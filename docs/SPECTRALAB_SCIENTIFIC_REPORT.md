# SpectraLab scientific report - v1.3.1

Documentation updated 2026-10-27.

The current technical report is `docs/scientific-reports/spectralab_spectral_measurement_analysis_and_provenance.pdf`.
It begins with the current v1.3.1 calculation, exchange and provenance contract and retains the v1.0.1 technical foundation as a clearly marked historical appendix. Current sections take precedence over historical formulas and version claims.

The current concise introduction is `docs/spectralab_summary_spectral_measurement.pdf`.
Editable sources are `docs/RELEASE_GUIDE.md` and `docs/TECHNICAL_SUMMARY.md`.
Rebuild both with `tools/build_release_documentation.py` (ReportLab and pypdf required only for authoring documentation).
The original technical foundation is preserved at `docs/scientific-reports/foundation-v1.0.1-historical.pdf`.

The package runtime still uses standard/base MATLAB for scientific reports. This documentation authoring tool does not add a Python PDF dependency to measurement or analysis.
See `SCIENTIFIC_REVIEW_20261026.md` for the numerical changes and qualification limits.
