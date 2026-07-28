- Spectrum colour guides now span the displayed wavelength range and render regions outside 380–730 nm in black; corrected custom `YLimits` validation.

## v0.8.0-dev — RP-016 Figure Caption
### RP-017a visual reference corrections

- Spectrum plots now start at y = 0 by default; `YLimits` can explicitly request another range.
- The default spectrum line width is reduced from 1.5 to 1.0.
- PDF reports embed the actual report-owned figure instead of a placeholder.
- PDF export preserves the full A4 page canvas so the defined 20 mm margins are retained.


- Added a canonical primary-figure caption model.
- Added deterministic caption measurement and PDF rendering.
- Added layout look-ahead so a figure and its caption remain on the same page.
- Added regression tests for caption modelling, manifest order, rendering, and grouped pagination.

### RP-017 - End-to-end reference report
- Added `generate_reference_cri_report` to create a visual-review PDF and PNG.
- Completed metadata, analysis, provenance, and footer presentation models needed by the standard manifest.
- Added an end-to-end integration test for the complete reference-report pipeline.

## Unreleased
- Fixed report PNG export to preserve the declared figure canvas aspect ratio by using a fixed paper surface rather than tight content cropping.

## v0.8.0-dev — RP-015 report figure PNG export

- Added atomic full-resolution PNG export in the report layer.
- PNG export uses the declared report figure geometry and a report-owned axes object.
- Existing files are never overwritten.
- Source figures and axes are preserved unchanged during export.
- Plot functions remain free from file-export responsibility.


### RP-014 spectral colour bar

- Added a thin 380--730 nm wavelength colour guide to `spectralab.plot.spectrum`.
- The guide is enabled by default and may be disabled with `ShowSpectralColorBar=false`.
- The implementation preserves axes limits and hold state and contains no colourimetric claims.

<!--

## RP-009 — Automatic page breaking

- Added automatic page breaks between measured document elements.
- Added explicit rejection of elements taller than one A4 content area.
- Kept all page-placement decisions inside the Layout Engine.

SpectraLab Documentation
Document: CHANGELOG.md
Version: v0.6.0
Status: CURRENT
-->

# Changelog

This changelog records the engineering significance of public SpectraLab releases.

It is not a commit log and does not list every internal modification.

Every public release represents a verified engineering milestone rather than a collection of completed tasks.

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
| v0.6.0 | Scientific Archive and Metadata | Current |
| v0.5.1 | Scientific Archive | Supported |
| v0.5.0 | Archive Architecture | Historical |
| v0.4.0 | Foundation Release | Historical |

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
