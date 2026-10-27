# SpectraLab v1.3.1 - 2026-10-27

This patch corrects scientific calculations and portable-startup documentation. It preserves original measurement archives and prior results; recalculate affected analyses as separate reviewed revisions.

- ISO visual and Status A/M calculate transmission S/R before applying their complete spectral weighting products (DENS-002). Explicit source-weighted compatibility remains available; whiteDensity deliberately remains source-weighted.
- Interpolate documentary Status A/M log products in log space. Record incomplete wavelength support; retain trapezoidal integration and the stated standards-conformance limits.
- Correct Ra rounding and explicit percent/fraction reflectance conversion, including fractional ColorChecker artifacts.
- Restore the fixed inclusive 400-730 nm Camera-41 export/display contract without cropping immutable source archives or extrapolating data.
- Record documented units for new explicit spotread emission modes; old archives are not relabelled.
- Preserve datetime reconstruction residuals in new emission JSON so subcomponent rounding does not alter restored timestamps; older packets remain readable.
- Include private Python preparation and revised release/installation metadata.
- Publish current technical summary and report, with the older technical foundation clearly marked as historical.

Validation: 94/94 MATLAB test files, 550 test cases, zero failures. Further qualification evidence: see docs/release-validation-v1.3.1.json. Scientific regressions run with MATLAB R2025b and synthetic fixtures. No new physical-instrument qualification, ISO Annex B or ASTM E308 implementation is claimed. A rejected negative/zero-reference analysis does not delete its measured source archive.

Use SpectraLab_v1.3.1.zip. SHA256SUMS.txt covers the ZIP and documentation assets; RELEASE_MANIFEST.json inside the ZIP records the source commit and per-file hashes. Historical release packages are unchanged.
