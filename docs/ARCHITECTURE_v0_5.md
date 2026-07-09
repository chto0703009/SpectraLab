# SpectraLab v0.5.0 Architecture

**Status:** Draft\
**Version:** 0.1\
**Branch:** `v0.5-archive-workflow`

**Project Owner:** Professor Christer Törnkvist\
**System Architect:** OpenAI ChatGPT

------------------------------------------------------------------------

# 1. Purpose

SpectraLab v0.5.0 defines the transition from an interactive measurement
application to a reusable scientific measurement platform.

The primary objective is to preserve spectral measurements so they can
be archived, reloaded, reprocessed and exported without requiring a new
measurement.

------------------------------------------------------------------------

# 2. Vision

> A measurement should never lose value because software evolves.

Original measurements represent the primary scientific record.

Processing creates derived information.

Archives preserve scientific information.

Exports communicate scientific information.

------------------------------------------------------------------------

# 3. Design Philosophy

## Measure once. Save forever.

Every measurement is considered valuable and worthy of long-term
preservation.

## Preserve information. Delay interpretation.

Interpretation should occur only when required.

Derived quantities shall be calculated from archived measurements rather
than replacing them.

## Interactive acquisition. Scriptable science.

Instrument operation may require user interaction.

Scientific analysis shall not.

## Original measurements are immutable.

Measured spectra shall never be overwritten.

## Derived information shall never overwrite measured information.

Transmission, density, filtered density, colour coordinates and quality
metrics shall always be represented as derived objects.

------------------------------------------------------------------------

# 4. Scientific Model

``` text
Instrument
      │
      ▼
Measurement
      │
      ▼
Archive
      │
      ▼
Reload
      │
      ▼
Processing
      │
      ▼
Export
```

Each layer has one responsibility.

------------------------------------------------------------------------

# 5. Scope of Version 0.5.0

Version 0.5.0 shall implement:

-   MAT archive
-   saveMeasurement()
-   loadMeasurement()
-   saveCollection()
-   loadCollection()
-   CSV export
-   XLSX export
-   metadata preservation
-   quality information
-   preparation for processing history

Version 0.5.0 intentionally does **not** implement:

-   transmission
-   density
-   filters
-   colour transforms
-   ICC workflows

------------------------------------------------------------------------

# 6. Scientific Assumption SA-001

Spotread spectra are treated as calibrated spectral measurements rather
than raw detector counts.

Reference-based calculations may therefore be performed on archived
spectra provided that calibration, geometry and signal quality remain
valid.

------------------------------------------------------------------------

# 7. Architectural Decisions

## AD-001 --- Scientific Measurements Have Precedence

Scientific meaning has priority over software implementation
convenience.

## AD-002 --- Archive Independence

Archives shall not depend directly on MATLAB class implementations.
Stable structures are preferred for long-term preservation.

## AD-003 --- Processing Does Not Belong in Export

Processing creates scientific meaning.

Export preserves or communicates it.

------------------------------------------------------------------------

# 8. Future Compatibility

The archive layer established in v0.5.0 shall support future processing
without invalidating previously archived measurements.

Future releases will introduce:

-   v0.6.0 --- Reference-based processing (transmission and density)
-   v0.7+ --- Filters, filtered density and colour transformations

------------------------------------------------------------------------

# Closing Statement

> **Measure once. Save forever. Reanalyse when needed.**
