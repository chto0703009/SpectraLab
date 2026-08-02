# RP-021 - Spotread One-Shot Measurement Workflow

**Target release:** SpectraLab v0.8.1  
**Development branch:** `v0.8.1-dev`  
**Status:** Approved specification  
**Primary instrument:** X-Rite i1Pro2  
**Backend:** ArgyllCMS `spotread` 3.5.0 or later

## 1. Purpose

SpectraLab shall replace the mandatory ENTER-controlled Spotread workflow
with a deterministic one-shot workflow based on the ArgyllCMS `-O` option.

The workflow shall allow a measurement only after Spotread has established
that the instrument is calibrated. A SpectraLab archive shall be created
only from a complete, successfully parsed and validated measurement.

## 2. Authoritative workflow

```text
Measurement requested
        |
        v
Spotread calibration state evaluated
        |
        v
Calibration required?
    +---+---+
    |       |
   yes      no
    |       |
    v       |
Request calibration placement
    |
Run and verify calibration
    |
Request measurement placement
    |       |
    +---+---+
        |
        v
Run one-shot measurement
        |
        v
Parse and validate spectrum
        |
        v
Create and save archive
```

## 3. Calibration authority

ArgyllCMS `spotread` and the physical instrument are authoritative for
calibration status.

SpectraLab shall not infer valid calibration only from an internal timer.
It may record calibration timestamps and provenance, but these records
shall not override a calibration request reported by Spotread.

The implementation shall distinguish between:

- calibration required;
- calibration completed successfully;
- calibration failed or was cancelled;
- measurement completed successfully;
- measurement failed or produced no spectrum.

Calibration output shall never be interpreted as measurement data.

## 4. One-shot execution with `-O`

The first implementation stage shall use Spotread's documented option:

```text
-O [fname.sp]  Do one calibration or measurement and exit
```

Each external Spotread process shall perform one bounded operation and
then exit. SpectraLab shall not depend on a persistent process waiting for
ENTER between calibration and measurement.

The exact command construction belongs inside the Spotread driver layer.
User scripts shall express measurement intent through the public
SpectraLab API and shall not construct Spotread commands directly.

## 5. User interaction

Non-interactive process control does not remove necessary physical user
actions.

When calibration is required, SpectraLab shall clearly request that the
instrument be placed on its calibration reference. Measurement shall not
start until calibration success has been established.

The placement instruction shall remind the operator to verify that the
calibration-plate serial number matches the instrument. This is operator
guidance only and does not add an unverified confirmation field to the saved
archive.

During a measurement series, a `CALIBRATION_REQUIRED` response triggers one
bounded recovery cycle: the incomplete attempt is discarded, the operator is
guided through a new white-reference calibration, and the requested
measurement is attempted once more. A second calibration request is reported
as an error; SpectraLab never enters an automatic retry loop.

Non-recoverable Spotread failures, including a missing USB instrument,
communication failure, timeout, failed calibration or backend process error,
abort `measureMany` immediately. The failed measurement is not added to the
collection and no later series item is attempted. A sample-specific rejected
dark signal may still be skipped without classifying the instrument itself as
unusable.

Before measurement, SpectraLab shall clearly request placement on the
sample or source. The program shall then run one bounded measurement.

No ENTER forwarding to a persistent Spotread process shall be required.

## 6. Archive rule

An archive may be created only when all of the following are true:

1. Spotread reports successful command completion.
2. Spectral output is present.
3. The spectral parser accepts the output.
4. Wavelength and power data pass SpectraLab validation.
5. Required instrument, calibration and command provenance is available.

Calibration-only, incomplete, cancelled or failed operations shall not
create measurement archives.

## 7. Provenance

The saved measurement shall record at least:

- physical instrument identity;
- Spotread executable and detected version;
- effective Spotread options;
- one-shot execution mode;
- calibration result associated with the measurement;
- whether high-resolution mode was enabled;
- parser identity and spectral sampling information;
- SpectraLab software version.

## 8. High-resolution stage with `-H`

After the `-O` workflow has passed physical-instrument verification,
SpectraLab shall evaluate Spotread's documented option:

