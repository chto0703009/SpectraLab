function [amendment, amendmentFile] = beginRemeasurement(sessionFile, coordinates, options)
%BEGINREMEASUREMENT Start a controlled immutable patch correction.

arguments
    sessionFile (1,1) string
    coordinates (:,1) string
    options.Reason (1,1) string
    options.Operator (1,1) string = ""
end

if isfolder(sessionFile)
    sessionFile = fullfile(sessionFile, "colorchecker_session.json");
end
session = spectralab.colorchecker.load(sessionFile);
coordinates = unique(upper(strtrim(coordinates)), "stable");
coordinates(coordinates == "") = [];
if isempty(coordinates)
    error("SpectraLab:ColorChecker:RemeasurementPatchesRequired", ...
        "Select at least one ColorChecker patch for remeasurement.");
end
if strlength(strtrim(options.Reason)) == 0
    error("SpectraLab:ColorChecker:RemeasurementReasonRequired", ...
        "A controlled remeasurement requires a reason.");
end

sessionCoordinates = string({session.Patches.Coordinate}).';
if any(~ismember(coordinates, sessionCoordinates))
    unknown = coordinates(~ismember(coordinates, sessionCoordinates));
    error("SpectraLab:ColorChecker:UnknownRemeasurementPatch", ...
        "Patch is not defined by the source session: %s", join(unknown, ", "));
end
if any(string({session.Patches.State}) ~= "measured")
    error("SpectraLab:ColorChecker:RemeasurementSourceIncomplete", ...
        "Controlled remeasurement requires a complete source session.");
end
verifySourceArchives(session);

sessionFolder = string(fileparts(sessionFile));
sequence = nextSequence(sessionFolder);
amendmentFile = fullfile(sessionFolder, sprintf( ...
    "colorchecker_session_amendment_%03d.json", sequence));
created = datetime("now", "TimeZone", "local");

entries = repmat(emptyEntry(), numel(coordinates), 1);
for index = 1:numel(coordinates)
    patch = session.Patches(sessionCoordinates == coordinates(index));
    entries(index).Coordinate = coordinates(index);
    entries(index).Original = archiveReference(patch);
end

amendment = struct();
amendment.Schema = "spectralab.colorchecker-amendment.v1";
amendment.Identity = struct( ...
    "UUID", string(java.util.UUID.randomUUID), ...
    "Created", char(created, "yyyy-MM-dd'T'HH:mm:ssXXX"), ...
    "CreatedBy", "SpectraLab", ...
    "Software", spectralab.version(), ...
    "Sequence", sequence, ...
    "Revision", 0, ...
    "State", "in_progress");
amendment.Source = struct( ...
    "SessionFile", relativeFile(sessionFolder, sessionFile), ...
    "SessionUUID", string(session.Identity.UUID), ...
    "ManifestSHA256", fileSha256(sessionFile));
amendment.Definition = struct( ...
    "Reason", strtrim(options.Reason), ...
    "Operator", strtrim(options.Operator), ...
    "Policy", "Original session and archives remain immutable; each replacement is a new SpectraLab archive.", ...
    "SelectedPatchCount", numel(entries));
if isfield(session, "AcquisitionSettings")
    amendment.AcquisitionSettings = session.AcquisitionSettings;
else
    amendment.AcquisitionSettings = struct();
end
amendment.Entries = entries;
amendment.History = string(created, "yyyy-MM-dd HH:mm:ss") + ...
    "  Controlled remeasurement started for " + join(coordinates, ", ") + ".";
amendment = writeAmendment(amendment, amendmentFile);
end

function verifySourceArchives(session)
folder = string(session.Context.SessionFolder);
for patch = reshape(session.Patches, 1, [])
    file = string(patch.ArchiveFile);
    if ~isfile(file), file = fullfile(folder, file); end
    archive = spectralab.archive.load(file, Quiet=true, Validation="error");
    if string(archive.Identity.UUID) ~= string(patch.ArchiveUUID) || ...
            string(archive.Identity.ContentHash) ~= string(patch.ArchiveContentHash)
        error("SpectraLab:ColorChecker:RemeasurementSourceIdentityMismatch", ...
            "Source patch %s does not match its recorded archive.", patch.Coordinate);
    end
end
end

function sequence = nextSequence(folder)
files = dir(fullfile(folder, "colorchecker_session_amendment_*.json"));
sequence = 1;
for file = reshape(files, 1, [])
    token = regexp(file.name, 'amendment_(\d+)\.json$', 'tokens', 'once');
    if ~isempty(token), sequence = max(sequence, str2double(token{1}) + 1); end
end
end

function entry = emptyEntry()
entry = struct("Coordinate", "", "State", "pending", ...
    "Reason", "", "Original", struct(), "Replacement", struct(), ...
    "Measured", "", "Instrument", struct(), "Resolution", "");
end

function value = archiveReference(patch)
value = struct("ArchiveFile", string(patch.ArchiveFile), ...
    "ArchiveUUID", string(patch.ArchiveUUID), ...
    "ArchiveContentHash", string(patch.ArchiveContentHash), ...
    "Measured", string(patch.Measured), ...
    "CalibrationSequence", double(patch.CalibrationSequence));
end

function value = relativeFile(folder, file)
prefix = folder + filesep;
if startsWith(file, prefix), value = extractAfter(file, strlength(prefix)); else, value = file; end
end

function amendment = writeAmendment(amendment, file)
amendment.Identity.Revision = amendment.Identity.Revision + 1;
temporary = file + ".tmp-" + string(java.util.UUID.randomUUID);
fid = fopen(temporary, "w");
if fid < 0, error("SpectraLab:ColorChecker:AmendmentWriteFailed", "Could not create amendment: %s", file); end
try
    fprintf(fid, "%s\n", jsonencode(amendment, PrettyPrint=true));
    fclose(fid);
catch ME
    fclose(fid);
    if isfile(temporary), delete(temporary); end
    rethrow(ME)
end
[ok, message] = movefile(temporary, file);
if ~ok, error("SpectraLab:ColorChecker:AmendmentWriteFailed", "Could not create amendment:\n%s\n\n%s", file, message); end
end

function hash = fileSha256(file)
fid = fopen(file, "r");
if fid < 0, error("SpectraLab:ColorChecker:ManifestReadFailed", "Could not read manifest: %s", file); end
cleanup = onCleanup(@() fclose(fid));
bytes = fread(fid, Inf, "*uint8");
md = java.security.MessageDigest.getInstance("SHA-256");
digest = typecast(md.digest(bytes), "uint8");
hash = lower(string(reshape(dec2hex(digest, 2).', 1, [])));
clear cleanup
end
