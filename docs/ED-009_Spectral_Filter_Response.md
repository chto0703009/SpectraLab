# ED-009 — Spectral Filter Response and Weighting Functions

**Status:** Accepted  
**Version:** SpectraLab v0.7.0

## Decision

SpectraLab represents wavelength-dependent filters and sensitivity curves as
first-class `spectralab.core.SpectralFilter` objects.

A spectral filter is defined by its behaviour as a wavelength-dependent
weighting function, not by its storage representation.

The class supports:

1. tabulated wavelength/value data;
2. analytical MATLAB function handles.

Both forms expose the same operation:

```matlab
value = filter.evaluate(wavelengthNm);
```

No silent extrapolation is permitted. Every filter declares its valid
wavelength interval in `RangeNm`.

## Construction

Tabulated representation:

```matlab
filter = spectralab.core.SpectralFilter.fromTable( ...
    wavelengthNm, ...
    value, ...
    Name="Measured red filter");
```

Analytical representation:

```matlab
filter = spectralab.core.SpectralFilter.fromFunction( ...
    @(lambdaNm) exp(-0.5*((lambdaNm-550)/20).^2), ...
    [380 730], ...
    Name="Gaussian weighting function");
```

## Rationale

The same abstraction can represent:

- measured optical-filter transmission;
- detector sensitivity;
- CIE colour-matching functions;
- photopic and scotopic luminosity functions;
- densitometric status filters;
- user-defined theoretical responses.

This prevents `analysis.filterResponse` and later colourimetric functions from
depending on whether the user possesses a table, a formula, or a future
representation.

## Filter response

`analysis.filterResponse` shall transform a spectrum into a
wavelength-dependent weighted response. Integration remains a separate,
explicit analysis operation.

The valid response interval is the intersection of:

- the measured spectrum interval;
- the filter interval;
- an optional user-requested interval.

No silent extrapolation is allowed.
