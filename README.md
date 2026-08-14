<!--
SpectraLab Documentation
Document: README.md
Version: v1.0.1-dev
Status: DEVELOPMENT
-->

# SpectraLab

> **Measure once. Save forever. Verify always.**

This worktree is the `v1.0.1-dev` patch-development line for corrections to
the accepted v1.0.0 release. It is not a published release.

SpectraLab is an open-source MATLAB toolbox for reliable spectral measurements.

It provides a stable engineering framework for acquiring, managing, analysing and preserving calibrated spectra while keeping measurement workflows simple, reproducible and understandable.

The current release supports ArgyllCMS `spotread` together with the X-Rite i1Pro2 spectrophotometer. The architecture is instrument-independent and designed for future expansion.

The post-release measurement examples have also been physically verified
with an original GretagMacbeth Eye-One Pro Rev. B, identified in SpectraLab
as `i1Pro`, in both standard and high-resolution modes. This result is
consistent with ArgyllCMS Spotread's own device identification and support.

---

## Current Release

**SpectraLab v1.0.0** is the current stable production release. It completes
the field-validated measurement, analysis, reporting and ColorChecker
workflows established through the v0.9 betas and v1.0 release candidate.

- [v1.0.0 release notes](releases/RELEASE_NOTES_v1.0.0.md)
- [Download SpectraLab v1.0.0](https://github.com/chto0703009/SpectraLab/releases/download/v1.0.0/SpectraLab_v1.0.0.zip)
- [Getting started](docs/GETTING_STARTED.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

The `main` branch represents the latest published release. Named development
branches are working branches and should not be treated as release packages.
For a fixed, reproducible installation, use the versioned ZIP above.

---

## Why SpectraLab?

Reliable measurements require reliable software.

SpectraLab was developed to provide a clean separation between measurement, data management, visualisation, export and instrument communication. This makes user applications independent of specific instruments while allowing new devices to be added through dedicated drivers.

The v1.0.0 release combines traceable measurement and archive handling with
registered analysis, controlled ColorChecker workflows, reliable PDF and PNG
output, and one graphical presentation standard.

---

## Features

- Bounded automatic and retained interactive spectral measurements
- Standard and optional high-resolution i1Pro2 acquisition
- Stable public MATLAB API
- Instrument-independent architecture
- Publication-quality plotting
- Registered scientific analyses
- PDF reports with analysis-specific figures where applicable
- Full-resolution PNG export of report figures
- Controlled ColorChecker acquisition, conversion and remeasurement
- Architecture-controlled target identity and integrity verification
- JSON-based measurement storage
- CSV and text export
- Automatic environment verification
- Structured error reporting using SPL codes
- Regression-tested core library
- Comprehensive documentation

---

## Supported Environment

The v1.0.0 release has been verified with the following environment.

| Component | Recommended |
|-----------|-------------|
| MATLAB | R2024b or later |
| Python | 3.10 or later |
| ArgyllCMS | 3.5 or later |
| pexpect | 4.9 or later |
| ptyprocess | 0.7 or later |

Earlier versions may work, but they are not part of the verified release configuration.

Run `setup` to let SpectraLab verify the environment before the first measurement.

---

## Installation

Clone the repository.

```bash
git clone https://github.com/chto0703009/SpectraLab.git
```

Open MATLAB, change to the SpectraLab project directory and run:

```matlab
setup
```

`setup` prepares the MATLAB path and verifies that required external components are available.

---

## First Measurement

```matlab
setup

measure_spectrum
```

`measure_spectrum` runs the bounded **automatic mode** and saves a trusted
MAT archive, registered PDF report and PNG figure below `examples/output/`.

During calibration and measurement, SpectraLab will ask you to:

1. Place the instrument on the white reference.
2. Confirm calibration when Spotread is ready.
3. Place the instrument on the light source.
4. Confirm measurement when Spotread is ready.

Follow the on-screen instructions until the measurement is complete.

---

## Public API

A typical workflow is:

```matlab
inst = spectralab.drivers.createInstrument("i1Pro2");

sess = spectralab.core.Session(inst);
sess = sess.open();

sess = sess.calibrate("Mode", "automatic");

spec = sess.measure("LED spectrum", "Mode", "automatic");

disp(spec.summary())

spectralab.plot.spectrum(spec)
```

The retained interactive fallback remains available:

```matlab
sess = sess.calibrate();
spec = sess.measure("LED spectrum");
```

The explicit mode syntax is recommended because it documents the intended
process-control contract.

The public API is considered stable within the v0.x release series.

---

## Measurement Modes

### automatic (supported and recommended)

For the i1Pro2, v0.8.1 supports a bounded automatic Spotread workflow for
calibration and measurement. Each operation runs in a separate one-shot
process, waits for an explicit ready state and accepts a result only after
the returned spectrum has been validated. Placement confirmations remain
visible because the user must physically position the instrument.

Use the explicit mode in measurement scripts:

```matlab
sess = sess.calibrate("Mode", "automatic");
spec = sess.measure("LED spectrum", "Mode", "automatic");
```

### interactive (API default and retained fallback)

For backward compatibility, omitting `Mode` still selects `interactive`.
The established Command Window workflow remains supported as a fallback and
can also be selected explicitly. New i1Pro2 measurement workflows should use
the bounded `automatic` mode above.

---

## Documentation

| Document | Purpose |
|----------|---------|
| `docs/GETTING_STARTED.md` | First-time installation and first verified measurement |
| `docs/TROUBLESHOOTING.md` | Error diagnosis and recovery |
| `docs/REPOSITORY_STRUCTURE.md` | Project organisation |
| `docs/DEVELOPMENT_PHILOSOPHY.md` | Engineering principles |
| `CONTRIBUTING.md` | Contribution guidelines |
| `DISCLAIMER.md` | Engineering and scientific responsibility |
| `CHANGELOG.md` | Release history and engineering significance |
| `ROADMAP.md` | Long-term engineering direction |
| `MANIFEST.md` | Definition of an official release |
| `RELEASE_CHECKLIST.md` | Release verification checklist |

---

## Quality

Every public release is verified using:

- automated regression tests,
- quality gates,
- documentation review,
- real instrument verification.

Passing all tests demonstrates that no known regressions have been introduced. It does **not** prove that the software is free from defects.

Quality gates exist to discover problems, not to prove perfection.

---

## Engineering Responsibility

SpectraLab assists scientific and engineering measurements.

It does not replace scientific or engineering judgement.

The user remains responsible for evaluating measurements and engineering conclusions before they are used in research, engineering, industrial processes or safety-related applications.

See `DISCLAIMER.md` for the full engineering and scientific responsibility statement.

---

## Contributing

Contributions are welcome.

Before contributing, please read:

- `CONTRIBUTING.md`
- `docs/DEVELOPMENT_PHILOSOPHY.md`
- `docs/REPOSITORY_STRUCTURE.md`

Understanding the project's engineering philosophy is considered as important as understanding its code.

---

## License

SpectraLab is released under the GNU General Public License Version 3.

See `LICENSE` for details.

---

## Project Philosophy

Reliable software supports reliable measurements.

Reliable measurements require engineering judgement.

Engineering judgement requires critical thinking.

Documentation is part of the product.

Software assists engineering decisions.

Engineers remain responsible for those decisions.

---

**SpectraLab**

**Measure once.**

**Save forever.**

**Verify always.**
