<!--
SpectraLab Documentation
Document: GETTING_STARTED.md
Version: v0.8.2
Status: CURRENT
-->

# Getting Started with SpectraLab

This guide takes you from a fresh SpectraLab checkout to your first verified spectrum.

It is written for first-time users. It does not explain the internal architecture. It explains what you need to do in order to start measuring.

Estimated time: **10–15 minutes**, assuming MATLAB, Python and ArgyllCMS are already installed.

---

## What You Will Accomplish

After completing this guide you will have:

- installed SpectraLab on the MATLAB path,
- verified the software environment,
- confirmed that `spotread` is available,
- connected a supported instrument,
- performed the first calibration,
- measured the first spectrum,
- confirmed that the installation is working correctly.

---

## Before You Start

You need:

- MATLAB,
- Python,
- the Python package `pexpect`,
- the Python package `ptyprocess` (normally installed by `pexpect`),
- ArgyllCMS with `spotread`,
- a supported spectrophotometer connected by USB,
- the instrument's white reference for calibration.

The v0.8.2 release has been verified with:

| Component | Recommended |
|-----------|-------------|
| MATLAB | R2024b or later |
| Python | 3.10 or later |
| ArgyllCMS | 3.5 or later |
| pexpect | 4.9 or later |
| ptyprocess | 0.7 or later |

Earlier versions may work, but they are not part of the verified release configuration.

If you are unsure which folder to open in MATLAB, open the folder containing `startup.m`.

---

## Install External Dependencies

SpectraLab uses ArgyllCMS `spotread` for the current Spotread driver.

On macOS, ArgyllCMS is commonly installed using Homebrew:

```bash
brew install argyll-cms
```

Verify that `spotread` is available:

```bash
spotread -?
```

SpectraLab also uses Python and `pexpect` to communicate safely with the external `spotread` process.
`pexpect` uses `ptyprocess` for pseudo-terminal process control. SpectraLab
checks and reports both packages separately so that a future packaging or
dependency change cannot pass unnoticed.

Example:

```bash
python3 -m pip install pexpect
```

If you use a dedicated Python environment for SpectraLab, install `pexpect` in that environment.

---

## Open SpectraLab in MATLAB

Start MATLAB and change the current folder to the SpectraLab project directory.

Run:

```matlab
setup
```

`setup` is a convenient alias for `startup`.

It prepares the MATLAB path and runs a status check.

You can also run:

```matlab
startup
```

Expected output is similar to:

```text
SpectraLab 0.8.1
Measure once. Save forever.
Ready

Project root:
  /path/to/SpectraLab_v0.8.1

Status
  Project ........ OK
  Examples ....... OK
  MATLAB ......... OK
  Python ......... OK
  pexpect ........ OK
  ptyprocess ...... OK
  ArgyllCMS ...... OK
  spotread ....... OK

First measurement:
  measure_spectrum
```

If any item is reported as `MISSING`, follow the instruction shown by `startup` and see `docs/TROUBLESHOOTING.md`.

---

## Before the First Measurement

Confirm the following before running the first example:

- Instrument connected by USB
- White reference available
- `startup` reports OK
- `spotread` detected
- No other software is using the instrument

If you intend to measure transmission, you must also measure the source
without the sample as the transmission reference. This is separate from the
instrument's white-reference calibration. Reflectance instead uses the white
reference during reflective calibration and normally requires only the sample
archive. See **Why transmission requires a separate reference** in
`USER_GUIDE.md`.

---

## First Measurement

Run:

```matlab
measure_spectrum
```

The example will:

1. create a Spotread instrument,
2. open a SpectraLab session,
3. run calibration,
4. measure an LED spectrum,
5. validate and archive the spectrum,
6. generate the registered PDF and PNG outputs.

Example result:

```text
LED spectrum
  Samples:          36
  Range:            380.0 - 730.0 nm
  Peak wavelength:  450.0 nm
  Integrated power: 3170.06 arbitrary*nm
```

The numerical values depend on the measured light source.

---

## Understanding Spotread modes

The Spotread driver provides two workflows in v0.8.1:

- `interactive` preserves the verified v0.8.0 persistent-process fallback;
- `automatic` uses one bounded Spotread process for calibration and one for
  measurement.

SpectraLab guides the user through calibration and measurement one step at a time. This ensures that each operation is performed only when the instrument and operator are ready.

