<!--
SpectraLab Documentation
Document: README.md
Version: v0.4.0
Status: FROZEN
-->

# SpectraLab

> **Measure once. Save forever. Verify always.**

SpectraLab is an open-source MATLAB toolbox for reliable spectral measurements.

It provides a stable engineering framework for acquiring, managing, analysing and preserving calibrated spectra while keeping measurement workflows simple, reproducible and understandable.

The current release supports ArgyllCMS `spotread` together with the X-Rite i1Pro2 spectrophotometer. The architecture is instrument-independent and designed for future expansion.

---

## Why SpectraLab?

Reliable measurements require reliable software.

SpectraLab was developed to provide a clean separation between measurement, data management, visualisation, export and instrument communication. This makes user applications independent of specific instruments while allowing new devices to be added through dedicated drivers.

The goal of the v0.4.0 release is long-term stability rather than rapid feature growth.

---

## Features

- Interactive spectral measurements
- Stable public MATLAB API
- Instrument-independent architecture
- Publication-quality plotting
- JSON-based measurement storage
- CSV and text export
- Automatic environment verification
- Structured error reporting using SPL codes
- Regression-tested core library
- Comprehensive documentation

---

## Supported Environment

The v0.4.0 release has been verified with the following environment.

| Component | Recommended |
|-----------|-------------|
| MATLAB | R2024b or later |
| Python | 3.10 or later |
| ArgyllCMS | 3.5 or later |
| pexpect | 4.9 or later |

Earlier versions may work, but they are not part of the verified release configuration.

Run `setup` to let SpectraLab verify the environment before the first measurement.

---

## Installation

Clone the repository.

```bash
git clone https://github.com/<user>/SpectraLab.git
```

Open MATLAB, change to the SpectraLab project directory and run:

```matlab
setup
```

`setup` prepares the MATLAB path and verifies that required external components are available.

The real GitHub URL should be inserted when the public repository is created.

---

## First Measurement

```matlab
setup

measure_led
```

`measure_led` runs in **interactive mode**.

During calibration and measurement, SpectraLab will prompt you in the MATLAB Command Window to:

1. Place the instrument on the white reference.
2. Press **ENTER**.
3. Place the instrument on the light source.
4. Press **ENTER**.

Follow the on-screen instructions until the measurement is complete.

---

## Public API

A typical workflow is:

```matlab
inst = spectralab.drivers.createInstrument("spotread");

sess = spectralab.core.Session(inst);
sess = sess.open();

sess = sess.calibrate("Mode", "interactive");

spec = sess.measure("LED spectrum", "Mode", "interactive");

disp(spec.summary())

spectralab.plot.spectrum(spec)
```

For convenience, the default mode is `interactive`, so existing code can also use:

```matlab
sess = sess.calibrate();
spec = sess.measure("LED spectrum");
```

The explicit `"Mode", "interactive"` syntax is recommended in scripts because it documents that the workflow requires user interaction.

The public API is considered stable within the v0.x release series.

---

## Measurement Modes

### interactive (default)

The current release operates in **interactive mode**.

SpectraLab guides the user through calibration and measurement using prompts in the MATLAB Command Window. This reflects the physical workflow of the currently supported Spotread driver, where the user must position the instrument before continuing.

### automatic (reserved)

`automatic` mode is reserved for future instruments capable of calibration and measurement without user interaction. It is recognized by the API but is not supported by the current Spotread workflow.

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