```text
-H  Start in high resolution spectrum mode (if available)
```

High-resolution mode shall initially be explicit and optional. It shall
not become the default until the following have been verified:

- i1Pro2 support and failure behaviour;
- wavelength range and sample spacing;
- parser compatibility;
- archive round-trip integrity;
- compatibility with all registered analyses;
- plot and report behaviour;
- repeatability compared with standard-resolution measurements.

## 9. Compatibility

The released v0.8.0 production installation and its archives shall remain
unchanged.

During v0.8.1 development, the verified interactive workflow shall remain
available as a fallback until the one-shot workflow satisfies every
acceptance criterion.

Existing released archives shall remain readable.

## 10. Acceptance criteria

RP-021 is complete only when:

- `-O` command construction is deterministic and tested;
- calibration-required output is recognized reliably;
- successful calibration is distinguished from measurement;
- measurement cannot start before required calibration succeeds;
- a complete spectrum can be measured without ENTER forwarding;
- failed or calibration-only operations create no archive;
- successful spectra are validated and archived with complete provenance;
- the physical instrument serial number is captured from Spotread when
  available and propagated to the archive quality record;
- existing regression tests continue to pass;
- new one-shot state and error paths have automated tests;
- the workflow has been verified with a physical X-Rite i1Pro2;
- standard-resolution operation is approved before `-H` evaluation begins;
- optional `-H` operation passes its separate compatibility matrix.

Instrument identity is obtained from Spotread verbose output during the
ordinary bounded operation. SpectraLab accepts ArgyllCMS `Serial Number:`
output and the i1Pro white-reference `S/N` prompt. Failure to obtain an
identity does not invalidate an otherwise sound spectrum; archive validation
retains the explicit missing-serial-number warning for operator review.

## 11. Implementation order

1. Capture representative Spotread 3.5.0 `-O` outputs.
2. Define the calibration and measurement outcome parser.
3. Implement a bounded one-shot command runner.
4. Integrate calibration state into `SpotreadInstrument`.
5. Enable the public automatic measurement path for the verified driver.
6. Verify standard-resolution operation with a physical i1Pro2.
7. Add optional `-H` support and repeat the scientific compatibility
   checks.

## 12. Decision

This document is the approved functional specification for the principal
Spotread work in SpectraLab v0.8.1.

## 13. Implementation status

Stages 1-5 are implemented in the development branch without removing the
released interactive fallback:

- `tools/capture_spotread_one_shot.m` records isolated physical-instrument
  runs, raw output and process metadata for operator review;
- `spectralab.drivers.spotread.OutcomeParser` defines the initial strict
  outcome vocabulary, covered by explicitly labelled synthetic fixtures;
- `spectralab.drivers.spotread.OneShotCommandRunner` runs argument-list based
  commands in a unique temporary directory with a hard timeout;
- `tools/spotread_one_shot.py` implements bounded process control without a
  persistent ENTER-controlled process.

Real ArgyllCMS 3.5.0/i1Pro2 calibration, dark-signal and valid-measurement
captures have been reviewed and promoted to regression fixtures.

The first physical captures showed that a fresh `-O` process reports that
calibration is needed and then completes one calibration operation. A new
process repeats that calibration path. Consequently, the separate one-shot
measurement capture uses `-N -O` only after a verified successful calibration.
This observed i1Pro2 behaviour shall be reverified before stage 4 adopts the
combination in the production workflow.

The first `-N -O` physical capture completed and wrote a 36-band `.sp` file,
but its near-zero predominantly negative signal demonstrated that successful
process completion is not sufficient for archiving. Capture metadata now
records signal statistics and a separate candidate-validity flag. The final
stage-4 validator shall reject such output before archive creation.

A subsequent correctly positioned `-e -s -N -O` capture succeeded in 4.2
seconds, produced 36 positive samples over 380-730 nm and wrote a matching
`.sp` file. Its reviewed output is retained as the first physical i1Pro2
measurement fixture for the one-shot workflow.

