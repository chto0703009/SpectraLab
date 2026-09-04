function tests = test_colorchecker_session
tests = functiontests(localfunctions);
end

function testSessionGeometryAndCalibration(testCase)
root = string(tempname);
cleanup = onCleanup(@() removeTree(root));
session = spectralab.colorchecker.create(root, ...
    Name="Test chart", Rows=2, Columns=3, CalibrationIntervalMinutes=20, ...
    ChartSerialNumber="X-Rite-123", ChartManufacturedDate="2024-05-17");

verifyEqual(testCase, string({session.Patches.Coordinate}), ...
    ["A1", "B1", "C1", "A2", "B2", "C2"]);
verifyTrue(testCase, isfile(fullfile(root, "colorchecker_session.json")));
verifyTrue(testCase, isfolder(fullfile(root, "archive")));
verifyEqual(testCase, string(session.Context.ArchiveFolder), "archive");
verifyEqual(testCase, ...
    string(session.MeasurementDefinition.IntendedUse), ...
    "camera colour calibration");
manifest = jsondecode(fileread(fullfile(root, "colorchecker_session.json")));
verifyEqual(testCase, manifest.Definition.Rows, 2);
verifyEqual(testCase, manifest.Definition.Columns, 3);
verifyFalse(testCase, isfield(manifest, "ColorimetryConversions"));
verifyEqual(testCase, ...
    string(manifest.MeasurementDefinition.Quantity), ...
    "spectral reflectance factor");
verifyEqual(testCase, spectralab.colorchecker.nextPatch(session).Coordinate, "A1");
[due, ~] = spectralab.colorchecker.isCalibrationDue(session);
verifyTrue(testCase, due);

instrument = struct("name", "i1Pro2", "serial_number", "123456");
session = spectralab.colorchecker.recordCalibration(session, instrument, ...
    Timestamp=datetime("now", "TimeZone", "local"));
[due, dueAt] = spectralab.colorchecker.isCalibrationDue(session);
verifyFalse(testCase, due);
verifyTrue(testCase, isdatetime(dueAt));
session = spectralab.colorchecker.save(session);

loaded = spectralab.colorchecker.load(root);
verifyEqual(testCase, loaded.Definition.Rows, 2);
verifyEqual(testCase, string(loaded.Definition.ChartSerialNumber), "X-Rite-123");
verifyEqual(testCase, string(loaded.Definition.ChartManufacturedDate), "2024-05-17");
verifyEqual(testCase, string(loaded.Calibrations(1).Instrument.name), "i1Pro2");
loaded = spectralab.colorchecker.recordCalibration( ...
    loaded, instrument, Timestamp=datetime("now", "TimeZone", "local"));
verifyEqual(testCase, numel(loaded.Calibrations), 2);
verifyClass(testCase, loaded.History, "string");
end

function testPatchUsesImmutableReflectanceArchive(testCase)
root = string(tempname);
cleanup = onCleanup(@() removeTree(root));
session = spectralab.colorchecker.create(root, Rows=1, Columns=1);
session = spectralab.colorchecker.recordCalibration(session, struct("name", "mock"));

spec = spectralab.core.Spectrum((400:10:700)', ones(31,1), ...
    "R", struct(), struct(), struct( ...
        "measurement_kind", "reflectance", ...
        "signal_quantity", "spectral reflectance factor"), "percent");
archive = spectralab.archive.create(spec);
archiveFile = fullfile(root, "archive", "A1.mat");
spectralab.archive.save(archive, archiveFile);

session = spectralab.colorchecker.recordMeasurement(session, "A1", archiveFile);
verifyEqual(testCase, session.Patches(1).State, "measured");
verifyEqual(testCase, session.Patches(1).ArchiveUUID, archive.Identity.UUID);
verifyEqual(testCase, string(session.Patches(1).ArchiveFile), ...
    fullfile("archive", "A1.mat"));
verifyEqual(testCase, spectralab.colorchecker.nextPatch(session), struct());
end

