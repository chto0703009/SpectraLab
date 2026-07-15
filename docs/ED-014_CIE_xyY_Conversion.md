# ED-014 — CIE xyY Conversion

**Status:** Accepted implementation  
**Version:** SpectraLab v0.7.0

## Decision

CIE xyY shall be implemented as a direct conversion from a canonical
SpectraLab CIE 1931 XYZ result.

No spectral filtering or integration is repeated.

## Conversion

```text
x = X / (X + Y + Z)
y = Y / (X + Y + Z)
Y = Y
```

The source Y scale is preserved.

## Rationale

xyY is a coordinate transformation of XYZ, not an independent spectral
analysis. Reusing the XYZ result preserves one authoritative spectral
integration path and avoids duplicated numerical work.

## Traceability

The xyY result shall retain:

- source XYZ values;
- source normalization mode;
- observer metadata when available;
- tristimulus sum;
- conversion description.
