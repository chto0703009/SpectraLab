function amendment = recordRemeasurement(amendmentFile, coordinate, archiveFile, options)
%RECORDREMEASUREMENT Record one immutable replacement patch archive.

arguments
    amendmentFile (1,1) string
    coordinate (1,1) string
    archiveFile (1,1) string
    options.Reason (1,1) string = ""
    options.InstrumentInfo (1,1) struct = struct()
    options.Resolution (1,1) string = ""
end

amendment = spectralab.colorchecker.loadRemeasurement(amendmentFile);
if string(amendment.Identity.State) ~= "in_progress"
    error("SpectraLab:ColorChecker:AmendmentNotOpen", ...
        "Only an in-progress amendment can accept patch measurements.");
end
coordinate = upper(strtrim(coordinate));
index = find(string({amendment.Entries.Coordinate}) == coordinate, 1);
if isempty(index)
    error("SpectraLab:ColorChecker:PatchNotSelectedForRemeasurement", ...
        "Patch %s is not selected by this amendment.", coordinate);
end
if string(amendment.Entries(index).State) ~= "pending"
    error("SpectraLab:ColorChecker:RemeasurementAlreadyRecorded", ...
        "Replacement for patch %s is already recorded.", coordinate);
end
if ~isfile(archiveFile)
    error("SpectraLab:ColorChecker:RemeasurementArchiveNotFound", ...
        "Replacement archive not found: %s", archiveFile);
end
archive = spectralab.archive.load(archiveFile, Quiet=true, Validation="error");
kind = "";
if isfield(archive.Measurement, "Context") && ...
        isfield(archive.Measurement.Context, "Kind")
    kind = lower(string(archive.Measurement.Context.Kind));
end
if kind ~= "reflectance"
    error("SpectraLab:ColorChecker:RemeasurementIsNotReflectance", ...
        "A ColorChecker replacement must be a reflectance archive.");
end

folder = string(fileparts(amendmentFile));
reference = relativeFile(folder, archiveFile);
entry = amendment.Entries(index);
entry.State = "recorded";
entry.Reason = strtrim(options.Reason);
if entry.Reason == "", entry.Reason = string(amendment.Definition.Reason); end
entry.Replacement = struct( ...
    "ArchiveFile", reference, ...
    "ArchiveUUID", string(archive.Identity.UUID), ...
    "ArchiveContentHash", string(archive.Identity.ContentHash));
entry.Measured = char(datetime("now", "TimeZone", "local"), ...
    "yyyy-MM-dd'T'HH:mm:ssXXX");
entry.Instrument = options.InstrumentInfo;
entry.Resolution = strtrim(options.Resolution);
amendment.Entries(index) = entry;
amendment.History(end+1,1) = string(datetime("now", ...
    "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss")) + ...
    "  Replacement for patch " + coordinate + " recorded from archive " + ...
    string(archive.Identity.UUID) + ".";
amendment = writeAmendment(amendment, amendmentFile);
end

function value = relativeFile(folder, file)
prefix = folder + filesep;
if startsWith(file, prefix), value = extractAfter(file, strlength(prefix)); else, value = file; end
end

function amendment = writeAmendment(amendment, file)
amendment.Identity.Revision = amendment.Identity.Revision + 1;
temporary = file + ".tmp-" + string(java.util.UUID.randomUUID);
fid = fopen(temporary, "w");
if fid < 0, error("SpectraLab:ColorChecker:AmendmentWriteFailed", "Could not update amendment: %s", file); end
try
    fprintf(fid, "%s\n", jsonencode(amendment, PrettyPrint=true));
    fclose(fid);
catch ME
    fclose(fid);
    if isfile(temporary), delete(temporary); end
    rethrow(ME)
end
[ok, message] = movefile(temporary, file, "f");
if ~ok, error("SpectraLab:ColorChecker:AmendmentWriteFailed", "Could not update amendment:\n%s\n\n%s", file, message); end
end
