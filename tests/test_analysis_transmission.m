function tests = test_analysis_transmission
tests = functiontests(localfunctions);
end

function testCorrectRatio(testCase)
r = makeArchive("Reference", [2;4;8], [400;500;600]);
s = makeArchive("Sample", [1;2;4], [400;500;600]);
a = spectralab.analysis.transmission(r,s);

verifyEqual(testCase, a.Result.Value, [0.5;0.5;0.5]);
verifyEqual(testCase, a.Result.Quantity, "Transmittance");
verifyEqual(testCase, a.Result.Unit, "1");
verifyEqual(testCase, a.Result.DisplayUnit, "%");
verifyEqual(testCase, a.Result.DisplayScale, 100);
verifyEqual(testCase, a.Sources(1).Role, "Reference");
verifyEqual(testCase, a.Sources(2).Role, "Sample");
end

function testWavelengthMismatch(testCase)
r = makeArchive("Reference", [2;4;8], [400;500;600]);
s = makeArchive("Sample", [1;2;4], [400;510;600]);
verifyError(testCase, @() spectralab.analysis.transmission(r,s), ...
    "SpectraLab:Analysis:WavelengthMismatch");
end

function testZeroReference(testCase)
r = makeArchive("Reference", [2;0;8], [400;500;600]);
s = makeArchive("Sample", [1;2;4], [400;500;600]);
verifyError(testCase, @() spectralab.analysis.transmission(r,s), ...
    "SpectraLab:Analysis:InvalidReferenceSignal");
end

function testAboveOnePreserved(testCase)
r = makeArchive("Reference", [1;1;1], [400;500;600]);
s = makeArchive("Sample", [1;2;1], [400;500;600]);
lastwarn("");
a = spectralab.analysis.transmission(r,s);
[~,id] = lastwarn;
verifyEqual(testCase, a.Result.Value, [1;2;1]);
verifyEqual(testCase, string(id), ...
    "SpectraLab:Analysis:TransmittanceAboveOne");
end

function archive = makeArchive(name, values, wavelengths)
archive.Identity.UUID = string(java.util.UUID.randomUUID);
archive.Identity.Created = datetime(2026,7,13,10,0,0);
archive.Identity.CreatedBy = "SpectraLab";
archive.Identity.HashAlgorithm = "SHA-256";

archive.Version.Format = "SLAB-MAT";
archive.Version.Version = "0.5";
archive.Version.Software = "0.7.0";
archive.Version.Created = datetime(2026,7,13,10,0,0);

archive.Measurement.Name = string(name);
archive.Measurement.Wavelength = wavelengths(:);
archive.Measurement.Value = values(:);
archive.Measurement.Unit = "arbitrary";
archive.Measurement.Operator = "Test Operator";
archive.Measurement.Timestamp = datetime(2026,7,13,10,5,0);

archive.Metadata.Project = "";
archive.Metadata.SampleID = "";
archive.Metadata.Description = "";
archive.Metadata.Laboratory = "";
archive.Metadata.Tags = strings(0);
archive.Metadata.Comment = "";

archive.Instrument.Name = "Mock";
archive.Instrument.Driver = "Mock";
archive.Instrument.SerialNumber = "TEST";
archive.Instrument.CalibrationID = "CAL-001";

archive.Quality.Valid = true;
archive.Quality.Warning = "";
archive.Quality.Saturated = false;
archive.Quality.SignalLevel = [];
archive.Quality.Comment = "";
archive.History = struct.empty;

payload.Measurement = archive.Measurement;
payload.Instrument = archive.Instrument;
payload.Quality = archive.Quality;
archive.Identity.ContentHash = spectralab.archive.contentHash(payload);
end
