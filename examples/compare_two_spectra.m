% SpectraLab v0.4 compare two spectra example

startup

inst1 = spectralab.drivers.createInstrument("mock", "Scale", 1.0);
sess1 = spectralab.core.Session(inst1);
sess1 = sess1.open();
sess1 = sess1.calibrate();
a = sess1.measure("Reference");

inst2 = spectralab.drivers.createInstrument("mock", "Scale", 0.8);
sess2 = spectralab.core.Session(inst2);
sess2 = sess2.open();
sess2 = sess2.calibrate();
b = sess2.measure("Measurement");

figure;
spectralab.plot.compare(a,b);
