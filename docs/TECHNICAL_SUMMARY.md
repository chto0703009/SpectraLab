# SpectraLab 1.3.1: technical summary

Release documentation | 2026-10-27 | Christer Törnkvist

## Measure once. Save forever. Verify always.

SpectraLab connects spectral acquisition, immutable archives, defined analyses and traceable PDF/PNG/JSON outputs. It uses standard/base MATLAB and an external acquisition adapter for ArgyllCMS spotread with supported X-Rite instruments. Correct calibration, geometry and physical sample handling remain the operator's responsibility.

## Measurement and preservation

Preserve the wavelength grid, measured values, units, instrument identity, calibration evidence and comments. Source archives remain immutable. Derived calculations and corrected analyses become separate revisions with their own provenance. A checksum verifies recorded content; it cannot validate the physical setup by itself.

## Portable installation

Keep the complete program folder together. Each installation has its own pinned Python 3.13.6 .venv. On macOS, Prepare can obtain a private checksum-verified interpreter without changing system Python. Identify/check remain read-only. First preparation requires internet. See PYTHON_ENVIRONMENT.md and GETTING_STARTED.md.

---

# What changes in 1.3.1

## Density weighting

ISO visual and Status A/M first calculate measured transmission T=S/R, then D=-log10(integral(T*Pi)/integral(Pi)). The complete spectral product Pi is not multiplied by the measured source a second time. Revised results identify DENS-002 and transmittance basis. Explicit source-weighted calculation remains available for diagnostic reproduction; whiteDensity deliberately remains source-weighted and is not ISO visual density.

## Numerical limits

Status A/M log products are interpolated in log space before integration. The integrator is trapezoidal, not ISO Annex B or ASTM E308 weighting. Missing spectral support is recorded; no extrapolation is introduced. Negative signals under active weights require review. Software calculation alone is not full ISO measurement conformity.

## Colour and spectral units

Percent/fraction reflectance units are handled explicitly and fractional ColorChecker artifacts store fractions. Ra is rounded after averaging unrounded R1-R8 values. New explicit spotread emission modes record their documented physical units; historical records are not relabelled or newly calibrated.

---

# Exchange, review and validation

## Camera-41

Transmission and ColorChecker artifacts use the fixed inclusive 400-730 nm exchange interval and reject partial coverage. This boundary does not crop source archives or restrict every CIE calculation. Exported spectral content, identities and provenance allow Camera-41 to calculate camera/film-specific results as separate records.

## Existing measurements

The release does not rewrite original archives, accepted profiles or old reports. Re-evaluate affected density-derived results as new reviewed revisions. SCIENTIFIC_REVIEW_20261026.md contains the calculation comparison and identifies uncertain historical source pairings.

## Verification and scope

Automated scientific regressions run in MATLAB R2025b using synthetic fixtures. Release notes and the validation JSON record the test and package checks. No new physical instrument, printer or complete standards conformance is claimed. The technical report starts with the current 1.3.1 method and retains the older v1.0.1 foundation as a clearly marked historical appendix.

Project: https://github.com/chto0703009/SpectraLab

Contact: christer.tornkvist@angstrom.uu.se
