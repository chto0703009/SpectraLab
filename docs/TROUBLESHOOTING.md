<!--
SpectraLab Documentation
Document: TROUBLESHOOTING.md
Version: v0.6.0
Status: FROZEN
-->

# Troubleshooting SpectraLab

SpectraLab errors are designed to answer one question:

> **What should I do now?**

This document helps you recover from problems quickly. It does not explain the internal implementation of SpectraLab.

---

## Before Looking for Problems

Run:

```matlab
setup
```

Read the status report carefully.

Most problems are caused by one of the following:

- SpectraLab is not on the MATLAB path.
- Python is not configured correctly.
- `pexpect` is missing from the selected Python environment.
- ArgyllCMS `spotread` is not installed or not on the system path.
- The instrument is disconnected or used by another program.

If `setup` reports a missing component, fix that first.

---

## Quick Diagnosis

Use this sequence before reading the full document.

```text
Did setup complete without missing components?
        |
        +-- no  -> environment problem
        |
        +-- yes
             |
             v
Did measure_led start?
        |
        +-- no  -> path or example problem
        |
        +-- yes
             |
             v
Did calibration complete?
        |
        +-- no  -> instrument, spotread or calibration problem
        |
        +-- yes
             |
             v
Did measurement complete?
        |
        +-- no  -> instrument or measurement problem
        |
        +-- yes -> SpectraLab is working
```

If an error includes an `SPL-xxx` code, search this document for that code.

---

## SPL Error Codes

| Code | Meaning |
|------|---------|
| SPL-001 | Project root could not be determined |
| SPL-002 | SpectraLab is not on the MATLAB path |
| SPL-003 | Python executable missing or unusable |
| SPL-004 | `pexpect` missing |
| SPL-005 | `spotread` missing |
| SPL-006 | `spotread` communication failure |
| SPL-007 | Invalid or missing spectrum output |
| SPL-008 | File format or export problem |
| SPL-009 | Plotting or graphics problem |
| SPL-010 | Unsupported MATLAB release |
| SPL-011 | Unexpected Python executable or version |
| SPL-012 | ArgyllCMS or `spotread` version problem |
| SPL-013 | Interactive bridge did not receive expected input |
| SPL-014 | Invalid measurement mode syntax |
| SPL-015 | Automatic mode requested but not supported |
| SPL-016 | Interactive workflow information |

---

## SPL-001 — Project Root Problem

### Meaning

SpectraLab could not determine the project root.

### Most common causes

- Files have been moved outside the release package.
- `startup.m` is not being run from the project directory.
- The release package is incomplete.

### What to do

1. Change MATLAB current folder to the SpectraLab project directory.
2. Confirm that `startup.m`, `setup.m`, `spectralab/`, `examples/` and `tests/` exist.
3. Run:

```matlab
setup
```

### Verify

`setup` should display the project root and report `Project ........ OK`.

---

## SPL-002 — SpectraLab Not on MATLAB Path

### Meaning

MATLAB cannot find SpectraLab functions.

### What to do

1. Change MATLAB current folder to the SpectraLab project directory.
2. Run:

```matlab
setup
```

3. Then run:

```matlab
measure_led
```

### Verify

Run:

```matlab
which spectralab.drivers.createInstrument
```

MATLAB should return a path inside the SpectraLab project.

---

## SPL-003 — Python Problem

### Meaning

SpectraLab could not use the configured Python executable.

### What to do

1. Confirm that Python is installed.
2. Confirm that MATLAB can call the intended Python executable.
3. Run:

```bash
python3 --version
```

Recommended version: Python 3.10 or later.

### Verify

Run:

```matlab
setup
```

Python should be reported as OK.

---

## SPL-004 — pexpect Missing

### Meaning

The Python package `pexpect` is missing from the Python environment used by SpectraLab.

### What to do

Install `pexpect` in the same Python environment shown by `setup`.

Example:

```bash
/path/to/python -m pip install pexpect
```

### Verify

Run:

```bash
/path/to/python -c "import pexpect; print(pexpect.__version__)"
```

Then restart MATLAB and run:

```matlab
setup
```

---

## SPL-005 — spotread Missing

### Meaning

ArgyllCMS `spotread` could not be found.

### What to do

1. Install ArgyllCMS.
2. Confirm that `spotread` is on the system path.
3. Run:

```bash
spotread -?
```

### Verify

Run:

```matlab
setup
```

`spotread` should be reported as OK.

---

## SPL-006 — spotread Communication Failure

### Meaning

`spotread` reported a communication failure with the instrument.

### Most common causes

- Instrument is not connected by USB.
- Another program is using the instrument.
- Instrument firmware or USB connection is unstable.
- The instrument needs to be unplugged and reconnected.

### What to do

1. Close other software that may use the instrument.
2. Unplug and reconnect the instrument.
3. Run in a terminal:

```bash
spotread -e
```

4. Restart MATLAB.
5. Run:

```matlab
setup
measure_led
```

### Verify