function testCamera41ArtifactEnforcesExportContract(testCase)
root=string(tempname);
cleanup=onCleanup(@() removeTree(root)); %#ok<NASGU>
session=spectralab.colorchecker.create(root,Rows=1,Columns=1);
session=spectralab.colorchecker.recordCalibration(session,struct("name","mock"));
wavelength=(370:10:750)';
spec=spectralab.core.Spectrum(wavelength,linspace(10,90,numel(wavelength))', ...
    "A1",struct(),struct(),struct( ...
    "measurement_kind","reflectance", ...
    "signal_quantity","spectral reflectance factor"), ...
    "relative reflectance (%)");
archive=spectralab.archive.create(spec);
archiveFile=fullfile(root,"archive","A1.mat");
spectralab.archive.save(archive,archiveFile);
session=spectralab.colorchecker.recordMeasurement(session,"A1",archiveFile);
spectralab.colorchecker.save(session);
artifact=spectralab.colorchecker.createSpectralArtifact( ...
    fullfile(root,"colorchecker_session.json"));
verifyTrue(testCase,spectralab.archive.validateSpectralArtifact(artifact).IsValid);
verifyEqual(testCase,artifact.Payload.WavelengthNm([1 end]),[400;730]);
verifySize(testCase,artifact.Payload.Values,[34 1]);
verifyEqual(testCase,artifact.Payload.RequestedWavelengthRangeNm,[400 730]);
verifyEqual(testCase,artifact.Provenance.EffectiveOutputWavelengthRangeNm, ...
    [400 730]);
verifyEqual(testCase,artifact.Provenance.Camera41ExportContract, ...
    spectralab.io.camera41ExportContract());
source=spectralab.archive.load(archiveFile,Quiet=true,Validation="error");
verifyEqual(testCase,source.Measurement.Wavelength([1 end]),[370;750]);
end

function testManufacturedMonthIsAccepted(testCase)
root = string(tempname);
cleanup = onCleanup(@() removeTree(root));
session = spectralab.colorchecker.create(root, ...
    ChartManufacturedDate="2024-05");
verifyEqual(testCase, session.Definition.ChartManufacturedDate, "2024-05");
end

function testArchitectureControlledDigitalSgDefinition(testCase)
root = string(tempname);
cleanup = onCleanup(@() removeTree(root));
session = spectralab.colorchecker.create(root, ...
    Name="My measured chart", ...
    TargetDefinitionID="xrite-colorchecker-digital-sg-140");

target = session.Definition.TargetDefinition;
verifyEqual(testCase, string(target.CanonicalID), ...
    "xrite-colorchecker-digital-sg-140");
verifyEqual(testCase, string(target.Name), ...
    "X-Rite ColorChecker Digital SG");
verifyEqual(testCase, target.Rows, 10);
verifyEqual(testCase, target.Columns, 14);
verifyEqual(testCase, target.PatchCount, 140);
verifyEqual(testCase, numel(session.Patches), 140);
verifyEqual(testCase, string(session.Definition.Name), "My measured chart");
verifyEqual(testCase, string(session.Definition.TargetDefinitionHash), ...
    spectralab.archive.contentHash(target));
end

function testTargetDefinitionTamperingIsRejected(testCase)
root = string(tempname);
cleanup = onCleanup(@() removeTree(root));
session = spectralab.colorchecker.create(root, ...
    TargetDefinitionID="xrite-colorchecker-digital-sg-140");
session.Definition.TargetDefinition.Name = "Similar looking chart";

verifyError(testCase, ...
    @() spectralab.colorchecker.validate(session), ...
    "SpectraLab:ColorChecker:TargetDefinitionMismatch");
end

function testPatchArchiveContainsNoDerivedColorimetry(testCase)
metadata = struct( ...
    "measurement_kind", "reflectance", ...
    "signal_quantity", "spectral reflectance factor", ...
    "raw_output", "Result is XYZ: 1 2 3, D50 Lab: 4 5 6", ...
    "spotread_colorimetry", struct( ...
        "available", true, "xyz", [1 2 3], "lab", [4 5 6]), ...
    "Operator", "Test operator");
