<!--
SpectraLab Documentation
Document: MANIFEST.md
Version: v0.9.0-beta.1
Status: PRERELEASE
-->

# SpectraLab Release Manifest

This manifest defines what constitutes an official SpectraLab release.

It is not merely an inventory of repository contents.

It defines a complete, verified engineering release.

A release is considered complete only when all required components are present and verified.

---

## Release Identity

| Item | Value |
|------|-------|
| Project | SpectraLab |
| Version | v0.9.0-beta.1 |
| Release type | ColorChecker Field Validation Prerelease |
| License | GNU General Public License v3 |
| Primary environment | MATLAB |
| Current instrument workflow | Bounded ArgyllCMS `spotread` with X-Rite i1Pro2 |

---

## Required Components

An official SpectraLab release shall contain the following components.

---

### Core Software

- MATLAB source code
- Public API
- Core data model
- Instrument drivers
- Plotting utilities
- Scientific analysis functions
- Authoritative report analysis registry
- PDF report generation
- PNG report-figure export
- I/O utilities
- Environment verification
- Structured error handling

Primary location:

```text
spectralab/
```

---

### Main Entry Points

| File | Purpose |
|------|---------|
| `setup.m` | User-friendly setup command |
| `startup.m` | MATLAB path setup and environment verification |
| `run_all_tests.m` | Regression test runner |
| `examples/measurement/measure_spectrum.m` | Bounded automatic measurement example |
| `examples/measurement/measure_spectrum_series_5.m` | Recalibration-aware measurement series |
| `VERSION` | Release version |

---

### Documentation

The official Documentation Pack consists of:

| Document | Purpose |
|----------|---------|
| `README.md` | Project introduction |
| `docs/GETTING_STARTED.md` | First verified measurement |
| `docs/TROUBLESHOOTING.md` | Error diagnosis and recovery |
| `docs/REPOSITORY_STRUCTURE.md` | Repository organisation |
| `docs/DEVELOPMENT_PHILOSOPHY.md` | Engineering principles |
| `CONTRIBUTING.md` | Contribution process |
| `DISCLAIMER.md` | Engineering and scientific responsibility |
| `CHANGELOG.md` | Release history and significance |
| `ROADMAP.md` | Long-term direction |
| `MANIFEST.md` | Release definition |
| `RELEASE_CHECKLIST.md` | Release verification |
| `docs/GP-001_Graphical_Presentation_Profile.md` | Required plot presentation standard |

Additional supporting documentation may be included in `docs/`.

---

### Examples

Examples are part of the release because they demonstrate supported public API usage.

Primary location:

```text
examples/
```

The v0.8.2 release includes categorized measurement, analysis, plotting and
inventory workflows, synthetic non-identifying SLAB-MAT fixtures, and
examples that follow the approved graphical-presentation profile.

---

### Tests

Regression tests are part of the release because they protect expected behaviour.

Primary location:

```text
tests/
```

The official test runner is:

```matlab
run_all_tests
```

---

### License

The release shall include:

- `LICENSE`
- any additional license notes required by the project

---

## Optional Components

A release may also include:

- example datasets,
- reference spectra,
- development utilities,
- additional analysis scripts,
- release notes.

These components may enhance the release but are not required for completeness unless explicitly listed in the release checklist.

---

## Release Verification

An official release is considered complete only after verification that:

- all required files are present,
- documentation is complete,
- regression tests pass,
- public API is verified,
- version information is consistent,
- release checklist has been completed and approved.

A release is defined by verified completeness rather than by the existence of an archive file.

---

## Integrity and Preservation

Every official SpectraLab release should remain a self-contained engineering package.

A future user should be able to:

- understand the software,
- reproduce its behaviour,
- verify its functionality,
- understand the engineering decisions,

using only the contents of the release package.

Essential engineering knowledge should not depend on private notes, unpublished discussions or external resources.

The release itself should remain the authoritative engineering record.

---

## Conceptual Release Package

A typical official release has the conceptual form:

```text
SpectraLab_v0.8.1/
    README.md
    LICENSE
    VERSION
    setup.m
    startup.m
    run_all_tests.m

    spectralab/
    examples/
    tests/
    docs/
    tools/
    releases/

    CHANGELOG.md
    CONTRIBUTING.md
    DISCLAIMER.md
    MANIFEST.md
    ROADMAP.md
    RELEASE_CHECKLIST.md
```

---

## Final Statement

An official SpectraLab release is more than software.

It is a verified engineering package consisting of source code, documentation, examples, tests and release verification.

Together these components preserve both the implementation and the engineering knowledge required to understand and maintain the project.
