% Core Spectrum tests

wl = (400:10:700).';
p = exp(-0.5*((wl - 550)/30).^2);

spec = spectralab.core.Spectrum(wl, p, "Gaussian");

assert(spec.Label == "Gaussian");
assert(numel(spec.WavelengthNm) == numel(wl));
assert(spec.integratedPower() > 0);

[lp, pp] = spec.peak();
assert(lp == 550);
assert(pp == max(p));

n = spec.normalizedPower();
assert(abs(max(n) - 1) < 1e-12);

spec2 = spec.withLabel("Renamed");
assert(spec2.Label == "Renamed");
assert(spec.Label == "Gaussian");

s = spec.toStruct();
spec3 = spectralab.core.Spectrum.fromStruct(s);
assert(abs(spec3.integratedPower() - spec.integratedPower()) < 1e-12);

fprintf("test_core_spectrum OK\n");