spec = spectralab.core.Spectrum((400:10:700)', ones(31,1), ...
    "A1", struct(), struct(), metadata, "relative reflectance (%)");

primary = spectralab.colorchecker.reflectanceOnlySpectrum( ...
    spec, Coordinate="A1", SessionUUID="session-1");
archive = spectralab.archive.create(primary);

verifyFalse(testCase, isfield(primary.Metadata, "raw_output"));
verifyFalse(testCase, isfield(primary.Metadata, "spotread_colorimetry"));
verifyFalse(testCase, isfield(archive.Measurement.Context, ...
    "InstrumentReportedColorimetry"));
verifyEqual(testCase, archive.Measurement.Value, spec.Power);
verifyEqual(testCase, archive.Measurement.Unit, ...
    "relative reflectance (%)");

fig = figure("Visible", "off");
figureCleanup = onCleanup(@() close(fig));
ax = axes("Parent", fig);
spectralab.plot.reflectanceColorimetryPanel(ax, archive);
panelText = findall(fig, "Tag", "SpectraLabReflectanceColorimetry");
verifyNotEmpty(testCase, panelText);
displayed = join(string(panelText.String), newline);
verifyTrue(testCase, contains(displayed, ...
    "SpectraLab calculated (D50, CIE 1931 2 degree)"));
verifyTrue(testCase, contains(displayed, "XYZ: "));
verifyTrue(testCase, contains(displayed, "Lab: "));
swatch = findall(fig, "Tag", "SpectraLabEvaluatedColorSwatch");
verifyNumElements(testCase, swatch, 1);
verifyGreaterThanOrEqual(testCase, swatch.FaceColor, zeros(1,3));
verifyLessThanOrEqual(testCase, swatch.FaceColor, ones(1,3));
verifyEqual(testCase, swatch.Position(3), swatch.Position(4), ...
    "AbsTol", 1e-12);
clear figureCleanup
end

function testColorimetryIsWrittenToSeparateJsonCopy(testCase)
root = string(tempname);
cleanup = onCleanup(@() removeTree(root));
session = spectralab.colorchecker.create(root, Rows=1, Columns=1);
session = spectralab.colorchecker.recordCalibration( ...
    session, struct("name", "mock"));
reflectance = linspace(10, 70, 31).';
spec = spectralab.core.Spectrum((400:10:700)', reflectance, ...
    "A1", struct(), struct(), struct( ...
        "measurement_kind", "reflectance", ...
        "signal_quantity", "spectral reflectance factor"), ...
    "relative reflectance (%)");
archive = spectralab.archive.create(spec);
archiveFile = fullfile(root, "archive", "A1.mat");
spectralab.archive.save(archive, archiveFile);
session = spectralab.colorchecker.recordMeasurement( ...
    session, "A1", archiveFile);
session = spectralab.colorchecker.save(session);
sourceFile = fullfile(root, "colorchecker_session.json");
sourceTextBefore = string(fileread(sourceFile));

[session, conversion, convertedFile, csvFile] = ...
    spectralab.colorchecker.calculateColorimetry(sourceFile);

verifyEqual(testCase, conversion.PatchCount, 1);
verifyEqual(testCase, conversion.CalculationVersion, "COL-001");
verifyEqual(testCase, conversion.SourceSessionUUID, ...
    string(session.Identity.UUID));
verifyEqual(testCase, conversion.Results(1).Coordinate, "A1");
verifyTrue(testCase, isfinite(conversion.Results(1).XYZ.X));
verifyTrue(testCase, isfinite(conversion.Results(1).Lab.L));
verifyEqual(testCase, numel(session.ColorimetryConversions), 1);
verifyEqual(testCase, string(fileread(sourceFile)), sourceTextBefore);
verifyEqual(testCase, convertedFile, fullfile(root, ...
    "colorchecker_session_colorimetry_D50_CIE1931_2.json"));
