# SpectraLab v1.0.0 Release Notes

Released 2026-08-11 as the first stable SpectraLab v1 release.

SpectraLab v1.0.0 is the result of staged beta and release-candidate testing,
full automated regression and physical verification with supported Spotread
instrument workflows. It replaces v0.8.2 as the recommended stable release.

## Measurement workflows

- One-shot emission and reflectance, emission series, transmission pairs and
  ColorChecker acquisition use bounded, traceable measurement workflows.
- Physical calibration failures stop acquisition without saving invalid data.
- ColorChecker resume preserves the locked instrument and resolution and
  requires a fresh calibration before further patch measurements.
- Every accepted patch is stored immediately as an immutable SLAB-MAT archive.

## ColorChecker and colourimetry

- The X-Rite ColorChecker Digital SG 140 has an architecture-controlled target
  identity, geometry and SHA-256 definition.
- Complete sessions preserve raw reflectance spectra, measurement provenance,
  corrections and content hashes without storing derived colour values in the
  source record.
- XYZ and CIELAB can be recalculated for D50, D65 or a selected measured
  illuminant and written to a separate verified JSON.
- Controlled remeasurement preserves the original session and creates an
  amendment plus a corrected derived session.
- Comparison with nominal X-Rite CIELAB data is explicitly reported as a
  measurement-chain consistency check, not formal conformity validation.

## Analysis, figures and reports

- Emission, reflectance and transmission figures follow the approved graphical
  presentation profile and use consistent, non-overlapping information areas.
- Reflectance and transmission default to a 0--100 % y-axis.
- Registered analyses generate traceable PDF reports and, where applicable,
  full-resolution PNG figures.
- PDF and PNG exports use independent graphics contexts, preventing export
  order or MATLAB global graphics state from invalidating ANL-007 output.

## Examples and interoperability

- Release-packaged examples cover emission, transmission, reflectance,
  ColorChecker acquisition, conversion, quality control, correction, plotting
  and reporting.
- ED-025 defines the read-only hand-off to Camera-41: SpectraLab supplies the
  measured target, illuminant and integrity provenance; Camera-41 owns RAW
  target detection, capture-quality assessment and camera RGB calibration.

## Verification

- All current physical workflows were exercised and approved by the project
  owner during the beta and release-candidate programme.
- The full source-tree MATLAB regression passed 498 tests with 0 failed and
  0 incomplete on 2026-08-11.
- The packaged release is regression-tested again before publication.

## Compatibility

- The SLAB-MAT archive format remains unchanged.
- Original ColorChecker sessions, amendments and patch archives remain
  immutable.
- Existing v0.8 and prerelease installations may be retained independently;
  install v1.0.0 in its own directory.
