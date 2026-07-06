% Status and MeasurementResult tests

st = spectralab.core.Status.ok("Everything fine.");
assert(st.Ok);
assert(st.Code == "OK");

st2 = spectralab.core.Status.error("BAD", "Something failed.");
assert(~st2.Ok);
assert(st2.Code == "BAD");

wl = (400:10:700).';
sp = spectralab.core.Spectrum(wl, ones(size(wl)), "Flat");

r = spectralab.core.MeasurementResult.ok(sp);
assert(r.Success);
assert(isa(r.Spectrum, "spectralab.core.Spectrum"));

rf = spectralab.core.MeasurementResult.failed("ERR", "Failed.");
assert(~rf.Success);
assert(rf.Status.Code == "ERR");

fprintf("test_status_and_result OK\n");
