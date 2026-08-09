function [correctedSession, correctedSessionFile] = finalizeRemeasurement(amendmentFile)
%FINALIZEREMEASUREMENT Create a new corrected session manifest.
%
% The source manifest and every original archive remain unchanged.

arguments
    amendmentFile (1,1) string
end
amendment = spectralab.colorchecker.loadRemeasurement(amendmentFile);
if string(amendment.Identity.State) ~= "in_progress"
    error("SpectraLab:ColorChecker:AmendmentNotOpen", ...
        "The amendment is not open for finalization.");
end
states = string({amendment.Entries.State});
if any(states ~= "recorded")
    missing = string({amendment.Entries(states ~= "recorded").Coordinate});
    error("SpectraLab:ColorChecker:AmendmentIncomplete", ...
        "Remeasurement is incomplete. Missing patch: %s", join(missing, ", "));
end

folder = string(fileparts(amendmentFile));
sourceFile = string(amendment.Source.SessionFile);
if ~isfile(sourceFile), sourceFile = fullfile(folder, sourceFile); end
if fileSha256(sourceFile) ~= string(amendment.Source.ManifestSHA256)
    error("SpectraLab:ColorChecker:SourceManifestChanged", ...
        "The original ColorChecker session changed after remeasurement began.");
end
source = spectralab.colorchecker.load(sourceFile);
if string(source.Identity.UUID) ~= string(amendment.Source.SessionUUID)
    error("SpectraLab:ColorChecker:SourceSessionIdentityMismatch", ...
        "The source session UUID does not match the amendment.");
end
verifySessionArchives(source);

correctedSession = source;
if isfield(correctedSession, "ColorimetryConversions")
    correctedSession = rmfield(correctedSession, "ColorimetryConversions");
end
sourceIdentity = source.Identity;
created = datetime("now", "TimeZone", "local");
correctedSession.Identity.UUID = string(java.util.UUID.randomUUID);
correctedSession.Identity.Created = char(created, "yyyy-MM-dd'T'HH:mm:ssXXX");
correctedSession.Identity.Software = spectralab.version();
correctedSession.Identity.Revision = 1;
currentDerivation = struct( ...
    "Type", "controlled ColorChecker patch remeasurement", ...
    "SourceSessionUUID", string(sourceIdentity.UUID), ...
    "SourceSessionFile", relativeFile(folder, sourceFile), ...
    "SourceManifestSHA256", string(amendment.Source.ManifestSHA256), ...
    "AmendmentUUID", string(amendment.Identity.UUID), ...
    "AmendmentFile", relativeFile(folder, amendmentFile), ...
    "AmendmentSequence", double(amendment.Identity.Sequence), ...
    "Created", char(created, "yyyy-MM-dd'T'HH:mm:ssXXX"));
if isfield(source, "DerivationHistory")
    derivationHistory = reshape(source.DerivationHistory, [], 1);
elseif isfield(source, "Derivation")
    derivationHistory = reshape(source.Derivation, [], 1);
else
    derivationHistory = repmat(currentDerivation, 0, 1);
end
correctedSession.DerivationHistory = ...
    [derivationHistory; currentDerivation];
correctedSession.Derivation = currentDerivation;

coordinates = string({correctedSession.Patches.Coordinate});
for entry = reshape(amendment.Entries, 1, [])
    replacementFile = string(entry.Replacement.ArchiveFile);
    if ~isfile(replacementFile), replacementFile = fullfile(folder, replacementFile); end
    archive = spectralab.archive.load(replacementFile, Quiet=true, Validation="error");
    if string(archive.Identity.UUID) ~= string(entry.Replacement.ArchiveUUID) || ...
            string(archive.Identity.ContentHash) ~= string(entry.Replacement.ArchiveContentHash)
        error("SpectraLab:ColorChecker:ReplacementArchiveIdentityMismatch", ...
            "Replacement patch %s does not match its recorded archive.", entry.Coordinate);
    end
    index = find(coordinates == string(entry.Coordinate), 1);
    patch = correctedSession.Patches(index);
    patch.ArchiveFile = relativeFile(folder, replacementFile);
    patch.ArchiveUUID = string(archive.Identity.UUID);
    patch.ArchiveContentHash = string(archive.Identity.ContentHash);
    patch.Measured = string(entry.Measured);
    patch.CalibrationSequence = 0;
    correctedSession.Patches(index) = patch;
end
if isfield(source, "Remeasurements")
    previousRemeasurements = reshape(source.Remeasurements, [], 1);
else
    previousRemeasurements = repmat(amendment.Entries(1), 0, 1);
end
correctedSession.Remeasurements = ...
    [previousRemeasurements; reshape(amendment.Entries, [], 1)];
correctedSession.History(end+1,1) = string(created, "yyyy-MM-dd HH:mm:ss") + ...
    "  Corrected session created by amendment " + string(amendment.Identity.Sequence) + ".";

baseName = sprintf("colorchecker_session_amended_%03d", amendment.Identity.Sequence);
correctedSessionFile = fullfile(folder, baseName + ".json");
if isfile(correctedSessionFile)
    error("SpectraLab:ColorChecker:CorrectedSessionExists", ...
        "SpectraLab refuses to overwrite the corrected session:\n%s", correctedSessionFile);
end
writeJson(correctedSessionFile, correctedSession);

amendment.Identity.State = "complete";
amendment.Output = struct( ...
    "CorrectedSessionFile", relativeFile(folder, correctedSessionFile), ...
    "CorrectedSessionUUID", string(correctedSession.Identity.UUID), ...
    "CorrectedManifestSHA256", fileSha256(correctedSessionFile));
amendment.History(end+1,1) = string(datetime("now", ...
    "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss")) + ...
    "  Corrected session finalized as " + string(baseName) + ".";
writeAmendment(amendmentFile, amendment);
end

function writeJson(file, value)
temporary = file + ".tmp-" + string(java.util.UUID.randomUUID);
fid = fopen(temporary, "w");
if fid < 0, error("SpectraLab:ColorChecker:CorrectedSessionWriteFailed", "Could not create corrected session: %s", file); end
try
    fprintf(fid, "%s\n", jsonencode(value, PrettyPrint=true));
    fclose(fid);
catch ME
    fclose(fid); if isfile(temporary), delete(temporary); end; rethrow(ME)
end
[ok, message] = movefile(temporary, file);
if ~ok, error("SpectraLab:ColorChecker:CorrectedSessionWriteFailed", "Could not create corrected session:\n%s\n\n%s", file, message); end
end

function writeAmendment(file, value)
value.Identity.Revision = value.Identity.Revision + 1;
temporary = file + ".tmp-" + string(java.util.UUID.randomUUID);
fid = fopen(temporary, "w");
if fid < 0, error("SpectraLab:ColorChecker:AmendmentWriteFailed", "Could not finalize amendment: %s", file); end
fprintf(fid, "%s\n", jsonencode(value, PrettyPrint=true)); fclose(fid);
[ok, message] = movefile(temporary, file, "f");
if ~ok, error("SpectraLab:ColorChecker:AmendmentWriteFailed", "Could not finalize amendment:\n%s\n\n%s", file, message); end
end

function value = relativeFile(folder, file)
prefix = folder + filesep;
if startsWith(file, prefix), value = extractAfter(file, strlength(prefix)); else, value = file; end
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

function verifySessionArchives(session)
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
