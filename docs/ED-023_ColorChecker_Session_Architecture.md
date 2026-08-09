# ED-023 — ColorChecker session architecture

## Decision

A ColorChecker acquisition is represented by a JSON session manifest and
one immutable standard SpectraLab archive per patch. A session never
duplicates spectral values held by an archive.

The Work script `measure_colorchecker_reflectance` guides the operator through
instrument selection, calibration, patch placement and session resume. It uses
the public `spectralab.colorchecker` session functions and the standard
SpectraLab instrument driver. The earlier separate Spotread series acquisition
path is not part of this architecture.

## Geometry

The chart has user-declared rows and columns. Columns are lettered from
left to right (`A`, `B`, ..., `Z`, `AA`, ...); rows are numbered from top
to bottom. `A1` is therefore the upper-left patch. The required acquisition
order is row-major: `A1`, `B1`, ... followed by `A2`, `B2`, ....
The chart definition can also record the chart ID, manufacturer serial
number and manufacturing date. Manufacturer date markings in `YYYY-MM` or
`YYYY-MM-DD` format are both accepted; a lot marking is also preserved as
entered.

## Persistence

The user-selected project root contains `<ColorChecker-name_timestamp>/`.
That named session folder contains `data/` for the acquisition manifest,
configuration and raw Spotread transcripts, while its `archive/` subfolder
contains all patch archives.
Each patch archive is a normal `SLAB-MAT` archive with
the complete reflectance factor spectrum. The manifest records only the patch
coordinate, archive filename, archive UUID and scientific content hash.

Later presentation outputs use `report/` for PDF and `plot/` for PNG below
the same named ColorChecker session folder. These folders are created only
when the corresponding output is explicitly generated; acquisition does not
create empty presentation folders.

The ColorChecker session report is documentation-only. It records target
definition, session timing and state, instrument/resolution provenance and
patch archive identity. It contains no plot and no derived XYZ or Lab data.

Patch archives are never overwritten. The manifest is mutable controlled
workflow state and is written atomically with a revision number.

## Calibration

The session records an initial calibration and every subsequent calibration,
including instrument metadata, timestamp and the policy-derived due time.
SpectraLab owns the elapsed-time policy. Any calibration error reported by
the instrument is a mandatory recalibration event regardless of the timer.

## Reporting

Acquisition writes neither PDF nor PNG. Individual patch reports and
session-level reports are explicit later operations.
CSV and aggregate MAT files are likewise explicit secondary exports. The
standard acquisition output remains the raw manifest and immutable patch
archives.