Calibration should complete without communication errors.

---

## SPL-007 — Invalid Spectrum Output

### Meaning

The instrument command completed, but SpectraLab could not parse a valid spectrum.

### What to do

1. Confirm that the instrument is supported.
2. Confirm that `spotread -e -s` produces spectral output.
3. Run the parser tests:

```matlab
run_all_tests
```

### Verify

The parser fixture tests should pass.

---

## SPL-008 — File Format or Export Problem

### Meaning

SpectraLab could not read or write the requested file format.

### What to do

1. Check the output path.
2. Check write permissions.
3. Use a supported export format.
4. See `docs/FILE_FORMAT.md`.

### Verify

Run:

```matlab
run_all_tests
```

The export tests should pass.

---

## SPL-009 — Plotting Problem

### Meaning

SpectraLab could not create the requested plot.

### What to do

1. Confirm that MATLAB graphics are available.
2. Close old figures.
3. Try plotting a known spectrum.
4. Run:

```matlab
run_all_tests
```

### Verify

`test_plot_helpers` should pass.

---

## SPL-010 — MATLAB Version Problem

### Meaning

The MATLAB release is older than the verified release configuration.

### What to do

Use MATLAB R2024b or later when possible.

Earlier releases may work, but they are not part of the verified v0.6.0 configuration.

---

## SPL-011 — Python Version or Executable Problem

### Meaning

SpectraLab detected an unexpected Python executable or version.

### What to do

1. Check the Python path shown by `setup`.
2. Confirm the version:

```bash
/path/to/python --version
```

3. Recommended version: Python 3.10 or later.

---

## SPL-012 — ArgyllCMS Version Problem

### Meaning

The installed `spotread` version could not be determined or is outside the verified configuration.

### What to do

Run:

```bash
spotread -?
```

Recommended ArgyllCMS version: 3.5 or later.

---

## SPL-013 — Interactive Bridge Input Problem

### Meaning

The interactive bridge did not receive the expected input.

### What to do

1. Stop the measurement with Ctrl-C if necessary.
2. Run:

```matlab
setup
```

3. Run `measure_led` again.
4. Press **ENTER** in the MATLAB Command Window when prompted.

---

## SPL-014 — Invalid Measurement Mode Syntax

### Meaning

The measurement or calibration mode was specified incorrectly.

### What to do

Use:

```matlab
sess = sess.calibrate("Mode", "interactive");
spec = sess.measure("LED spectrum", "Mode", "interactive");
```

Supported mode names are:

- `interactive`
- `automatic` (reserved, not supported by the current Spotread workflow)

---

## SPL-015 — Automatic Mode Not Supported

### Meaning

`automatic` mode was requested, but the current Spotread workflow requires user interaction.

### What to do

Use interactive mode:

```matlab
sess = sess.calibrate("Mode", "interactive");
spec = sess.measure("LED spectrum", "Mode", "interactive");
```

`automatic` mode is reserved for future instruments that can calibrate and measure without user input.

---

## SPL-016 — Interactive Workflow Information

### Meaning

The current Spotread driver operates in interactive mode.

During calibration and measurement, SpectraLab pauses and waits for user confirmation.

This is expected behaviour.

### What to do

When prompted:

1. Position the instrument.
2. Press **ENTER** in the MATLAB Command Window.
3. Wait for the next instruction.

This is not an error.

---

## Environment Problems

Environment problems occur before the instrument workflow begins.

Typical causes include:

- MATLAB path problems,
- missing Python,
- missing `pexpect`,
- missing `spotread`,
- unsupported versions.

Always begin with:

```matlab
setup
```

---

## Instrument Problems

Instrument problems occur when SpectraLab can start the workflow but cannot communicate with the instrument.

Typical causes include:

- disconnected USB cable,
- another program using the instrument,
- calibration failure,
- unsupported instrument,
- `spotread` communication failure.

Verify the instrument directly with:

```bash
spotread -e
```

---

## Measurement Problems

Measurement problems occur after communication works.

Examples include:

- unexpected spectral shape,
- very low signal,
- saturation,
- incorrect measurement geometry,
- wrong reference condition,
- environmental light contamination.

Before assuming a software defect, verify the complete measurement chain.

---

## Reporting a Problem

When reporting a problem, include:

- SpectraLab version,
- MATLAB version,
- Python version,
- ArgyllCMS or `spotread` version,
- operating system,
- complete `setup` output,
- SPL error code,
- command that produced the problem,
- description of the expected and observed behaviour.

Good problem reports make good engineering support possible.

---

## Engineering Responsibility

Unexpected measurements should always be verified before engineering conclusions are drawn.

Verification of software does not replace verification of measurements.

Verification of measurements does not replace engineering judgement.

See `DISCLAIMER.md` for the full engineering and scientific responsibility statement.

---

## Further Reading

- `docs/GETTING_STARTED.md`
- `DISCLAIMER.md`
- `CONTRIBUTING.md`

Measure once.
Save forever.
Verify always.
