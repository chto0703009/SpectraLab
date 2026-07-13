function tests = test_archive_load_validation
%TEST_ARCHIVE_LOAD_VALIDATION Regression tests for ARCH-004.
tests = functiontests(localfunctions);
end

function testDefaultLoadRemainsBackwardCompatible(testCase)
filename = tempname + ".mat";
cleanup = onCleanup(@() deleteIfExists(filename));

archive = makeArchive();
spectralab.archive.save(archive, filename);

loaded = spectralab.archive.load(filename, Quiet=true);

verifyEqual(testCase, loaded.Measurement.Name, "ARCH-004 test");
end

function testWarnModeLoadsValidArchive(testCase)
filename = tempname + ".mat";
cleanup = onCleanup(@() deleteIfExists(filename));

archive = makeArchive();
spectralab.archive.save(archive, filename);

loaded = spectralab.archive.load(filename, ...
    Quiet=true, Validation="warn");

verifyEqual(testCase, loaded.Measurement.Name, "ARCH-004 test");
end

function testErrorModeRejectsTamperedArchive(testCase)
filename = tempname + ".mat";
cleanup = onCleanup(@() deleteIfExists(filename));

archive = makeArchive();
archive.Measurement.Value(1) = archive.Measurement.Value(1) + 1;
save(filename, "archive", "-mat");

verifyError(testCase, ...
    @() spectralab.archive.load(filename, ...
        Quiet=true, Validation="error"), ...
    "SpectraLab:Archive:ValidationFailed");
end

function testNoneModeLoadsTamperedArchive(testCase)
filename = tempname + ".mat";
cleanup = onCleanup(@() deleteIfExists(filename));

archive = makeArchive();
archive.Measurement.Value(1) = archive.Measurement.Value(1) + 1;
save(filename, "archive", "-mat");

loaded = spectralab.archive.load(filename, ...
    Quiet=true, Validation="none");

verifyEqual(testCase, loaded.Measurement.Name, "ARCH-004 test");
end

function testInvalidValidationModeIsRejected(testCase)
filename = tempname + ".mat";
cleanup = onCleanup(@() deleteIfExists(filename));

archive = makeArchive();
spectralab.archive.save(archive, filename);

verifyError(testCase, ...
    @() spectralab.archive.load(filename, ...
        Quiet=true, Validation="strict"), ...
    "SpectraLab:Archive:InvalidValidationMode");
end

function archive = makeArchive()
archive.Identity.UUID = "12345678-1234-1234-1234-123456789abc";
archive.Identity.Created = datetime(2026,7,13,10,0,0);
archive.Identity.CreatedBy = "SpectraLab";
archive.Identity.HashAlgorithm = "SHA-256";

archive.Version.Format = "SLAB-MAT";
archive.Version.Version = "0.6";
archive.Version.Software = "0.6.0";
archive.Version.Created = datetime(2026,7,13,10,0,0);

archive.Measurement.Name = "ARCH-004 test";
archive.Measurement.Wavelength = (380:10:730)';
archive.Measurement.Value = ones(36,1);
archive.Measurement.Unit = "arbitrary";
archive.Measurement.Operator = "Christer Törnkvist";
archive.Measurement.Timestamp = datetime(2026,7,13,10,5,0);

archive.Metadata.Project = "Archive loading";
archive.Metadata.SampleID = "LOAD-001";
archive.Metadata.Description = "";
archive.Metadata.Laboratory = "";
archive.Metadata.Tags = strings(0);
archive.Metadata.Comment = "";

archive.Instrument.Name = "X-Rite i1Pro 2";
archive.Instrument.Driver = "spotread";
archive.Instrument.SerialNumber = "1001799";
archive.Instrument.CalibrationID = "CAL-001";

archive.Quality.Valid = true;
archive.Quality.Warning = "";
archive.Quality.Saturated = false;
archive.Quality.SignalLevel = [];
archive.Quality.Comment = "";

archive.History = struct.empty;

payload = struct();
payload.Measurement = archive.Measurement;
payload.Instrument = archive.Instrument;
payload.Quality = archive.Quality;

archive.Identity.ContentHash = ...
    spectralab.archive.contentHash(payload);
end

function deleteIfExists(filename)
if isfile(filename)
    delete(filename);
end
end