verifyEqual(testCase, csvFile, "");
sourceManifest = jsondecode(fileread(sourceFile));
verifyFalse(testCase, isfield(sourceManifest, "ColorimetryConversions"));
manifest = jsondecode(fileread(convertedFile));
verifyEqual(testCase, manifest.ColorimetryConversions.PatchCount, 1);
verifyTrue(testCase, isfinite( ...
    manifest.ColorimetryConversions.Results.XYZ.X));
report = spectralab.colorchecker.generateColorimetryReport(convertedFile);
verifyTrue(testCase, isfile(report.PDFFile));
verifyEqual(testCase, report.PatchCount, 1);
verifyTrue(testCase, report.ContainsXYZ);
verifyTrue(testCase, report.ContainsLab);
verifyTrue(testCase, report.ContainsProvenance);
verifyTrue(testCase, report.ContainsQuality);
restoredArchive = spectralab.archive.load(archiveFile, Quiet=true);
verifyFalse(testCase, isfield(restoredArchive.Measurement.Context, ...
    "InstrumentReportedColorimetry"));
end

function testColorimetryCsvIsExplicitAndTraceable(testCase)
root = string(tempname);
cleanup = onCleanup(@() removeTree(root));
session = spectralab.colorchecker.create(root, Rows=1, Columns=1);
session = spectralab.colorchecker.recordCalibration( ...
    session, struct("name", "mock"));
spec = spectralab.core.Spectrum((400:10:700)', linspace(10, 70, 31)', ...
    "A1", struct(), struct(), struct("measurement_kind", "reflectance"), ...
    "relative reflectance (%)");
archive = spectralab.archive.create(spec);
archiveFile = fullfile(root, "archive", "A1.mat");
spectralab.archive.save(archive, archiveFile);
session = spectralab.colorchecker.recordMeasurement( ...
    session, "A1", archiveFile);
spectralab.colorchecker.save(session);
[~, ~, convertedFile, csvFile] = ...
    spectralab.colorchecker.calculateColorimetry( ...
    fullfile(root, "colorchecker_session.json"), ExportCSV=true);
verifyTrue(testCase, isfile(csvFile));
data = readtable(csvFile, TextType="string");
verifyEqual(testCase, string(data.Properties.VariableNames), ...
    ["Patch", "X", "Y", "Z", "L_star", "a_star", "b_star", ...
     "Illuminant", "Observer", "ArchiveFile", "ArchiveUUID", ...
     "ArchiveContentHash"]);
verifyEqual(testCase, data.Patch, "A1");
verifyEqual(testCase, data.ArchiveUUID, string(archive.Identity.UUID));
verifyEqual(testCase, data.ArchiveContentHash, ...
    string(archive.Identity.ContentHash));
verification = spectralab.colorchecker.verifyColorimetry(convertedFile);
verifyTrue(testCase, verification.Verified);
tampered = jsondecode(fileread(convertedFile));
tampered.ColorimetryConversions.Results.XYZ.X = ...
    tampered.ColorimetryConversions.Results.XYZ.X + 0.01;
tamperedFile = fullfile(root, ...
    "colorchecker_session_colorimetry_tampered.json");
fid = fopen(tamperedFile, "w");
fprintf(fid, "%s\n", jsonencode(tampered, PrettyPrint=true));
fclose(fid);
verifyError(testCase, ...
    @() spectralab.colorchecker.verifyColorimetry(tamperedFile), ...
    "SpectraLab:ColorChecker:ConvertedColorimetryMismatch");
end

function testColorimetryRejectsIncompleteSession(testCase)
root = string(tempname);
cleanup = onCleanup(@() removeTree(root));
spectralab.colorchecker.create(root, Rows=1, Columns=2);
verifyError(testCase, @() ...
    spectralab.colorchecker.calculateColorimetry( ...
        fullfile(root, "colorchecker_session.json")), ...
    "SpectraLab:ColorChecker:SessionIncomplete");
end

function testControlledPatchRemeasurementPreservesSource(testCase)
root = string(tempname);
cleanup = onCleanup(@() removeTree(root));
session = spectralab.colorchecker.create(root, Rows=1, Columns=2);
session = spectralab.colorchecker.recordCalibration(session, ...
    struct("name", "mock", "serial_number", "MOCK-1"));
