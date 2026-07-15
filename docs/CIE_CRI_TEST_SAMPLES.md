# CIE CRI Test-Colour Sample Library

SpectraLab provides the fourteen official CIE 13.3 test-colour samples as
named `SpectralFilter` objects:

```matlab
sample1 = spectralab.filters.cri.tcs01();
sample9 = spectralab.filters.cri.tcs09();

samples = spectralab.filters.cri.all();
```

## Why `SpectralFilter` is used

The samples are physically spectral radiance factors of test surfaces.
SpectraLab does not introduce a separate reflectance class because the
required computational behaviour is already represented by the common
spectral-weighting abstraction:

```text
illuminant spectrum × test-sample spectral factor
```

The scientific identity is retained in the object metadata:

```matlab
filter.Unit
filter.Source
filter.Description
```

## Official source

The bundled data are the official CIE dataset:

```text
Spectral radiance factors of 14 test samples for the
CIE colour rendering index calculation

CIE 1995
DOI 10.25039/CIE.DS.wuiuu9cz
Original source: CIE 13.3:1995
```

The general colour rendering index `Ra` uses TCS01 through TCS08. TCS09
through TCS14 provide the additional special colour rendering indices.

## Integrity

The bundled CSV is protected by its official SHA-256 digest:

```text
f461decedb5c18800c61a6923240c71f6cf91fd23ac94865133cbfdb7e05c0ad
```

Automated tests also verify the published validation row at 475 nm.
