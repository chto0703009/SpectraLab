function session = recordMeasurement(session, coordinate, archiveFile)
%RECORDMEASUREMENT Attach an immutable standard archive to one patch.

arguments
    session (1,1) struct
    coordinate (1,1) string
    archiveFile (1,1) string
end

spectralab.colorchecker.validate(session);
coordinate = upper(strtrim(coordinate));
patchIndex = find(string({session.Patches.Coordinate}) == coordinate, 1);
if isempty(patchIndex)
    error("SpectraLab:ColorChecker:UnknownPatch", ...
        "Patch coordinate is not defined by this session: %s", coordinate);
end
if string(session.Patches(patchIndex).State) ~= "pending"
    error("SpectraLab:ColorChecker:PatchAlreadyMeasured", ...
        "Patch %s is already measured. Create a deliberate remeasurement revision instead.", ...
        coordinate);
end
expected = spectralab.colorchecker.nextPatch(session);
if coordinate ~= string(expected.Coordinate)
    error("SpectraLab:ColorChecker:UnexpectedPatch", ...
        "Expected patch %s, but received %s.", expected.Coordinate, coordinate);
end
if ~isfile(archiveFile)
    error("SpectraLab:ColorChecker:ArchiveNotFound", ...
        "Patch archive not found: %s", archiveFile);
end

archive = spectralab.archive.load(archiveFile, Quiet=true, Validation="error");
kind = "";
if isfield(archive.Measurement, "Context") && ...
        isfield(archive.Measurement.Context, "Kind")
    kind = lower(string(archive.Measurement.Context.Kind));
end
if kind ~= "reflectance"
    error("SpectraLab:ColorChecker:ArchiveIsNotReflectance", ...
        "ColorChecker patches must use a reflectance archive.");
end
if isempty(session.Calibrations)
    error("SpectraLab:ColorChecker:CalibrationRequired", ...
        "Record a successful calibration before recording a patch.");
end

sessionFolder = string(session.Context.SessionFolder);
archiveFile = string(archiveFile);
prefix = sessionFolder + filesep;
if startsWith(archiveFile, prefix)
    archiveReference = extractAfter(archiveFile, strlength(prefix));
else
    archiveReference = archiveFile;
end

patch = session.Patches(patchIndex);
patch.State = "measured";
patch.ArchiveFile = archiveReference;
patch.ArchiveUUID = string(archive.Identity.UUID);
patch.ArchiveContentHash = string(archive.Identity.ContentHash);
patch.Measured = char(datetime("now", "TimeZone", "local"), ...
    "yyyy-MM-dd'T'HH:mm:ssXXX");
patch.CalibrationSequence = session.Calibrations(end).Sequence;
session.Patches(patchIndex) = patch;
session.History(end+1,1) = string(datetime("now", ...
    "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss")) + ...
    "  Patch " + coordinate + " recorded from archive " + ...
    string(archive.Identity.UUID) + ".";
end
