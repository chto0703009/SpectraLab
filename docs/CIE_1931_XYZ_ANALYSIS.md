# CIE 1931 XYZ Analysis

## Public API

```matlab
result = spectralab.analysis.xyz(inputData);
```

The input may be a `spectralab.core.Spectrum` or a canonical spectral analysis
result containing:

```matlab
inputData.Result.WavelengthNm
inputData.Result.Value
```

## Pipeline

```text
spectral input
     ├─ CIE xBar -> filterResponse -> integration -> X
     ├─ CIE yBar -> filterResponse -> integration -> Y
     └─ CIE zBar -> filterResponse -> integration -> Z
```

## Normalization

Unnormalized relative tristimulus values:

```matlab
result = spectralab.analysis.xyz( ...
    inputData, ...
    Normalization="none");
```

Y normalized to 100:

```matlab
result = spectralab.analysis.xyz( ...
    inputData, ...
    Normalization="Y100");
```

For spectra measured in arbitrary units, `Y100` preserves chromatic ratios
while providing convenient relative tristimulus values. It does not create an
absolute photometric calibration.

## Result fields

```matlab
result.Result.X
result.Result.Y
result.Result.Z

result.Result.RawX
result.Result.RawY
result.Result.RawZ

result.XResponse
result.YResponse
result.ZResponse
```

The wavelength-dependent responses remain available for plotting and
inspection.

## Observer and provenance

The implementation uses the bundled official CIE 1931 2° colour-matching
functions:

```text
CIE 2019
DOI 10.25039/CIE.DS.xvudnb9b
```

The dataset is protected by the standard-filter integrity tests.
