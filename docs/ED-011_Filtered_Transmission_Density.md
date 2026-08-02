# ED-011 — Filtered Transmission Density

**Status:** Accepted  
**Version:** SpectraLab v0.7.0

## Meaning

Density in this decision means **transmission density**.

## Canonical pipeline

Filtered transmission density shall be calculated from the spectral
transmission result:

```text
reference + sample
        ↓
analysis.transmission
        ↓
analysis.filterResponse
        ↓
normalized integration
        ↓
transmission density
```

The canonical effective transmission is:

```text
T = integral(transmission(lambda) * filter(lambda)) /
    integral(filter(lambda))
```

Transmission density is:

```text
D = -log10(T)
```

## Rationale

The reference/sample spectral ratio removes the measured source spectrum and
instrument response before the standardized weighting function is applied,
subject to the normal requirements of stable measurement conditions, adequate
signal, linearity, and controlled geometry.

This is preferred to independently integrating filtered raw reference and
sample spectra, where the source spectrum would remain part of the broadband
weighting.

## Public API

```matlab
result = spectralab.analysis.transmissionDensity( ...
    referenceArchive, ...
    sampleArchive, ...
    spectralab.filters.statusA.red());
```

The result preserves the full chain:

```matlab
result.Transmission
result.FilterResponse
result.Result.EffectiveTransmission
result.Result.Density
```

## Quality warnings

Very low effective transmission and high density can be dominated by noise,
stray light, or the practical measurement floor. The implementation therefore
supports configurable warning thresholds without silently rejecting valid
results.
