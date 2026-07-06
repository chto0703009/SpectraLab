<!--
SpectraLab Documentation
Document: REPOSITORY_STRUCTURE.md
Version: v0.4.0
Status: FROZEN
-->

# SpectraLab Repository Structure

This document explains how the SpectraLab repository is organised and where different types of work belong.

It is written for developers, contributors and future maintainers.

A repository should be organised so that new contributors can understand it before they modify it.

---

## Design Principles

Every directory has one primary responsibility.

SpectraLab follows four structural principles:

1. **Separation of concerns**  
   Each part of the repository has a clearly defined purpose.

2. **Stable public interface**  
   Applications should depend on the documented public API, not on internal implementation details.

3. **Instrument independence**  
   Adding a new spectrometer should not require changes to user applications.

4. **Documentation follows the software**  
   The documentation is organised around how users and contributors interact with the project.

---

## Top-Level Layout

A typical SpectraLab release contains:

```text
SpectraLab/
    README.md
    setup.m
    startup.m
    run_all_tests.m
    VERSION
    LICENSE
    CHANGELOG.md
    CONTRIBUTING.md
    DISCLAIMER.md
    MANIFEST.md
    ROADMAP.md
    RELEASE_CHECKLIST.md

    spectralab/
    examples/
    tests/
    docs/
    tools/
    releases/
```

The top-level files are the main entry points for users, contributors and release managers.

---

## Main Entry Points

| File | Purpose |
|------|---------|
| `README.md` | Introduces SpectraLab |
| `setup.m` | User-friendly setup command |
| `startup.m` | Prepares MATLAB path and verifies the environment |
| `run_all_tests.m` | Runs the regression test suite |
| `VERSION` | Stores the release version |

New users normally start with `setup` and `measure_led`.

---

## The `spectralab/` Package

`spectralab/` contains the MATLAB package implementation.

It includes the public API and internal implementation required by SpectraLab.

Important package areas include:

```text
+spectralab/
    +core/
    +drivers/
    +io/
    +plot/
    +ui/
```

### `+core/`

Core abstractions such as sessions, spectra, collections, calibration state and status objects.

### `+drivers/`

Instrument drivers and driver-specific support code.

The current release includes the Spotread driver.

### `+io/`

Reading, writing and exporting spectral data.

### `+plot/`

Plotting helpers and visualisation functions.

### `+ui/`

Terminal output helpers used by the interactive workflow.

---

## Public API

Applications should use documented public interfaces such as:

```matlab
spectralab.drivers.createInstrument
spectralab.core.Session
spectralab.plot.spectrum
spectralab.io.saveSpectrum
spectralab.io.exportCsv
spectralab.status
```

Internal implementation may evolve between releases.

The public API is the contract between SpectraLab and its users.

---

## Examples

`examples/` contains ready-to-run examples that demonstrate the intended use of SpectraLab.

Examples are part of the documentation.

They should be:

- simple,
- readable,
- directly executable,
- based on the public API,
- useful to a new user.

Example files include:

```text
examples/measure_led.m
examples/first_measurement.m
examples/compare_two_spectra.m
examples/spotread_i1pro2_measurement.m
```

---

## Tests

`tests/` contains regression tests that protect existing behaviour.

Tests verify public behaviour rather than internal implementation details.

Run all tests with:

```matlab
run_all_tests
```

A release is not considered ready unless the regression test suite passes.

---

## Documentation

`docs/` contains detailed user and developer documentation.

| Document | Purpose |
|----------|---------|
| `GETTING_STARTED.md` | First verified measurement |
| `TROUBLESHOOTING.md` | Recovery from problems |
| `REPOSITORY_STRUCTURE.md` | Project organisation |
| `DEVELOPMENT_PHILOSOPHY.md` | Engineering principles |
| `API_REFERENCE.md` | Public API reference |
| `FILE_FORMAT.md` | File format information |
| `TESTING.md` | Testing information |
| `USER_GUIDE.md` | General user guidance |
| `DEVELOPER_GUIDE.md` | Developer guidance |
| `FAQ.md` | Frequently asked questions |
| `SCIENTIFIC_NOTES.md` | Scientific and measurement notes |

Documentation is part of the product.

---

## Tools

`tools/` contains internal helper programs used by SpectraLab or by the release process.

Users normally do not execute these files directly.

Examples include Python helper scripts used to communicate safely with the external `spotread` process.

---

## Releases

`releases/` contains release notes and related release material.

Release notes summarise the engineering significance of a public release. They are not a substitute for `CHANGELOG.md`.

---

## Adding New Components

When adding new functionality, place it according to its purpose.

| New component | Location |
|---------------|----------|
| New instrument driver | `spectralab/+spectralab/+drivers/` |
| New core abstraction | `spectralab/+spectralab/+core/` |
| New export format | `spectralab/+spectralab/+io/` |
| New plotting helper | `spectralab/+spectralab/+plot/` |
| New user workflow | `examples/` |
| New regression test | `tests/` |
| New user documentation | `docs/` |

If a file does not have a clear home, reconsider whether the design is clear enough.

---

## Where Should I Start?

```text
New user
   |
   v
README.md
   |
   v
docs/GETTING_STARTED.md
   |
   v
examples/measure_led.m
```

Developers should then continue with:

```text
docs/REPOSITORY_STRUCTURE.md
   |
   v
docs/DEVELOPMENT_PHILOSOPHY.md
   |
   v
CONTRIBUTING.md
```

---

## Repository Philosophy

A clean repository is part of the user interface.

A contributor should be able to understand where a change belongs before writing code.

Every directory has one primary responsibility.

Every document has one primary purpose.

Together, the repository structure and documentation should make SpectraLab understandable before it is modified.
