function tests = test_archive_info
%TEST_ARCHIVE_INFO Regression tests for ARCH-003.
tests = functiontests(localfunctions);
end

function testInfoReturnsInspectionResult(testCase)
filename = tempname + ".mat";
cleanup = onCleanup(@() deleteIfExists(filename));

archive = makeArchive();
spectralab.archive.save(archive, filename);

result = spectralab.archive.info(filename);

verifyEqual(testCase, result.Filename, string(filename));
verifyTrue(testCase, result.Validation.IsValid);
verifyTrue(testCase, contains(result.Summary, ...
    "SpectraLab Archive Summary"));
verifyEqual(testCase, result.Archive.Measurement.Name, ...
    "ARCH-003 test");
end

function testMissingFileIsRejected(testCase)
filename = tempname + ".mat";

verifyError(testCase, ...
    @() spectralab.archive.info(filename), ...
    "SpectraLab:Archive:FileNotFound");
end

function testInvalidArchiveIsReported(testCase)
filename = tempname + ".mat";
cleanup = onCleanup(@() deleteIfExists(filename));

archive = makeArchive();
archive.Measurement.Value(1) = archive.Measurement.Value(1) + 1;
save(filename, "archive", "-mat");

result = spectralab.archive.info(filename);

verifyFalse(testCase, result.Validation.IsValid);
verifyTrue(testCase, any(contains( ...
    result.Validation.Errors, ...
    "Content hash verification failed")));
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

archive.Measurement.Name = "ARCH-003 test";
archive.Measurement.Wavelength = (380:10:730)';
archive.Measurement.Value = ones(36,1);
archive.Measurement.Unit = "arbitrary";
archive.Measurement.Operator = "Christer Törnkvist";
archive.Measurement.Timestamp = datetime(2026,7,13,10,5,0);

archive.Metadata.Project = "Archive inspection";
archive.Metadata.SampleID = "INFO-001";
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
