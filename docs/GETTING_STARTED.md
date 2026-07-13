<!--
SpectraLab Documentation
Document: GETTING_STARTED.md
Version: v0.6.0
Status: FROZEN
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
- ArgyllCMS with `spotread`,
- a supported spectrophotometer connected by USB,
- the instrument's white reference for calibration.

The v0.6.0 release has been verified with:

| Component | Recommended |
|-----------|-------------|
| MATLAB | R2024b or later |
| Python | 3.10 or later |
| ArgyllCMS | 3.5 or later |
| pexpect | 4.9 or later |

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
SpectraLab 0.6.0
Measure once. Save forever.
Ready

Project root:
  /path/to/SpectraLab_v0_4_0

Status
  Project ........ OK
  Examples ....... OK
  MATLAB ......... OK
  Python ......... OK
  pexpect ........ OK
  spotread ....... OK

First measurement:
  measure_led
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

---

## First Measurement

Run:

```matlab
measure_led
```

The example will:

1. create a Spotread instrument,
2. open a SpectraLab session,
3. run calibration,
4. measure an LED spectrum,
5. print a spectrum summary,
6. plot the spectrum.

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

## Understanding Interactive Mode

The current Spotread driver operates in **interactive mode**.

SpectraLab guides the user through calibration and measurement one step at a time. This ensures that each operation is performed only when the instrument and operator are ready.

During calibration and measurement SpectraLab will ask you to:

1. place the instrument,
2. press **ENTER** in the MATLAB Command Window,
3. wait for the operation to complete.

This behaviour is expected.

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

`automatic` mode is reserved for future instruments that can calibrate and measure without user input.

---

## Basic API Workflow

The example `measure_led` is convenient for the first test. Applications normally use the public API directly.

```matlab
inst = spectralab.drivers.createInstrument("spotread");

sess = spectralab.core.Session(inst);
sess = sess.open();

sess = sess.calibrate("Mode", "interactive");

spec = sess.measure("LED spectrum", "Mode", "interactive");

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
- `measure_led` completes calibration,
- `measure_led` completes measurement,
- `run_all_tests` passes.

At that point SpectraLab is ready for normal use.

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
