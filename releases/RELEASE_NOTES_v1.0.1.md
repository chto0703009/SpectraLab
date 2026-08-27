# SpectraLab v1.0.1 Release Notes

Released 2026-08-27.

SpectraLab v1.0.1 is a compatible stabilization release following v1.0.0.
It preserves the accepted measurement, archive and analysis contracts while
correcting issues found during practical use.

## Measurement workflows

- New analysis sessions remember the most recently used archive folder.
- Calibration placement prompts in emission series are modal.
- Reflectance and emission entry points identify their measurement kind
  clearly, and one-shot terminology is consistent.

## Emission, analysis and figures

- One-shot emission PNGs include peak wavelength, peak value, spectral
  integral, range, sample count, operator, instrument and provenance.
- Emission-derived analyses, including CRI, retain their scientific results
  in the report while PDF figures remain clean graphical components.
- Spectral mean stability uses relative RMS difference, avoiding inflated
  percentages caused by pointwise division near zero.
- Large source legends use a smaller font to remain within the figure.

## Reports

- PDF footers identify the report filename.
- Measurement comments are retained in the Measurement section.
- ColorChecker session and colorimetry reports use the same base-MATLAB PDF
  backend as other SpectraLab reports.

## Compatibility and verification

- Existing SpectraLab archives remain supported and unchanged.
- Standard/base MATLAB is the only required MathWorks product.
- ArgyllCMS `spotread`, Python, `pexpect` and `ptyprocess` remain external
  acquisition dependencies and are not MATLAB toolbox dependencies.
- All 86 test files and 515 test cases passed with zero failures and zero
  incomplete tests on MATLAB R2025b.
- The affected workflows were approved through practical use before release.

## Upgrade

Install `SpectraLab_v1.0.1` in its own directory. Existing measurement
archives and Work data should remain outside the release directory and do not
need conversion.
