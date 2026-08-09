# Changelog

This changelog records the engineering significance of public SpectraLab releases.

It is not a commit log and does not list every internal modification.

Every public release represents a verified engineering milestone rather than a collection of completed tasks.

---

## Traceable ColorChecker Validation Beta - v0.9.0-beta.2

Released 2026-08-09 for continued controlled real-world validation.

### Added

- Controlled patch remeasurement with immutable original sessions, separate
  amendment records, corrected derived sessions and chained integrity checks.
- Public quality-control examples for comparison with nominal X-Rite CIELAB
  reference data and for selective ColorChecker patch remeasurement.
- Official X-Rite ColorChecker Digital SG and reference-data documentation
  links in the quality-control workflow.

### Verified

- A complete 140-patch ColorChecker acquisition and D50 colorimetry conversion
  were completed without workflow errors.
- Selective correction of deliberately identified patch measurements was
  completed through two chained amendments while preserving original data.
- Four one-shot reflectance measurements agreed with Spotread colour values
  at the second decimal place.
- The complete automated MATLAB regression suite passes.

### Release status

This remains a prerelease for broader physical field validation. The current
stable release remains v0.8.2.

---

## ColorChecker Field Validation Beta - v0.9.0-beta.1

Released 2026-08-09 for controlled real-world validation.

### Added

- Complete ColorChecker reflectance acquisition with resumable sessions,
  immutable MAT archives per patch and session-level JSON traceability.
- Derived ColorChecker XYZ and CIELAB conversion under bundled CIE D50,
  bundled CIE D65 or a selected illuminant spectrum.
- Recalculation-based integrity verification of converted colorimetry against
  the immutable patch spectra, UUIDs and SHA-256 content hashes.
- Optional traceable ColorChecker CSV export.
- ColorChecker PDF reports containing session provenance, quality summaries,
  patch-level traceability and compact evaluated-colour previews.

### Improved

- One-shot reflectance reports compare Spotread and SpectraLab colorimetry.
- Reflectance figures and report products include an approximate sRGB colour
  preview while keeping numerical results in the appropriate report section.
- Side legends adapt their dimensions to the number and length of entries.
- Spotread one-shot spectrum validation tolerates the instrument's harmless
  text/file representation differences while retaining strict data checks.

### Release status

This is a prerelease for physical field validation. The current stable
release remains v0.8.2. Successful field validation leads to v1.0.0 release
candidates and subsequently v1.0.0.

---

## Presentation Standard and Reliable Report Exports - v0.8.2

Released 2026-08-06.

### Improved examples

- Physical measurement examples now show Spotread's USB identification and
  let the user confirm `i1Pro` or `i1Pro2` for archive provenance.
- The instrument serial number is locked after calibration and verified
  after every measurement before MAT, PDF or PNG output is saved.
- Standard and high-resolution acquisition with an original GretagMacbeth
  Eye-One Pro Rev. B (recorded as `i1Pro`) were physically verified against
  the examples alongside the established X-Rite i1Pro2 workflow.
- Every PDF provenance table identifies the instrument immediately before
  its serial number, including both ordered instruments in pair analyses.
- ANL-007 ISO Visual Density now owns a registered spectral-density figure
  used consistently for PDF and PNG output.
- Audible measurement feedback uses a clearer 1200 Hz tone while retaining
  the established one-, two- and five-beep event patterns.
- Mean spectra report pointwise standard deviation and mean relative
  standard deviation to quantify measurement stability.
- Spectral-difference reports provide RMS and maximum absolute difference.
- Report figures use the approved right-side information layout: data are
  never obscured by legends or text, and PNG and PDF preserve the legend.
- Archive and folder-selection dialogs identify the requested analysis and
  archive role explicitly.
- Report PNG output can be written directly to its plot folder without a
  temporary file appearing in the report folder.
- Public examples follow the same output-folder and graphical-presentation
  contracts as the application workflows.

---

## Measurement Workflow and Reproducible Examples - v0.8.1

Released 2026-08-02.

SpectraLab v0.8.1 completes RP-021 and strengthens acquisition,
traceability, derived analysis and reproducible use without changing the
released archive format.

### Added

- Bounded Spotread one-shot calibration and measurement using `-O` and the
  physically verified `-N -O` measurement path.
- Optional i1Pro2 high-resolution acquisition using `-H` for both
  calibration and measurement.
- Instrument-switch triggering as an explicit alternative to the default
  modal placement confirmation.
