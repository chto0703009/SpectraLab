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

function testManufacturedMonthIsAccepted(testCase)
root = string(tempname);
cleanup = onCleanup(@() removeTree(root));
session = spectralab.colorchecker.create(root, ...
    ChartManufacturedDate="2024-05");
verifyEqual(testCase, session.Definition.ChartManufacturedDate, "2024-05");
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

function removeTree(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
