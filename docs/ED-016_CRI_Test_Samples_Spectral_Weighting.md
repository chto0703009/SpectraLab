# ED-016 — CRI Test Samples Use Spectral Weighting

**Status:** Accepted implementation  
**Version:** SpectraLab v0.7.0

## Decision

The fourteen CIE 13.3 test-colour sample spectral radiance factors shall be
represented by `spectralab.core.SpectralFilter`.

No separate reflectance-specific class is introduced.

## Rationale

CRI requires multiplication of an illuminant spectral power distribution by
each test-sample spectral radiance factor. This is the same computational
behaviour already provided by the first-class spectral-weighting
architecture:

```text
Spectrum × SpectralFilter → FilterResponse
```

The physical meaning remains explicit through name, unit, source, and
description metadata.

## Public API

```matlab
sample = spectralab.filters.cri.tcs01();
samples = spectralab.filters.cri.all();
```

## Provenance

The implementation uses the official CIE dataset:

```text
CIE 1995
DOI 10.25039/CIE.DS.wuiuu9cz
CIE 13.3:1995
```

The dataset shall be protected by checksum and documentary-value tests.