- ANL-009 Spectral Mean with a traceable derived MAT archive recording both
  source archives and their ordered roles.
- ANL-010 Spectral Difference as a signed diagnostic report without a
  derived archive.
- Categorized release examples for measurement, registered analysis,
  plotting and archive inventory.
- Three deterministic, synthetic and non-identifying SLAB-MAT example
  archives.

### Improved

- Automatic measurement retries once after a controlled recalibration when
  Spotread reports that calibration is required.
- Five-measurement series calibrate initially, save each successful result
  immediately and stop on non-recoverable hardware or process errors.
- Measurement workflows reject dark or non-positive signals before archive
  creation.
- Physical instrument serial numbers from Spotread are propagated into new
  measurement archives and reports.
- Long provenance values and source filenames wrap within report boxes.
- Measurement comments and source identities are retained throughout
  reports.
- Audible feedback uses one tone frequency: one beep at start, two after
  success and five after failure.
- Startup verifies and reports both `pexpect` and `ptyprocess`.
- Plot examples create PNG only; report analyses follow the
  `calculate_*_report` naming contract.

### Quality and provenance

- Spotread one-shot operations request verbose instrument information and
  record the physical instrument serial number in new measurement archives.
- A missing or unrecognized serial number remains a validation warning rather
  than causing a valid measurement to be discarded.
- Startup reports and verifies both direct Python dependency `pexpect` and its
  runtime dependency `ptyprocess` independently.
- Audible operation feedback uses one consistent tone frequency: one beep at
  start, two after success and five after failure.
- A measurement series performs one controlled white-reference recalibration
  and retry when Spotread reports that calibration has expired.
- Measurement series stop immediately after non-recoverable Spotread hardware,
  USB communication, timeout, calibration or process failures.
- Single-measurement and five-measurement workflows were physically verified
  with an X-Rite i1Pro2, including MAT, PDF and PNG output.
- All non-hardware release examples were executed from a temporary clean
  example tree.
- 73 test files and 465 test cases passed with 0 failed and 0 incomplete.

---

## Versioning Policy

SpectraLab uses version numbers to communicate release significance.

- **Major versions** may introduce major architectural or compatibility changes.
- **Minor versions** introduce significant improvements while preserving the public API whenever practical.
- **Patch versions** correct defects or improve documentation without changing intended behaviour.

Only public releases are recorded as release history.

---

## Release History

| Version | Release | Status |
|---|---|---|
| v0.8.2 | Presentation Standard and Reliable Report Exports | Current |
| v0.8.1 | Measurement Workflow and Reproducible Examples | Supported |
| v0.8.0 | Analysis and Reporting | Supported |
| v0.6.0 | Scientific Archive and Metadata | Supported |
| v0.5.1 | Scientific Archive | Historical |
| v0.5.0 | Archive Architecture | Historical |
| v0.4.0 | Foundation Release | Historical |

---

## Analysis and Reporting — v0.8.0

SpectraLab v0.8.0 adds a verified scientific analysis and reporting layer
above the established measurement and archive architecture.

### Added

- Spectral transmission and optical-density analysis.
- A common weighted-density engine.
- White, Status A, ISO visual and Status M density analysis.
- CIE XYZ, xyY and CIELAB analysis with explicit provenance.
- Colour rendering analysis and versioned CIE test-colour sample data.
- A standard spectral-filter library with integrity verification.
- Deterministic A4 PDF reports with structured metadata, results,
  provenance, captions and page framing.
- Full-resolution PNG export for analyses that define a primary figure.
- A canonical analysis registry that is the sole authoritative definition
  of every reportable analysis.
- Public analysis discovery through `spectralab.report.listAnalyses` and
  `spectralab.report.describeAnalysis`.
- End-to-end reference-report examples and tests.

### Improved

- Spectrum plots include a wavelength colour guide from 380 to 730 nm.
- All standard plot types start at y = 0 by default.
- Report figures use labelled wavelength and quantity axes.
- PDF output embeds the actual report-owned figure and preserves the
  complete A4 canvas with defined margins.
- Figure captions remain grouped with their figures during pagination.
- The test runner discovers the complete regression suite automatically.

### Compatibility

- The public measurement and archive workflows remain compatible with the
  established v0.x API.
- CSV and text export remain available.
- Historical release documentation and released archive formats are
  preserved.

### Verification

- 65 test files passed.
- 434 test cases passed with 0 failed and 0 incomplete.
- The interactive X-Rite i1Pro2 workflow was verified through ArgyllCMS
  `spotread`.

