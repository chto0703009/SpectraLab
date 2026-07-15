# Standard Spectral Filter Library

SpectraLab provides named `SpectralFilter` objects for common scientific
weighting functions.

## Flat weighting

```matlab
filter = spectralab.filters.flat([380 730]);
```

The value is one throughout the declared range.

## ISO Status A transmission spectral products

```matlab
blue  = spectralab.filters.statusA.blue();
green = spectralab.filters.statusA.green();
red   = spectralab.filters.statusA.red();
```

These are normalized linear spectral products derived from the logarithmic
documentary values in ANSI/ISO 5-3:1995, Table 3. The standard tabulates
log10 spectral products normalized to a peak value of 5.000. SpectraLab
converts them using:

```text
value = 10^(logProduct - 5)
```

The supplied objects represent the complete Status A transmission weighting,
not merely a physical glass-filter transmittance curve.

## CIE 1931 2 degree standard observer

```matlab
xBar = spectralab.filters.cie1931.xBar();
yBar = spectralab.filters.cie1931.yBar();
zBar = spectralab.filters.cie1931.zBar();
```

The filters use the official CIE 1 nm open dataset from 360 to 830 nm:

- CIE 2019, DOI 10.25039/CIE.DS.xvudnb9b
- Original source: CIE 018:2019, Table 6

## Photopic luminous efficiency

```matlab
vLambda = spectralab.filters.photopic();
```

This uses the official CIE `V(lambda)` 1 nm dataset:

- CIE 2019, DOI 10.25039/CIE.DS.dktna2s3
- Original source: CIE 018:2019, Table 1

Although its numerical values match CIE 1931 `yBar`, it is exposed under a
separate name because its scientific meaning is photometric.

## Design

Every library function returns a `spectralab.core.SpectralFilter`. Users can
therefore use tables and analytical filters through one stable interface:

```matlab
value = filter.evaluate(wavelengthNm);
```
