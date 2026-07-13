function tests = test_archive_validate
%TEST_ARCHIVE_VALIDATE Regression tests for ARCH-002.
tests = functiontests(localfunctions);
end

function testValidArchivePasses(testCase)
archive = makeArchive();

result = spectralab.archive.validate(archive);

verifyTrue(testCase, result.IsValid);
verifyEmpty(testCase, result.Errors);
verifyEqual(testCase, result.StoredContentHash, ...
    result.CalculatedContentHash);
end

function testMissingSectionFails(testCase)
archive = makeArchive();
archive = rmfield(archive, "Instrument");

result = spectralab.archive.validate(archive);

verifyFalse(testCase, result.IsValid);
verifyTrue(testCase, any(contains(result.Errors, ...
    "Missing required section: Instrument")));
end

function testVectorLengthMismatchFails(testCase)
archive = makeArchive();
archive.Measurement.Value = archive.Measurement.Value(1:end-1);
archive = updateHash(archive);

result = spectralab.archive.validate(archive);

verifyFalse(testCase, result.IsValid);
verifyTrue(testCase, any(contains(result.Errors, ...
    "different lengths")));
end

function testNonIncreasingWavelengthFails(testCase)
archive = makeArchive();
archive.Measurement.Wavelength(3) = ...
    archive.Measurement.Wavelength(2);
archive = updateHash(archive);

result = spectralab.archive.validate(archive);

verifyFalse(testCase, result.IsValid);
verifyTrue(testCase, any(contains(result.Errors, ...
    "strictly increasing")));
end

function testTamperedContentFailsHashCheck(testCase)
archive = makeArchive();
archive.Measurement.Value(1) = archive.Measurement.Value(1) + 1;

result = spectralab.archive.validate(archive);

verifyFalse(testCase, result.IsValid);
verifyTrue(testCase, any(contains(result.Errors, ...
    "Content hash verification failed")));
end

function testMissingProvenanceCreatesWarnings(testCase)
archive = makeArchive();
archive.Measurement.Operator = "";
archive.Instrument.Name = "";
archive.Instrument.SerialNumber = "";
archive = updateHash(archive);

result = spectralab.archive.validate(archive);

verifyTrue(testCase, result.IsValid);
verifyEqual(testCase, numel(result.Warnings), 3);
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

archive.Measurement.Name = "Validation test";
archive.Measurement.Wavelength = (380:10:730)';
archive.Measurement.Value = ones(36,1);
archive.Measurement.Unit = "arbitrary";
archive.Measurement.Operator = "Christer Törnkvist";
archive.Measurement.Timestamp = datetime(2026,7,13,10,5,0);

archive.Metadata.Project = "CSW Filter Study";
archive.Metadata.SampleID = "SAM-10B";
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
archive = updateHash(archive);
end

function archive = updateHash(archive)
payload = struct();
payload.Measurement = archive.Measurement;
payload.Instrument = archive.Instrument;
payload.Quality = archive.Quality;

archive.Identity.ContentHash = ...
    spectralab.archive.contentHash(payload);
end