for index = 1:2
    coordinate = ["A1", "B1"];
    spectrum = spectralab.core.Spectrum((400:10:700)', ...
        ones(31,1) * (20 + 10 * index), coordinate(index), ...
        struct(), struct(), struct("measurement_kind", "reflectance"), ...
        "relative reflectance (%)");
    archive = spectralab.archive.create(spectrum);
    archiveFile = fullfile(root, "archive", coordinate(index) + ".mat");
    spectralab.archive.save(archive, archiveFile);
    session = spectralab.colorchecker.recordMeasurement( ...
        session, coordinate(index), archiveFile);
end
session = spectralab.colorchecker.save(session);
sourceFile = fullfile(root, "colorchecker_session.json");
sourceText = string(fileread(sourceFile));
originalA1 = session.Patches(1);

replacementSpectrum = spectralab.core.Spectrum((400:10:700)', ...
    ones(31,1) * 55, "A1 remeasurement", struct(), struct(), ...
    struct("measurement_kind", "reflectance"), ...
    "relative reflectance (%)");
replacementArchive = spectralab.archive.create(replacementSpectrum);
replacementFile = fullfile(root, "archive", "A1_remeasurement.mat");
spectralab.archive.save(replacementArchive, replacementFile);

[~, amendmentFile] = spectralab.colorchecker.beginRemeasurement( ...
    sourceFile, "A1", Reason="suspected placement error", ...
    Operator="Test operator");
spectralab.colorchecker.recordRemeasurement( ...
    amendmentFile, "A1", replacementFile, ...
    InstrumentInfo=struct("name", "mock"), Resolution="standard");
[corrected, correctedFile] = ...
    spectralab.colorchecker.finalizeRemeasurement(amendmentFile);

verifyEqual(testCase, string(fileread(sourceFile)), sourceText);
verifyEqual(testCase, corrected.Patches(1).ArchiveUUID, ...
    replacementArchive.Identity.UUID);
verifyEqual(testCase, corrected.Patches(1).ArchiveContentHash, ...
    replacementArchive.Identity.ContentHash);
verifyEqual(testCase, string(corrected.Patches(2).ArchiveUUID), ...
    string(session.Patches(2).ArchiveUUID));
verifyNotEqual(testCase, corrected.Identity.UUID, session.Identity.UUID);
verifyEqual(testCase, ...
    string(corrected.Remeasurements.Original.ArchiveUUID), ...
    string(originalA1.ArchiveUUID));
verifyTrue(testCase, isfile(correctedFile));
amendment = spectralab.colorchecker.loadRemeasurement(amendmentFile);
verifyEqual(testCase, string(amendment.Identity.State), "complete");
verifyEqual(testCase, string(amendment.Output.CorrectedSessionUUID), ...
    string(corrected.Identity.UUID));

[~, conversion, convertedFile] = ...
    spectralab.colorchecker.calculateColorimetry(correctedFile);
verifyEqual(testCase, conversion.PatchCount, 2);
verifyTrue(testCase, isfile(convertedFile));
verifyEqual(testCase, conversion.Results(1).ArchiveUUID, ...
    replacementArchive.Identity.UUID);

correctedText = string(fileread(correctedFile));
secondSpectrum = spectralab.core.Spectrum((400:10:700)', ...
    ones(31,1) * 65, "B1 remeasurement", struct(), struct(), ...
    struct("measurement_kind", "reflectance"), ...
    "relative reflectance (%)");
secondArchive = spectralab.archive.create(secondSpectrum);
secondArchiveFile = fullfile(root, "archive", "B1_remeasurement.mat");
spectralab.archive.save(secondArchive, secondArchiveFile);
[~, secondAmendmentFile] = ...
    spectralab.colorchecker.beginRemeasurement( ...
        correctedFile, "B1", Reason="second controlled correction");
spectralab.colorchecker.recordRemeasurement( ...
    secondAmendmentFile, "B1", secondArchiveFile);
[secondCorrected, secondCorrectedFile] = ...
    spectralab.colorchecker.finalizeRemeasurement(secondAmendmentFile);
