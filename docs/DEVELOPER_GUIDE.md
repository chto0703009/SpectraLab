# Developer Guide

## Architecture

SpectraLab is divided into:

- `core` — instrument-independent measurement objects
- `drivers` — hardware and backend adapters
- `io` — file formats and export
- `plot` — visualization helpers
- `tests` — regression and unit tests

## Core rule

The Core API must not know about any specific instrument.

## Driver rule

A driver must implement the abstract `spectralab.core.Instrument` interface:

```matlab
getInfo
open
close
calibrate
measure
```

## File format rule

`.slab.json` is the long-term archival format. MATLAB `.mat` is useful but not archival.
