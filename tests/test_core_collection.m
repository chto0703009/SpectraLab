% Core SpectrumCollection tests

wl = (400:10:700).';
a = spectralab.core.Spectrum(wl, sin(wl/100).^2 + 0.1, "A");
b = spectralab.core.Spectrum(wl, cos(wl/100).^2 + 0.1, "B");

c = spectralab.core.SpectrumCollection("Core collection");
assert(c.count() == 0);

c = c.add(a);
c = c.add(b);

assert(c.count() == 2);
labels = c.labels();
assert(labels(1) == "A");
assert(c.get(2).Label == "B");

T = c.summaryTable();
assert(height(T) == 2);

s = c.toStruct();
c2 = spectralab.core.SpectrumCollection.fromStruct(s);
assert(c2.count() == 2);

fprintf("test_core_collection OK\n");
