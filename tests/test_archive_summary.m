function tests = test_archive_summary
%TEST_ARCHIVE_SUMMARY Regression tests for ARCH-001.
tests = functiontests(localfunctions);
end

function testCompleteArchiveSummary(testCase)
archive = makeArchive();

txt = spectralab.archive.summary(archive);

verifyTrue(testCase, contains(txt, "SpectraLab Archive Summary"));
verifyTrue(testCase, contains(txt, "Identity"));
verifyTrue(testCase, contains(txt, "Measurement"));
verifyTrue(testCase, contains(txt, "Instrument"));
verifyTrue(testCase, contains(txt, "Metadata"));
verifyTrue(testCase, contains(txt, "Quality"));
verifyTrue(testCase, contains(txt, "History"));

verifyTrue(testCase, contains(txt, "Christer Törnkvist"));
verifyTrue(testCase, contains(txt, "X-Rite i1Pro 2"));
verifyTrue(testCase, contains(txt, "spotread"));
verifyTrue(testCase, contains(txt, "1001799"));
verifyTrue(testCase, contains(txt, "CSW Filter Study"));
verifyTrue(testCase, contains(txt, "SAM-10B"));
verifyTrue(testCase, contains(txt, "Validated metadata"));
verifyTrue(testCase, contains(txt, "380.0 - 730.0 nm"));
end

function testOptionalFieldsMayBeMissing(testCase)
archive = makeArchive();

archive.Metadata = struct();
archive.Instrument = struct();
archive.Quality = struct();
archive = rmfield(archive, "History");

txt = spectralab.archive.summary(archive);

verifyTrue(testCase, contains(txt, "not specified"));
verifyTrue(testCase, contains(txt, "Entries       : 0"));
end

function testMissingRequiredSectionIsRejected(testCase)
archive = makeArchive();
archive = rmfield(archive, "Measurement");

verifyError(testCase, ...
    @() spectralab.archive.summary(archive), ...
    "SpectraLab:Archive:InvalidArchive");
end

function archive = makeArchive()
archive.Identity.UUID = "12345678-1234-1234-1234-123456789abc";
archive.Identity.Created = datetime(2026,7,13,10,0,0);
archive.Identity.CreatedBy = "SpectraLab";
archive.Identity.ContentHash = ...
    "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

archive.Version.Format = "SLAB-MAT";
archive.Version.Version = "0.6";
archive.Version.Software = "0.6.0";

archive.Measurement.Name = "CSW sample";
archive.Measurement.Operator = "Christer Törnkvist";
archive.Measurement.Timestamp = datetime(2026,7,13,10,5,0);
archive.Measurement.Unit = "arbitrary";
archive.Measurement.Wavelength = (380:10:730)';
archive.Measurement.Value = ones(36,1);

archive.Instrument.Name = "X-Rite i1Pro 2";
archive.Instrument.Driver = "spotread";
archive.Instrument.SerialNumber = "1001799";
archive.Instrument.CalibrationID = "CAL-001";

archive.Metadata.Project = "CSW Filter Study";
archive.Metadata.SampleID = "SAM-10B";
archive.Metadata.Description = "Test archive";
archive.Metadata.Laboratory = "SpectraLab";
archive.Metadata.Tags = ["filter","sample"];
archive.Metadata.Comment = "Validated metadata";

archive.Quality.Valid = true;
archive.Quality.Warning = "";
archive.Quality.Saturated = false;
archive.Quality.SignalLevel = 0.75;
archive.Quality.Comment = "";

archive.History = struct.empty;
end
