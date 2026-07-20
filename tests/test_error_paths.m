% Error path regression tests

failed = false;
try
    spectralab.core.Spectrum([400 410], 1, "bad");
catch ME
    failed = strcmp(ME.identifier, "SpectraLab:Spectrum:SizeMismatch");
end
assert(failed);

failed = false;
try
    spectralab.core.Spectrum([410 400], [1 2], "bad");
catch ME
    failed = strcmp(ME.identifier, "SpectraLab:Spectrum:WavelengthOrder");
end
assert(failed);

failed = false;
try
    spectralab.drivers.createInstrument("does-not-exist");
catch ME
    failed = strcmp(ME.identifier, "SpectraLab:Drivers:UnknownInstrument");
end
assert(failed);

failed = false;
try
    spectralab.io.readSpectrum("file.unsupported");
catch ME
    failed = strcmp(ME.identifier, "SpectraLab:IO:UnsupportedFormat");
end
assert(failed);

fprintf("test_error_paths OK\n");