---

## Scientific Archive and Metadata — v0.6.0

SpectraLab v0.6.0 strengthens the scientific archive workflow with
structured metadata, provenance preservation, archive validation and
verified round-trip integrity.

### Added

- Session metadata for Operator, Comment, Project and SampleID.
- Centralized metadata validation.
- Structured archive summaries.
- Archive integrity validation.
- Direct archive-file inspection with `spectralab.archive.info`.
- Optional validation during archive loading.
- Validated archive restoration.

### Improved

- Instrument and calibration provenance propagation.
- Preservation of archive metadata during restoration.
- Informative and quiet archive-loading workflows.
- Compatibility handling for older archives with missing optional metadata.

### Fixed

- Instrument metadata being replaced by empty archive fields.
- Metadata loss during archive restoration.
- Measurement timestamp loss during restoration.
- Changed `ContentHash` after archive round trips.

### Verification

- 52 automated regression tests pass.
- No failed or incomplete tests.

## Scientific Archive — v0.5.1

### Why this release exists

Version 0.5.1 completes the engineering work required before SpectraLab
moves from infrastructure development to scientific analysis.

The release focuses on archive usability, scientific provenance,
metadata consistency and release quality without changing the released
archive structure.

### Engineering improvements

- Canonical operator provenance
- Structured metadata mapping
- Archive summary
- Informative and quiet archive loading
- Safe archive filename handling
- Documentation and version consistency
- Regression-tested maintenance improvements

### User impact

Users can now identify, understand and manage archived measurements more
easily while maintaining compatibility with previously released archive
formats.

### Compatibility

No breaking changes have been introduced.

Archives produced by previous released versions remain readable.

The archive structure established during the v0.5 release series is
considered stable for future analytical development.

## Foundation Release — v0.4.0

### Why this release exists

SpectraLab v0.4.0 establishes the first stable engineering foundation for reliable spectral measurements in MATLAB.

The focus of this release is not feature quantity. The focus is a robust architecture, stable public API, verified instrument workflow, regression tests and documentation that makes the project understandable and maintainable.

### Why this release matters

This release turns SpectraLab from an instrument-specific experiment into an engineering framework for spectral measurement workflows.

It establishes the design principles future releases should preserve.

### Engineering improvements

#### Stable public MATLAB API

The public workflow is based on:

- instrument creation,
- session management,
- calibration,
- measurement,
- spectrum objects,
- plotting,
- export.

This protects user applications from internal implementation details.

#### Instrument-independent architecture

Instrument-specific behaviour is isolated inside drivers.

The current release supports ArgyllCMS `spotread` and the X-Rite i1Pro2 workflow, while the architecture is prepared for additional instruments.

#### Interactive measurement workflow

Calibration and measurement are explicitly interactive for the current Spotread driver.

The workflow reflects the physical nature of the measurement: the user must position the instrument before calibration and measurement.

#### Environment verification

`setup` and `startup` verify the software environment before measurement.

This reduces configuration errors by checking MATLAB, Python, `pexpect`, ArgyllCMS and `spotread`.

#### Structured error handling

SpectraLab introduces SPL error codes to help users understand what went wrong and what to do next.

#### Regression test suite

The release includes a regression test suite covering the core data model, I/O, exports, plotting helpers, error paths, mock workflows and Spotread parser fixtures.

#### Documentation Pack

The v0.4.0 release establishes the official SpectraLab Documentation Pack, including user, developer, engineering responsibility and release process documents.

#### Engineering responsibility

The release introduces explicit documentation on scientific and engineering responsibility, making clear that SpectraLab assists engineering work but does not replace judgement.

### User impact

Users can:

- install SpectraLab,
- verify the environment,
- run a first measurement,
- inspect spectra,
- plot results,
- export data,
- run tests,
- diagnose common problems using SPL codes.

### Compatibility

The public API is considered stable within the v0.x release series.

`interactive` is the default measurement mode. The explicit syntax is recommended in scripts:

```matlab
sess = sess.calibrate("Mode", "interactive");
spec = sess.measure("LED spectrum", "Mode", "interactive");
```

`automatic` mode is reserved for future instruments and is not supported by the current Spotread workflow.

### Known limitations

- The verified instrument workflow is based on ArgyllCMS `spotread` and X-Rite i1Pro2.
- Automatic measurement mode is not implemented in v0.4.0.
- Additional instruments require driver verification before being considered supported.

---

## Future Releases

Future public releases will continue to document significant engineering improvements using the same principles.
