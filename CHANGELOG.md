<!--
SpectraLab Documentation
Document: CHANGELOG.md
Version: v0.5.1
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

| Version | Release Type | Status |
|---------|--------------|--------|
| v0.5.1 | Scientific Archive | Current |
| v0.5.0 | Archive Architecture | Supported |
| v0.4.0 | Foundation Release | Historical |

---

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
