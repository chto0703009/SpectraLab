function tests = test_archive_restore_validation
%TEST_ARCHIVE_RESTORE_VALIDATION Regression tests for ARCH-005.
tests = functiontests(localfunctions);
end

function testValidArchiveRestoresByDefault(testCase)
archive = makeArchive();

spec = spectralab.archive.restore(archive);

verifyEqual(testCase, spec.Label, "ARCH-005 test");
verifyEqual(testCase, spec.Metadata.Operator, "Christer Törnkvist");
verifyEqual(testCase, spec.Metadata.Project, "Restore validation");
verifyEqual(testCase, spec.Metadata.SampleID, "RESTORE-001");
verifyEqual(testCase, spec.Metadata.Comment, "Preserve metadata");
verifyEqual(testCase, spec.Instrument.Name, "X-Rite i1Pro 2");
verifyEqual(testCase, spec.Instrument.SerialNumber, "1001799");
verifyEqual(testCase, spec.Calibration.CalibrationID, "CAL-001");
end

function testDefaultRejectsTamperedArchive(testCase)
archive = makeArchive();
archive.Measurement.Value(1) = archive.Measurement.Value(1) + 1;

verifyError(testCase, ...
    @() spectralab.archive.restore(archive), ...
    "SpectraLab:Archive:ValidationFailed");
end

function testNoneModeRestoresTamperedArchive(testCase)
archive = makeArchive();
archive.Measurement.Value(1) = archive.Measurement.Value(1) + 1;

spec = spectralab.archive.restore(archive, Validation="none");

verifyEqual(testCase, spec.Power(1), 2);
end

function testWarnModeRestoresTamperedArchive(testCase)
archive = makeArchive();
archive.Measurement.Value(1) = archive.Measurement.Value(1) + 1;

lastwarn("");
spec = spectralab.archive.restore(archive, Validation="warn");
[~, warningID] = lastwarn;

verifyEqual(testCase, spec.Power(1), 2);
verifyEqual(testCase, string(warningID), ...
    "SpectraLab:Archive:ValidationError");
end

function testInvalidModeIsRejected(testCase)
archive = makeArchive();

verifyError(testCase, ...
    @() spectralab.archive.restore(archive, Validation="strict"), ...
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

archive.Measurement.Name = "ARCH-005 test";
archive.Measurement.Wavelength = (380:10:730)';
archive.Measurement.Value = ones(36,1);
archive.Measurement.Unit = "arbitrary";
archive.Measurement.Operator = "Christer Törnkvist";
archive.Measurement.Timestamp = datetime(2026,7,13,10,5,0);

archive.Metadata.Project = "Restore validation";
archive.Metadata.SampleID = "RESTORE-001";
archive.Metadata.Description = "";
archive.Metadata.Laboratory = "";
archive.Metadata.Tags = strings(0);
archive.Metadata.Comment = "Preserve metadata";

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