In automatic mode, SpectraLab shows separate placement confirmations and
waits for Spotread readiness before calibration and measurement. Interactive
mode instead uses the established Command Window prompts.

Interactive mode is the default workflow:

```matlab
sess = sess.calibrate();
spec = sess.measure("LED spectrum");
```

For interactive scripts, the explicit form is recommended:

```matlab
sess = sess.calibrate("Mode", "interactive");
spec = sess.measure("LED spectrum", "Mode", "interactive");
```

In `automatic` mode, SpectraLab asks the operator to position the instrument
and confirm each operation in a separate modal dialog. It uses `-O` for
calibration and the physically verified `-N -O` combination for measurement.
No ENTER key is forwarded to a persistent Spotread process. A spectrum is
returned only after the textual result and the saved `.sp` file agree and the
signal passes validation.

The physically verified i1Pro2 switch trigger remains available explicitly:

```matlab
inst = spectralab.drivers.createInstrument( ...
    "i1Pro2", AutomaticTrigger="instrument");
```

In switch mode, release the calibration press, reposition the instrument,
wait for the new `SPECTRALAB_READY` line, and then make a separate measurement
press.

The modal dialog is the default because it gives an unambiguous, separate
confirmation for calibration and measurement.

High-resolution i1Pro2 acquisition is explicit and requires its own
calibration:

```matlab
inst = spectralab.drivers.createInstrument( ...
    "i1Pro2", HighResolution=true);
```

This adds `-H` to both the calibration and measurement operations. Standard
resolution remains the default.

```matlab
sess = sess.calibrate("Mode", "automatic");
spec = sess.measure("LED spectrum", "Mode", "automatic");
```

---

## Basic API Workflow

The example `measure_spectrum` is the recommended first physical test.
Applications normally use the public API directly.

```matlab
inst = spectralab.drivers.createInstrument("spotread");

sess = spectralab.core.Session(inst);
sess = sess.open();

sess = sess.calibrate("Mode", "automatic");

spec = sess.measure("LED spectrum", "Mode", "automatic");

disp(spec.summary())

spectralab.plot.spectrum(spec)
```

Applications should depend on the public API, not on driver internals.

---

## Verify the Installation

Run the test suite:

```matlab
run_all_tests
```

Expected result:

```text
SpectraLab test summary
  Passed: 11
  Failed: 0

All SpectraLab tests passed.
```

Run the status function at any time:

```matlab
spectralab.status()
```

When reporting a problem, copy the complete `setup` or `spectralab.status()` output.

---

## Installation Verification

Your installation is considered verified when:

- `setup` completes successfully,
- all required environment checks are OK,
- `measure_spectrum` completes calibration,
- `measure_spectrum` completes measurement,
- `run_all_tests` passes.

At that point SpectraLab is ready for normal use.

---

## Mean or difference of two saved spectra

Select the registered analysis by running its analysis-specific workflow:

```matlab
run("/Users/christer/Desktop/SpectraLab/SpectraLab_Work/scripts/spectral_mean.m")
run("/Users/christer/Desktop/SpectraLab/SpectraLab_Work/scripts/spectral_difference.m")
```

`Spectral mean` saves a new traceable MAT archive plus PDF and PNG.
`Spectral difference A - B` creates PDF and PNG only. The report names both
source files. ANL-010 asks first for the minuend and then for the
subtrahend, so the calculation order is explicit. Default output names are
the first source basename plus `_Mean` or `_Diff`. A custom Work script may
set `pairOutputName` before running the shared workflow.

Use ANL-010 to inspect light-source stability between measurements. Use
ANL-009 when a traceable mean spectrum is needed to reduce the influence of
measurement variation in a subsequent analysis.

---

## Where to Go Next

| Goal | Document |
|------|----------|
| Understand errors | `docs/TROUBLESHOOTING.md` |
| Understand the project structure | `docs/REPOSITORY_STRUCTURE.md` |
| Understand engineering principles | `docs/DEVELOPMENT_PHILOSOPHY.md` |
| Contribute to the project | `CONTRIBUTING.md` |
| Understand responsibility | `DISCLAIMER.md` |

---

## Congratulations

Your SpectraLab installation has been verified.

You are now ready to perform reliable spectral measurements.

Measure once.
Save forever.
Verify always.
