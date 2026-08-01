# Spotread outcome fixtures

The `spotread_outcome_*.txt` files are synthetic parser fixtures. They test
the approved outcome vocabulary without claiming to reproduce every message
emitted by ArgyllCMS.

`spotread_i1pro2_calibration_complete.txt` is based on an actual ArgyllCMS
3.5.0/i1Pro2 capture made on 31 July 2026. The physical reference serial
number has been redacted; message order and wording are otherwise preserved.

`spotread_i1pro2_measurement_complete.txt` preserves an actual successful
standard-resolution `-e -s -N -O` capture from the same date. It contains 36
positive samples over 380-730 nm and is used to verify both outcome
classification and spectral parsing.

`spotread_i1pro2_high_resolution.sp` preserves the actual 109-band `-H`
measurement made on 1 August 2026. It covers 370-730 nm at approximately
3.33 nm spacing and is used for parser, analysis and archive regression tests.

Actual ArgyllCMS 3.5.0 and i1Pro2 transcripts shall be collected with:

```matlab
addpath(fullfile(pwd, "tools"))
capture_spotread_one_shot("calibration-required")
capture_spotread_one_shot("calibration-succeeded")
capture_spotread_one_shot("measurement-succeeded")
```

Captured output must be reviewed by the operator before its wording is used
to refine `spectralab.drivers.spotread.OutcomeParser` or promoted to a test
fixture. A captured calibration operation must never be treated as a spectral
measurement.

High-resolution evaluation is explicit and does not change the standard
capture default:

```matlab
capture_spotread_one_shot( ...
    "measurement-succeeded", HighResolution=true)
```
