% Plot helper smoke tests

inst = spectralab.drivers.createInstrument("mock", "NoiseLevel", 0);
sess = spectralab.core.Session(inst);
sess = sess.open();
sess = sess.calibrate();

a = sess.measure("A");
b = sess.measure("B");

c = spectralab.core.SpectrumCollection("Plot test");
c = c.add(a);
c = c.add(b);

fig = figure("Visible", "off");
c.plotOverlay("Normalize", true);
close(fig);

fig = figure("Visible", "off");
d = spectralab.plot.compare(a, b);
assert(isfield(d, "delta"));
close(fig);

fprintf("test_plot_helpers OK\n");


fig = figure("Visible", "off");
spectralab.plot.spectrum(a);
close(fig);
