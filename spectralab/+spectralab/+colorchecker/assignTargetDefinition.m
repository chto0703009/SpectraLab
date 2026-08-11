function [session, outputFile] = assignTargetDefinition( ...
        sessionFile, targetIdentifier, options)
%ASSIGNTARGETDEFINITION Bind an existing session to a controlled target.
%
%   [SESSION, OUTPUTFILE] = ...
%       spectralab.colorchecker.assignTargetDefinition( ...
%           SESSIONFILE, "xrite-colorchecker-digital-sg-140")
%
% The source JSON and every patch archive remain unchanged. The function
% verifies the complete patch set and the UUID and SHA-256 identity of every
% referenced archive before writing a separate target-defined session JSON.

arguments
    sessionFile (1,1) string
    targetIdentifier (1,1) string
    options.Operator (1,1) string = ""
end

sessionFile = string(sessionFile);
if ~isfile(sessionFile)
    error("SpectraLab:ColorChecker:TargetAssignmentSourceNotFound", ...
        "ColorChecker source session not found: %s", sessionFile);
end

session = spectralab.colorchecker.load(sessionFile);
if isfield(session, "ColorimetryConversions") && ...
        ~isempty(session.ColorimetryConversions)
    error("SpectraLab:ColorChecker:TargetAssignmentRequiresMeasurementSession", ...
        ["Select the measurement-session JSON, not a converted " ...
         "colorimetry JSON."]);
end
if isfield(session.Definition, "TargetDefinition")
    error("SpectraLab:ColorChecker:TargetDefinitionAlreadyAssigned", ...
        "The selected session already contains a controlled target definition.");
end

target = spectralab.colorchecker.targetDefinition(targetIdentifier);
verifyGeometryAndCoordinates(session, target);
verifyPatchArchives(session, sessionFile);

sourceHash = fileSha256(sessionFile);
assigned = datetime("now", "TimeZone", "local");
session.Definition.TargetDefinition = target;
session.Definition.TargetDefinitionHash = ...
    spectralab.archive.contentHash(target);
session.TargetDefinitionAssignment = struct( ...
    "Type", "controlled target-definition assignment", ...
    "Assigned", char(assigned, "yyyy-MM-dd'T'HH:mm:ssXXX"), ...
    "AssignedBy", strtrim(options.Operator), ...
    "Software", spectralab.version(), ...
    "SourceSessionFile", sessionFile, ...
    "SourceSessionUUID", string(session.Identity.UUID), ...
    "SourceManifestSHA256", sourceHash, ...
    "TargetCanonicalID", string(target.CanonicalID), ...
    "TargetDefinitionSHA256", ...
        string(session.Definition.TargetDefinitionHash), ...
    "VerifiedPatchCount", numel(session.Patches), ...
    "PatchArchivesVerified", true, ...
    "MeasurementDataChanged", false);
if isfield(session.Identity, "Revision")
    session.Identity.Revision = double(session.Identity.Revision) + 1;
end
session.History(end+1,1) = string(assigned, "yyyy-MM-dd HH:mm:ss") + ...
    "  Controlled target definition assigned: " + ...
    string(target.Name) + "; measurement data unchanged.";

spectralab.colorchecker.validate(session);
outputFile = targetOutputFile(sessionFile, string(target.CanonicalID));
writeDerivedJson(outputFile, session);
end

function verifyGeometryAndCoordinates(session, target)
if session.Definition.Rows ~= target.Rows || ...
        session.Definition.Columns ~= target.Columns || ...
        numel(session.Patches) ~= target.PatchCount
    error("SpectraLab:ColorChecker:TargetAssignmentGeometryMismatch", ...
        ["The session geometry does not match %s (%d rows, %d columns, " ...
         "%d patches)."], target.Name, target.Rows, target.Columns, ...
        target.PatchCount);
end
actual = reshape(string({session.Patches.Coordinate}), [], 1);
expected = targetCoordinates(target.Columns, target.Rows);
if numel(unique(actual)) ~= numel(actual) || ...
        ~isequal(sort(actual), sort(expected))
    error("SpectraLab:ColorChecker:TargetAssignmentPatchSetMismatch", ...
        "The session does not contain the complete patch set required by %s.", ...
        target.Name);
end
states = reshape(string({session.Patches.State}), [], 1);
if ~all(states == "measured")
    error("SpectraLab:ColorChecker:TargetAssignmentSessionIncomplete", ...
        "A target definition can be assigned only after every patch is measured.");
end
end

function verifyPatchArchives(session, sessionFile)
sessionFolder = string(fileparts(sessionFile));
for index = 1:numel(session.Patches)
    patch = session.Patches(index);
    archiveFile = string(patch.ArchiveFile);
    if ~isfile(archiveFile)
        archiveFile = fullfile(sessionFolder, archiveFile);
    end
    archive = spectralab.archive.load( ...
        archiveFile, Quiet=true, Validation="error");
    if string(archive.Identity.UUID) ~= string(patch.ArchiveUUID) || ...
            string(archive.Identity.ContentHash) ~= ...
                string(patch.ArchiveContentHash)
        error("SpectraLab:ColorChecker:TargetAssignmentArchiveMismatch", ...
            "Patch %s does not match its recorded archive identity.", ...
            patch.Coordinate);
    end
end
end

function coordinates = targetCoordinates(columns, rows)
coordinates = strings(columns * rows, 1);
index = 0;
for row = 1:rows
    for column = 1:columns
        index = index + 1;
        coordinates(index) = columnLabel(column) + string(row);
    end
end
end

function label = columnLabel(column)
label = "";
while column > 0
    remainder = mod(column - 1, 26);
    label = char(65 + remainder) + label;
    column = floor((column - 1) / 26);
end
end

function outputFile = targetOutputFile(sessionFile, canonicalID)
[folder, baseName] = fileparts(sessionFile);
outputFile = fullfile(string(folder), ...
    string(baseName) + "_target_" + canonicalID + ".json");
if isfile(outputFile)
    error("SpectraLab:ColorChecker:TargetAssignmentOutputExists", ...
        "SpectraLab refuses to overwrite the target-defined session:\n%s", ...
        outputFile);
end
end

function writeDerivedJson(outputFile, session)
temporary = outputFile + ".tmp-" + string(java.util.UUID.randomUUID);
fid = fopen(temporary, "w");
if fid < 0
    error("SpectraLab:ColorChecker:TargetAssignmentWriteFailed", ...
        "Could not create target-defined session: %s", temporary);
end
try
    fprintf(fid, "%s\n", jsonencode(session, PrettyPrint=true));
    fclose(fid);
catch ME
    fclose(fid);
    if isfile(temporary), delete(temporary); end
    rethrow(ME)
end
[ok, message] = movefile(temporary, outputFile);
if ~ok
    error("SpectraLab:ColorChecker:TargetAssignmentWriteFailed", ...
        "Could not create target-defined session:\n%s\n\n%s", ...
        outputFile, message);
end
end

function hash = fileSha256(file)
fid = fopen(file, "r");
if fid < 0
    error("SpectraLab:ColorChecker:TargetAssignmentSourceReadFailed", ...
        "Could not read ColorChecker source session: %s", file);
end
cleanup = onCleanup(@() fclose(fid));
bytes = fread(fid, Inf, "*uint8");
md = java.security.MessageDigest.getInstance("SHA-256");
digest = typecast(md.digest(bytes), "uint8");
hash = lower(string(reshape(dec2hex(digest, 2).', 1, [])));
clear cleanup
end
