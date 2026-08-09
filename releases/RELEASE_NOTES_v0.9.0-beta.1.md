# SpectraLab v0.9.0-beta.1 Prerelease Notes

Released 2026-08-09 for controlled real-world validation.

SpectraLab v0.9.0-beta.1 is the first field-validation build on the path to
v1.0.0. The current stable production release remains v0.8.2.

## ColorChecker workflow

- Measures a complete rectangular ColorChecker as rows by columns.
- Stores one immutable SLAB-MAT reflectance archive per patch.
- Records session definition, chart identity, calibration history,
  instrument identity, measurement order and patch archive references.
- Supports safe resume while locking instrument identity and resolution.
- Keeps the original measurement-session JSON unchanged by later analysis.

## Colorimetry and integrity

- Converts archived R(lambda) to XYZ and CIELAB under CIE D50, CIE D65 or a
  selected illuminant MAT spectrum.
- Writes derived values to a separate suffixed JSON file.
- Recalculates converted values from every MAT archive during quality control.
- Verifies archive UUIDs and SHA-256 content hashes and rejects manipulated
  or inconsistent converted JSON values.
- Optionally exports a traceable CSV without changing the source archives.

## Reports and figures

- ColorChecker reports include measurement provenance, calibration and
  quality summaries, patch-level hashes and compact XYZ/Lab result tables.
- Each result row includes a small evaluated-colour preview immediately after
  the patch identifier.
- Reflectance plots include an approximate sRGB preview in interactive, PNG
  and PDF output.
- One-shot reflectance reports compare instrument-reported and SpectraLab
  XYZ/Lab values.
- Legend dimensions adapt to their actual content.

## Validation status

- The complete automated MATLAB regression suite passes.
- Report PDF and PNG layouts have been rendered and visually inspected.
- Physical field validation with production ColorChecker measurements is the
  purpose of this beta and remains required before v1.0.0.

## Compatibility

- The SLAB-MAT archive format remains unchanged.
- The v0.8.2 stable release remains available independently.
- This beta must be installed separately from a production v0.8.2 setup.
