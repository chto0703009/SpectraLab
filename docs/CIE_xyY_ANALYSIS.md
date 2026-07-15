# CIE xyY Analysis

## Public API

```matlab
xyYResult = spectralab.analysis.xyY(xyzResult);
```

The input must be a canonical result from:

```matlab
xyzResult = spectralab.analysis.xyz(inputData);
```

## Conversion

```text
x = X / (X + Y + Z)
y = Y / (X + Y + Z)
Y = Y
```

The Y value is preserved from the XYZ result.

Therefore:

- XYZ with `Normalization="none"` produces xyY with the original relative Y;
- XYZ with `Normalization="Y100"` produces xyY with `Y = 100`.

## Result fields

```matlab
xyYResult.Result.x
xyYResult.Result.y
xyYResult.Result.Y
```

The source XYZ values and tristimulus sum are retained for traceability:

```matlab
xyYResult.Result.X
xyYResult.Result.Z
xyYResult.Result.TristimulusSum
```
