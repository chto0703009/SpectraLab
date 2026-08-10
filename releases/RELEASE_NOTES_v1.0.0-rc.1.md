# SpectraLab v1.0.0-rc.1 Release Candidate Notes

Released 2026-08-10 as the official release candidate for final controlled
validation before SpectraLab v1.0.0.

This is the best field-tested SpectraLab build and is the recommended build
for continued validation. It is published as a GitHub prerelease and does not
yet replace v0.8.2 as the stable production release.

## Measurement workflows

- One-shot emission and reflectance, emission series and ColorChecker
  acquisition have been exercised with physical hardware.
- Emission series show the numbered measurement in the operator prompt.
- Audible start feedback follows operator confirmation; success and error
  patterns retain the approved one-, two- and five-beep meanings.
- ColorChecker resume requires the original locked instrument and resolution
  and performs a fresh physical calibration.
- Paused acquisition and controlled post-completion remeasurement are now
  explicitly separated in the user workflow.

## Scientific presentation and reports

- Interactive and PNG figures follow the approved 1400 x 700, 2:1 graphical
  profile rather than inheriting the PDF figure geometry.
- Percent transmission and reflectance plots default to a 0–100 % y-axis.
- Transmission, Status A and Status M Results present transmittance in percent
  while retaining dimensionless calculation values internally.
- Two-source transmission and density figures identify Reference and Sample
  archives in a compact, aligned right-side presentation.
- Emission plots preserve integrated power, peak wavelength and peak height.
- PDF Results retain numerical and provenance content without duplicating the
  interactive information panel.

## ColorChecker and colourimetry

- Complete chart acquisition stores one immutable SLAB-MAT archive per patch
  with session provenance and content-hash traceability.
- Conversion recalculates XYZ and CIELAB from archived reflectance spectra for
  D50, D65 or a selected measured illuminant without changing source data.
- Controlled patch remeasurement creates amendment and corrected-session JSON
  files while preserving every original archive.
- Quality comparison against nominal X-Rite data remains explicitly a
  chain-level check rather than a formal inter-laboratory conformity claim.

## Documentation and architecture

- ED-024 defines the canonical plot-presentation architecture.
- User documentation distinguishes a measured transmission source reference
  from reflective white-reference calibration.
- Public ColorChecker quality-control and remeasurement examples are included.

## Validation status

- All current measurement, analysis, plotting, report, ColorChecker,
  conversion, quality-control and correction routines have been exercised and
  approved by the project owner.
- Both the source-tree and clean packaged-release MATLAB regression suites
  passed 494 tests with 0 failed and 0 incomplete.

## Compatibility

- The SLAB-MAT archive format remains unchanged.
- Original ColorChecker sessions, amendments and patch archives remain
  immutable.
- Install this release candidate separately from the stable v0.8.2 release.
