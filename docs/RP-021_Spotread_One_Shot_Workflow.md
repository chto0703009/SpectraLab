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
- existing regression tests continue to pass;
- new one-shot state and error paths have automated tests;
- the workflow has been verified with a physical X-Rite i1Pro2;
- standard-resolution operation is approved before `-H` evaluation begins;
- optional `-H` operation passes its separate compatibility matrix.

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
