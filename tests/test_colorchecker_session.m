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
archiveFile = fullfile(root, "A1.mat");
spectralab.archive.save(archive, archiveFile);

session = spectralab.colorchecker.recordMeasurement(session, "A1", archiveFile);
verifyEqual(testCase, session.Patches(1).State, "measured");
verifyEqual(testCase, session.Patches(1).ArchiveUUID, archive.Identity.UUID);
verifyEqual(testCase, spectralab.colorchecker.nextPatch(session), struct());
end

function testManufacturedMonthIsAccepted(testCase)
root = string(tempname);
cleanup = onCleanup(@() removeTree(root));
session = spectralab.colorchecker.create(root, ...
    ChartManufacturedDate="2024-05");
verifyEqual(testCase, session.Definition.ChartManufacturedDate, "2024-05");
end

function testPythonSpotreadSeriesIsReadableByMatlab(testCase)
root = string(tempname);
mkdir(root);
cleanup = onCleanup(@() removeTree(root));
fixture = fullfile(fileparts(mfilename("fullpath")), "fixtures", ...
    "spotread_i1pro2_measurement_complete.txt");
copyfile(fixture, fullfile(root, "A1.txt"));
manifest = struct( ...
    "schema", "spectralab.spotread-colorchecker-series.v1", ...
    "state", "complete", ...
    "message", "", ...
    "started_unix", 1, ...
    "updated_unix", 2, ...
    "requested_patch_count", 1, ...
    "completed_patch_count", 1, ...
    "instrument_id", "i1Pro2", ...
    "high_resolution", false, ...
    "chart_name", "Digital SG laboratory target", ...
    "chart_manufactured_date", "2023-11", ...
    "records", struct("index", 1, "coordinate", "A1", ...
        "raw_file", "A1.txt"));
fid = fopen(fullfile(root, "series_manifest.json"), "w");
fprintf(fid, "%s", jsonencode(manifest));
fclose(fid);

series = spectralab.colorchecker.readSpotreadSeries(root);

verifyEqual(testCase, series.State, "complete");
verifyEqual(testCase, series.CompletedPatchCount, 1);
verifyEqual(testCase, series.Patches(1).Coordinate, "A1");
verifyClass(testCase, series.Patches(1).Spectrum, ...
    "spectralab.core.Spectrum");
verifyEqual(testCase, ...
    series.Patches(1).Spectrum.Metadata.measurement_kind, "reflectance");
verifyGreaterThan(testCase, numel(series.Patches(1).Spectrum.Power), 3);
verifyEqual(testCase, series.Definition.Name, ...
    "Digital SG laboratory target");
verifyEqual(testCase, series.Definition.ManufacturedDate, "2023-11");
archive = spectralab.archive.create(series.Patches(1).Spectrum);
verifyEqual(testCase, archive.Measurement.Context.ColorCheckerName, ...
    "Digital SG laboratory target");
verifyEqual(testCase, ...
    archive.Measurement.Context.ColorCheckerManufacturedDate, "2023-11");
end

function removeTree(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
