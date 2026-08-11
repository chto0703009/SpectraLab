# User Guide

## Installation

Unzip the repository and open MATLAB in the repository root.

```matlab
startup
```

## Mock measurement

Use the mock instrument first. It verifies that the MATLAB installation and SpectraLab path are working.

```matlab
inst = spectralab.drivers.createInstrument("mock");
sess = spectralab.core.Session(inst);
sess = sess.open();
sess = sess.calibrate("Mode", "interactive");
spec = sess.measure("Mock LED");
spec.plot();
```

## Saving

```matlab
spectralab.io.saveSpectrum(spec, "mock_led.slab.json");
```

The `.slab.json` format is the archival format.

## Loading

```matlab
spec2 = spectralab.io.readSpectrum("mock_led.slab.json");
```

## Export

```matlab
spectralab.io.exportCsv(spec, "mock_led.csv");
spectralab.io.exportTxt(spec, "mock_led.txt");
```

## Real instrument

Use `spotread` after the mock workflow works.

```matlab
inst = spectralab.drivers.createInstrument("spotread");
```

## Controlled ColorChecker target definitions

For an X-Rite ColorChecker Digital SG acquisition, the Work script selects the
architecture-controlled `xrite-colorchecker-digital-sg-140` definition. The
operator does not enter its geometry: the canonical model name fixes the
10-row, 14-column and 140-patch contract associated with X-Rite's nominal
target specification. Session name and optional markings from the physical
chart remain separate traceability information. Other chart models can be
introduced later as additional versioned definitions without changing
existing sessions.

## Why transmission requires a separate reference

Transmission and reflectance are both relative spectral quantities, but
SpectraLab obtains their reference information at different stages of the
measurement.

| Measurement | Archived inputs | Reference operation |
|---|---:|---|
| Transmission | Reference and sample | Measure the source without the sample, then measure the same source through the sample. |
| Reflectance | Reflectance sample | Calibrate the reflectance instrument on its supplied white reference, then measure the sample. |

### Transmission

An emissive measurement records the detected spectrum; it is not already a
transmission value. SpectraLab therefore needs:

```text
reference(lambda) = source measured without the sample
sample(lambda)    = source measured through the sample

T(lambda) = sample(lambda) / reference(lambda)
```

The ratio removes the measured source spectrum and the common response of the
measurement chain. It leaves the fraction transmitted by the sample, provided
that the source, instrument position, optical geometry, exposure and other
conditions remain unchanged. A new reference is required when those conditions
change. Instrument calibration alone cannot replace this measurement because
calibration does not record the spectrum and level incident on the sample.

### Reflectance

In reflective mode, the instrument is calibrated against its supplied white
reflectance reference. Spotread then reports the sample relative to that
calibrated reference as the spectral reflectance factor `R(lambda)`, stored by
SpectraLab in percent. Consequently, a normal reflectance archive does not need
a second user-measured white-reference archive.

The white tile is nevertheless a real physical reference and remains essential:
it belongs to the calibration step rather than to a later two-archive ratio.
The instrument and its matching white reference must be used as instructed,
and SpectraLab records the calibration provenance.

These workflows must not be interchanged. A transmission source reference is
not a substitute for reflective white calibration, and reflective white
calibration is not a substitute for measuring the incident transmission
source. Technical details are recorded in
`ED-011_Filtered_Transmission_Density.md` and
`REFLECTANCE_COLORIMETRY.md`.
