# SpectraLab v1.3.1 release verification

Release date: 2026-10-27.

- VERSION, spectralab.version, README, manifest and citation metadata identify 1.3.1.
- Complete MATLAB R2025b regression: 94 test files, 550 cases, zero failures.
- Current technical summary and technical report rebuilt; historical foundation is retained and labelled.
- Scientific corrections and limits are recorded in docs/SCIENTIFIC_REVIEW_20261026.md and releases/RELEASE_NOTES_v1.3.1.md.
- No original measured archive, prior numerical report or Camera-41 accepted project is regenerated.

Build the official clean-commit ZIP with tools/build_release.py --output <folder>. Check its CRC, VERSION, source-commit manifest and every SHA-256; exclude private captures, local runtimes and nested release archives. Tag the reviewed commit as v1.3.1, push it and upload the archive, current PDF documents and SHA256SUMS.txt. Verify the published release and uploaded file digests before reporting completion.

Physical instrument and operating-system combinations have not been newly requalified. Neither ISO Annex B nor ASTM E308 numerical conformance is claimed.