verifyEqual(testCase, string(fileread(correctedFile)), correctedText);
verifyEqual(testCase, string(secondCorrected.Patches(1).ArchiveUUID), ...
    string(corrected.Patches(1).ArchiveUUID));
verifyEqual(testCase, string(secondCorrected.Patches(2).ArchiveUUID), ...
    string(secondArchive.Identity.UUID));
verifyEqual(testCase, numel(secondCorrected.Remeasurements), 2);
verifyEqual(testCase, ...
    string({secondCorrected.Remeasurements.Coordinate}), ["A1", "B1"]);
verifyEqual(testCase, numel(secondCorrected.DerivationHistory), 2);
verifyEqual(testCase, secondCorrected.Derivation.AmendmentSequence, 2);
verifyTrue(testCase, endsWith(secondCorrectedFile, ...
    "colorchecker_session_amended_002.json"));
end

function testControlledTargetAssignmentPreservesMeasurements(testCase)
root = string(tempname);
cleanup = onCleanup(@() removeTree(root));
session = spectralab.colorchecker.create(root, Rows=10, Columns=14);

spectrum = spectralab.core.Spectrum((400:10:700)', ones(31,1) * 50, ...
    "Shared target-assignment fixture", struct(), struct(), ...
    struct("measurement_kind", "reflectance"), ...
    "relative reflectance (%)");
archive = spectralab.archive.create(spectrum);
archiveFile = fullfile(root, "archive", "shared.mat");
spectralab.archive.save(archive, archiveFile);
for index = 1:numel(session.Patches)
    session.Patches(index).State = "measured";
    session.Patches(index).ArchiveFile = fullfile("archive", "shared.mat");
    session.Patches(index).ArchiveUUID = archive.Identity.UUID;
    session.Patches(index).ArchiveContentHash = archive.Identity.ContentHash;
    session.Patches(index).Measured = "2026-08-11T09:00:00+02:00";
end
session = spectralab.colorchecker.save(session);
sourceFile = fullfile(root, "colorchecker_session.json");
sourceText = string(fileread(sourceFile));
sourcePatches = session.Patches;

[defined, outputFile] = ...
    spectralab.colorchecker.assignTargetDefinition( ...
        sourceFile, "xrite-colorchecker-digital-sg-140", ...
        Operator="Test operator");

verifyEqual(testCase, string(fileread(sourceFile)), sourceText);
verifyTrue(testCase, isfile(outputFile));
verifyEqual(testCase, string(defined.Definition.TargetDefinition.Name), ...
    "X-Rite ColorChecker Digital SG");
verifyEqual(testCase, ...
    string(defined.Definition.TargetDefinitionHash), ...
    spectralab.archive.contentHash( ...
        defined.Definition.TargetDefinition));
verifyEqual(testCase, string({defined.Patches.Coordinate}), ...
    string({sourcePatches.Coordinate}));
verifyEqual(testCase, string({defined.Patches.ArchiveFile}), ...
    string({sourcePatches.ArchiveFile}));
verifyEqual(testCase, string({defined.Patches.ArchiveUUID}), ...
    string({sourcePatches.ArchiveUUID}));
verifyEqual(testCase, string({defined.Patches.ArchiveContentHash}), ...
    string({sourcePatches.ArchiveContentHash}));
verifyEqual(testCase, string(defined.Identity.UUID), ...
    string(session.Identity.UUID));
verifyTrue(testCase, ...
    defined.TargetDefinitionAssignment.PatchArchivesVerified);
verifyFalse(testCase, ...
    defined.TargetDefinitionAssignment.MeasurementDataChanged);
verifyEqual(testCase, ...
    defined.TargetDefinitionAssignment.VerifiedPatchCount, 140);

verifyError(testCase, ...
    @() spectralab.colorchecker.assignTargetDefinition( ...
        sourceFile, "xrite-colorchecker-digital-sg-140"), ...
    "SpectraLab:ColorChecker:TargetAssignmentOutputExists");
end

function removeTree(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
