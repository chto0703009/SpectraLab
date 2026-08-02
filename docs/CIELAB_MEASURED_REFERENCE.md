# CIELAB with a Measured Reference White

## Public API

```matlab
labResult = spectralab.analysis.lab( ...
    sampleXyz, ...
    referenceXyz);
```

Both inputs are canonical results from:

```matlab
spectralab.analysis.xyz(...)
```

## Measured transmission workflow

```text
LED reference spectrum      -> raw XYZ
LED-through-sample spectrum -> raw XYZ
                               |
                               v
                    common reference-derived scale
                               |
                               v
                            CIELAB
```

The measured LED reference defines the reference white.

## Common-scale requirement

The reference and sample must not be normalized independently.

Independent `Y100` normalization would force both measurements to `Y = 100`
and would destroy the sample/reference luminance relationship. In that case,
the sample would incorrectly obtain `L* = 100`.

The canonical workflow is:

```matlab
referenceRaw = spectralab.analysis.xyz( ...
    referenceSpec, ...
    Normalization="none");

sampleRaw = spectralab.analysis.xyz( ...
    sampleSpec, ...
    Normalization="none");

scaleFactor = 100 / referenceRaw.Result.Y;
```

The same scale factor is then applied to both XYZ results:

```matlab
referenceXyz.Result.X = referenceRaw.Result.X * scaleFactor;
referenceXyz.Result.Y = referenceRaw.Result.Y * scaleFactor;
referenceXyz.Result.Z = referenceRaw.Result.Z * scaleFactor;

sampleXyz.Result.X = sampleRaw.Result.X * scaleFactor;
sampleXyz.Result.Y = sampleRaw.Result.Y * scaleFactor;
sampleXyz.Result.Z = sampleRaw.Result.Z * scaleFactor;
```

Both results are marked with:

```matlab
Processing.Normalization = "ReferenceY100";
```

## Interpretation

This makes the measured reference white use:

```text
Yn = 100
```

while preserving the relative sample luminance.

The resulting CIELAB values describe the sample relative to the measured LED
reference. They are not automatically equivalent to values under D50, D65,
or another standard illuminant.

## Result fields

```matlab
labResult.Result.L
labResult.Result.a
labResult.Result.b
```

The reference-white XYZ values are retained in:

```matlab
labResult.ReferenceWhite
```
