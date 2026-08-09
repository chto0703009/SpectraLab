function verification = verifyColorimetry(convertedJsonFile, options)
%VERIFYCOLORIMETRY Recalculate and verify converted ColorChecker results.

arguments
    convertedJsonFile (1,1) string
    options.Illuminant = []
    options.Tolerance (1,1) double {mustBeFinite, mustBeNonnegative} = 1e-9
end
session = spectralab.colorchecker.load(convertedJsonFile);
if ~isfield(session, "ColorimetryConversions") || ...
        isempty(session.ColorimetryConversions)
    error("SpectraLab:ColorChecker:ColorimetryConversionMissing", ...
        "The selected JSON contains no ColorChecker colorimetry conversion.");
end
conversion = session.ColorimetryConversions(end);
illuminant = options.Illuminant;
if isempty(illuminant)
    label = upper(string(conversion.Illuminant.Label));
    if contains(label, "D50")
        illuminant = spectralab.filters.cie.d50();
    elseif contains(label, "D65")
        illuminant = spectralab.filters.cie.d65();
    else
        error("SpectraLab:ColorChecker:VerificationIlluminantRequired", ...
            "Select the illuminant spectrum used by this conversion to verify its results.");
    end
end
if string(illuminant.Label) ~= string(conversion.Illuminant.Label)
    error("SpectraLab:ColorChecker:VerificationIlluminantMismatch", ...
        "The selected illuminant '%s' does not match the converted JSON illuminant '%s'.", ...
        illuminant.Label, conversion.Illuminant.Label);
end
sessionFolder = string(fileparts(convertedJsonFile));
maxXyzDifference = 0;
maxLabDifference = 0;
referenceWhite = struct();
for index = 1:numel(conversion.Results)
    expected = conversion.Results(index);
    archiveFile = string(expected.ArchiveFile);
    if ~isfile(archiveFile), archiveFile = fullfile(sessionFolder, archiveFile); end
    archive = spectralab.archive.load(archiveFile, Quiet=true, Validation="error");
    if string(archive.Identity.UUID) ~= string(expected.ArchiveUUID) || ...
            string(archive.Identity.ContentHash) ~= ...
                string(expected.ArchiveContentHash)
        error("SpectraLab:ColorChecker:PatchArchiveIdentityMismatch", ...
            "Patch %s does not match its recorded MAT archive.", ...
            expected.Coordinate);
    end
    dataset = spectralab.analysis.colorimetry(archiveFile, ...
        Illuminant=illuminant, Observer=string(conversion.Observer));
    actual = dataset.Samples(1).Colorimetry;
    if index == 1
        referenceWhite = actual.ReferenceWhiteXYZ;
    end
    xyzDifference = max(abs([actual.XYZ.X, actual.XYZ.Y, actual.XYZ.Z] - ...
        [expected.XYZ.X, expected.XYZ.Y, expected.XYZ.Z]));
    labDifference = max(abs([actual.Lab.L, actual.Lab.a, actual.Lab.b] - ...
        [expected.Lab.L, expected.Lab.a, expected.Lab.b]));
    maxXyzDifference = max(maxXyzDifference, xyzDifference);
    maxLabDifference = max(maxLabDifference, labDifference);
end
verified = max(maxXyzDifference, maxLabDifference) <= options.Tolerance;
if ~verified
    error("SpectraLab:ColorChecker:ConvertedColorimetryMismatch", ...
        "Recalculated XYZ/Lab do not match the converted JSON (maximum difference %.15g).", ...
        max(maxXyzDifference, maxLabDifference));
end
verification = struct("Verified", true, ...
    "PatchCount", numel(conversion.Results), ...
    "Illuminant", string(illuminant.Label), ...
    "Observer", string(conversion.Observer), ...
    "Tolerance", options.Tolerance, ...
    "ReferenceWhiteXYZ", referenceWhite, ...
    "MaximumXYZDifference", maxXyzDifference, ...
    "MaximumLabDifference", maxLabDifference);
end
