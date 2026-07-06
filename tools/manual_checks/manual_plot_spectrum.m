%TEST_PLOT_SPECTRUM  Quick test of clean SpectraLab plotting.

startup

if exist("spec", "var") && isa(spec, "spectralab.core.Spectrum")
    spectrumToPlot = spec;
elseif isfile("led.slab.json")
    spectrumToPlot = spectralab.io.readSpectrum("led.slab.json");
else
    inst = spectralab.drivers.createInstrument("mock");
    sess = spectralab.core.Session(inst);
    sess = sess.open();
    sess = sess.calibrate();
    spectrumToPlot = sess.measure("Mock spectrum");
end

figure("Name", "SpectraLab plot test");
spectrumToPlot.plot();

figure("Name", "SpectraLab normalized plot test");
spectrumToPlot.plotNormalized();
