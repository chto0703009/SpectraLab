# SpectraLab v1.3.0

Released 2026-10-21.

This release adds self-contained spectral JSON exchange for measured ColorChecker targets and lamp emission measurements, including series. Supported exports retain patch IDs, wavelength grids, units, physical bindings, archive provenance and content hashes for use in Camera-41_DC and Camera-41_PRE.

## Included changes

- ColorChecker spectral JSON exporter and acquisition/remeasurement example integration.
- Emission JSON exporter, importer, binding dialog and single/series measurement integration.
- Canonical JSON/hash helpers, validation and exchange regression tests.
- Reflectance-series example and local X-Rite nominal-table conversion tool. X-Rite manufacturer values are not included in that tool.
- Measurement metadata preservation and improved PNG report export that preserves both information and colour-swatch panels.
- Existing post-v1.2.0 fixes, including version-independent dialog titles.

## Requirements and verification

Standard/base MATLAB remains the supported runtime policy; MathWorks add-on toolboxes are not required. Physical acquisition additionally needs the supported measurement instrument and its existing spotread setup.

Automated regression passed in MATLAB R2025b: 92 test files, 539 test cases, zero failures. Newly changed physical acquisition dialogs have not been requalified with every instrument or operating system. Release publication does not assert otherwise. Camera-41_DC/PRE manual integration checks remain separate from SpectraLab regression tests.

Use the attached SpectraLab_v1.3.0.zip for the packaged application, or the Git source archives. See docs/COLORCHECKER_SPECTRA_JSON.md and docs/EMISSION_SPECTRA_JSON.md for exchange contracts. GPL and dataset-specific notices remain attached.
