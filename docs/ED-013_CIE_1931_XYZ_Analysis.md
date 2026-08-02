# ED-013 — CIE 1931 XYZ Analysis

**Status:** Accepted implementation  
**Version:** SpectraLab v0.7.0

## Decision

CIE 1931 2° tristimulus values shall be calculated using the existing
first-class spectral-weighting architecture:

```text
spectral input
     ├─ xBar -> filterResponse -> integrate -> X
     ├─ yBar -> filterResponse -> integrate -> Y
     └─ zBar -> filterResponse -> integrate -> Z
```

No separate colour-matching interpolation or weighting subsystem shall be
introduced.

## Normalization

The initial implementation supports:

- `none` — direct relative integrated values;
- `Y100` — common scaling so that Y equals 100.

`Y100` is a relative normalization. It does not imply absolute luminance or
photometric calibration.

## Traceability

The result shall preserve:

- the three wavelength-dependent weighted responses;
- raw integrated X, Y, and Z values;
- normalized values;
- observer identity;
- source provenance;
- wavelength interval;
- integration and normalization metadata.