`SpotreadInstrument` now exposes the bounded workflow through public
`automatic` mode. It accepts calibration only after
`CALIBRATION_SUCCEEDED`, compares measurement console data with the saved
`.sp` file, rejects non-positive integrated signals, and creates a `Spectrum`
only after all checks pass. Full public-workflow verification with the
physical i1Pro2 was the stage-6 gate and is recorded below.

Desktop placement confirmation uses a modal Continue/Cancel dialog so that
pasted multi-line MATLAB commands cannot leave `input()` waiting in the
Command Window. Headless MATLAB retains an ENTER-based fallback.

## 14. Physical standard-resolution verification

- **Status:** Passed 31 July 2026
- **Instrument:** X-Rite i1Pro2
- **Backend:** ArgyllCMS 3.5.0
- **MATLAB:** R2025b

The public workflow was run through `Session` and `SpotreadInstrument`:

```matlab
sess = sess.calibrate("Mode", "automatic");
spec = sess.measure("RP-021 physical test", "Mode", "automatic");
```

The operator received separate placement dialogs for calibration and
measurement. Calibration completed, the subsequent bounded measurement
completed without ENTER forwarding, and SpectraLab returned:

```text
Samples:          36
Range:            380.0 - 730.0 nm
Peak wavelength:  450.0 nm
Integrated power: 44604.9 arbitrary*nm
```

This passes the stage-6 standard-resolution physical-instrument gate. Archive
integration remains required before the complete RP-021 workflow can be
approved. Optional `-H` evaluation remains a separate later stage.

## 15. Instrument-switch trigger evaluation

An experimental bounded runner was verified with its stdin pipe kept open.
With the i1Pro2 positioned on its white reference, pressing the physical
instrument switch triggered `-e -s -O`, returned status 0 and reported
`Calibration complete` in 8.7 seconds. No spectrum file was created during
the calibration-only operation. Instrument-switch measurement was then
verified before changing the default trigger.

The subsequent physical-switch measurement using `-e -s -N -O` also passed:
status 0, no timeout, 36 positive samples over 380-730 nm, positive integrated
power and a matching `.sp` file. The physical i1Pro2 switch remains available
through explicit `AutomaticTrigger="instrument"` selection. Modal confirmation
is the default because it unambiguously separates calibration and measurement
actions.

The first immediate back-to-back public calibration/measurement attempt
showed that an operator can press the switch before the newly launched
measurement process has reached Spotread's reading prompt. The runner now
detects the actual Spotread calibration or measurement prompt through its PTY
and emits `SPECTRALAB_READY` before asking for the physical switch. Early
button presses are therefore no longer presented as valid timing.

The first back-to-back test after prompt synchronization showed that the
release event from the calibration switch could still be observed by an
immediately launched measurement process. A two-second switch-settle guard is
therefore applied before arming measurement. The operator is instructed to
release the switch and reposition the instrument during this interval; only a
new press after the subsequent `SPECTRALAB_READY` is valid.

## 16. High-resolution physical evaluation

The capture tool exposes `HighResolution=true`, which adds `-H` explicitly
without changing the standard-resolution default. The first high-resolution
capture shall be reviewed for wavelength range, sample count and spacing,
console/`.sp` agreement, signal validity and parser compatibility before the
option is exposed by `SpotreadInstrument` or the measurement GUI.

The first `-H -N -O` attempt after standard-resolution calibration caused
Spotread to request a new calibration. Because the instrument was already on
the light source, calibration correctly failed with `Measurement misread`
and `Dark reading is not valid (too light)`. No spectrum file was created.
This demonstrates that high-resolution mode has an independent calibration
requirement. Evaluation must therefore use `-H -O` calibration on the white
reference before `-H -N -O` measurement.

The corrected sequence passed physically. High-resolution calibration took
13.3 seconds. Measurement took 4.2 seconds and returned 109 positive samples
over 370-730 nm (approximately 3.33 nm spacing), positive integrated signal
and matching console/`.sp` data. `SpotreadInstrument` therefore exposes
explicit `HighResolution=true`, and the work measurement GUI offers Standard
or High resolution before calibration. Standard remains the default.
