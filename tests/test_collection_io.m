% Collection IO test

inst = spectralab.drivers.createInstrument("mock", "NoiseLevel", 0);
sess = spectralab.core.Session(inst);
sess = sess.open();
sess = sess.calibrate();

collection = spectralab.core.SpectrumCollection("Collection test");
collection = collection.add(sess.measure("A"));
collection = collection.add(sess.measure("B"));

tmp = fullfile(tempdir, "spectralab_v040_collection.slab.json");
spectralab.io.saveCollection(collection, tmp);

collection2 = spectralab.io.readCollection(tmp);

assert(collection2.count() == 2);
labels = collection2.labels();
assert(labels(1) == "A");
assert(labels(2) == "B");

fprintf("test_collection_io OK\n");
