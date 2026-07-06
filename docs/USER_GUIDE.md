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
