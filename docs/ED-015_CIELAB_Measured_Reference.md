# ED-015 — CIELAB with Measured Reference White

**Status:** Accepted and corrected  
**Version:** SpectraLab v0.7.0

## Decision

CIELAB shall be calculated from:

1. sample XYZ;
2. reference-white XYZ.

For measured transmission workflows, the LED reference measurement supplies
the reference-white XYZ values, while the LED-through-sample measurement
supplies the sample XYZ values.

## Common-scale rule

Sample and reference shall use one common XYZ scale.

They shall not be independently normalized to `Y = 100`.

The canonical procedure is:

```text
reference spectrum -> raw XYZ
sample spectrum    -> raw XYZ
reference raw Y    -> common scale factor
common scale       -> reference XYZ and sample XYZ
scaled pair        -> CIELAB
```

The common scale factor is:

```text
scale = 100 / Y_reference_raw
```

and is applied to all X, Y, and Z values of both measurements.

## Rationale

Independent normalization would force both reference and sample to `Y = 100`,
destroying the relative luminance relationship and incorrectly yielding
`L* = 100` for the sample.

One reference-derived scale preserves:

- reference white at `Yn = 100`;
- sample/reference luminance ratio;
- chromatic ratios;
- physically meaningful relative `L*`.

## Metadata

Both scaled XYZ results shall record:

```text
Normalization = ReferenceY100
ScaleFactor   = common reference-derived factor
```

## Consequence

The resulting CIELAB values describe the measured sample relative to the
measured LED reference under the actual measurement conditions.

They are not automatically equivalent to CIELAB values under D50, D65, or
another standard illuminant.
