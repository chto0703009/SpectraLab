# ED-012 — Spectral Weighting as a First-Class Concept

**Status:** Accepted  
**Version:** SpectraLab v0.7.0

## Context

SpectraLab now supports several wavelength-dependent scientific weighting
functions, including:

- ISO Status A red, green, and blue transmission spectral products;
- CIE 1931 2° colour-matching functions x-bar, y-bar, and z-bar;
- the photopic luminous-efficiency function V(lambda);
- flat weighting;
- user-defined tabulated or analytical weighting functions.

These functions belong to different scientific domains, but they share the
same fundamental behaviour: each assigns a wavelength-dependent weight to
spectral data.

## Decision

Spectral weighting is a first-class scientific concept in SpectraLab.

All wavelength-dependent weighting functions shall be represented by:

```matlab
spectralab.core.SpectralFilter
```

All spectral weighting operations shall use the common analysis function:

```matlab
spectralab.analysis.filterResponse(...)
```

A weighting function is defined by its behaviour, not by its representation.

It may therefore be supplied as:

1. tabulated wavelength/value data;
2. an analytical MATLAB function;
3. a future representation that implements the same evaluation behaviour.

## Supported scientific domains

The common abstraction applies to, among others:

### Transmission densitometry

```matlab
red = spectralab.filters.statusA.red();

result = spectralab.analysis.transmissionDensity( ...
    referenceArchive, ...
    sampleArchive, ...
    red);
```

Status A remains a permanent part of the SpectraLab densitometry domain.

Future density standards may include:

- Status M;
- Status T;
- Status E;
- user-defined densitometer responses.

### Colorimetry

```matlab
xBar = spectralab.filters.cie1931.xBar();
yBar = spectralab.filters.cie1931.yBar();
zBar = spectralab.filters.cie1931.zBar();
```

These functions will support future XYZ and related colorimetric analyses.

### Photometry

```matlab
vLambda = spectralab.filters.photopic();
```

The photopic response uses the same weighting mechanism while retaining its
distinct photometric meaning.

## Canonical pipeline

```text
Scientific spectral object
          +
SpectralFilter
          ↓
analysis.filterResponse
          ↓
Wavelength-dependent weighted response
          ↓
Optional explicit integration or higher-level analysis
```

The weighted response remains wavelength dependent and plottable.

Integration is performed only when required by a higher-level scientific
quantity, such as transmission density, XYZ tristimulus values, or a
photometric response.

## Separation of scientific domains

The common weighting infrastructure does not merge the scientific meanings of
the filters.

For example:

- Status A remains a densitometric standard;
- CIE x-bar, y-bar, and z-bar remain color-matching functions;
- V(lambda) remains a photometric luminous-efficiency function.

They share implementation infrastructure, but not scientific identity.

## Public API principles

Users shall work with named scientific objects:

```matlab
filter = spectralab.filters.statusA.red();
```

rather than manually entering internal arrays whenever a standard library
definition exists.

Custom filters remain supported:

```matlab
filter = spectralab.core.SpectralFilter.fromTable( ...
    wavelengthNm, ...
    value, ...
    Name="Custom filter");
```

or:

```matlab
filter = spectralab.core.SpectralFilter.fromFunction( ...
    @(lambdaNm) responseFunction(lambdaNm), ...
    [380 730], ...
    Name="Analytical filter");
```

## Consequences

### Advantages

- One stable interface for all spectral weighting functions.
- Reuse of validated interpolation and wavelength-range handling.
- Consistent metadata and provenance.
- Weighted responses are returned as ordinary spectral data and may be plotted using SpectraLab’s standard plotting facilities.
- Easier addition of new standards without changing analysis algorithms.
- Clear separation between scientific identity and implementation mechanics.

### Constraints

- No silent extrapolation outside a filter's declared wavelength range.
- Standard weighting functions must include authoritative provenance.
- Bundled reference datasets must be protected by integrity tests.
- Higher-level analyses must preserve the identity of the weighting function
  used.

## Design principle

Spectral weighting is shared infrastructure.

Scientific meaning remains explicit.
