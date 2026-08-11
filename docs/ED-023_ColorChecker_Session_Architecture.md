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

The chart has user-declared rows and columns, unless an
architecture-controlled target definition is selected. A controlled target
definition identifies a manufacturer's nominal chart contract by a canonical
ID and name and locks its model, geometry, patch count, orientation and
nominal-specification identity. The first controlled definition is
`xrite-colorchecker-digital-sg-140`, named
`X-Rite ColorChecker Digital SG`.

The controlled model identity is separate from the free session name and from
the optional ID, serial number, manufacture date or lot marking of one physical
chart instance. SpectraLab embeds the complete controlled definition and its
SHA-256 hash in the session JSON. The manufacturer's nominal values define what
the model is intended to contain; the immutable measured R(lambda) archives
characterise the actual physical chart used by the operator.

Columns are lettered from
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

## Controlled patch remeasurement

An erroneous completed patch is never edited or deleted. A controlled
remeasurement selects one or more patch coordinates and creates a separate
amendment manifest. Every selected patch is then measured into a new immutable
MAT archive. The amendment records the original and replacement archive UUIDs
and SHA-256 content hashes, the reason, operator, instrument and resolution.

The amendment is patch-granular: each replacement has its own state and
identity. Several patches may nevertheless be handled in one correction
session so that one physical calibration and one documented reason can cover
the operator's correction round.

Finalization first verifies that the original session manifest has not changed
and that all replacement archives match their recorded identities. It then
creates `colorchecker_session_amended_NNN.json` with a new session UUID. The
original session JSON and every original MAT archive remain unchanged. Derived
colorimetry is recalculated into a new suffixed JSON from the amended session.

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
