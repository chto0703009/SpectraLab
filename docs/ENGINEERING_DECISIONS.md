# SpectraLab Engineering Decisions

**Status:** Living Document\
**Purpose:** Record approved engineering decisions that guide
implementation.\
**Related:** `ARCHITECTURE_v0_5.md`

------------------------------------------------------------------------

# ED-001 --- SpectraLab Archive Structure

**Status:** Approved

Every SpectraLab archive shall contain exactly one top-level MATLAB
structure:

``` matlab
archive
```

Initial layout:

``` matlab
archive.Version
archive.Measurement
archive.Metadata
archive.Instrument
archive.Quality
archive.History
```

The archive is the scientific object. MAT is the storage container.

------------------------------------------------------------------------

# ED-002 --- Scientific Provenance

**Status:** Approved

The original measurement records the acquisition event.

Subsequent analyses are appended to the processing history.

The original measurement is never modified.

Measurement fields:

``` matlab
archive.Measurement.Operator
archive.Measurement.Timestamp
archive.Measurement.Instrument
```

History fields:

``` matlab
archive.History(n).Timestamp
archive.History(n).Operator
archive.History(n).Action
archive.History(n).Comment
archive.History(n).SoftwareVersion
```

Rationale:

-   Full scientific provenance
-   Multiple analysts supported
-   Reproducibility
-   Original measurement preserved

------------------------------------------------------------------------

# Decision Lifecycle

    Draft
      ↓
    Review
      ↓
    Approved
      ↓
    Implemented
      ↓
    Frozen

The Architecture document defines principles.

Engineering Decisions document concrete implementation choices.

------------------------------------------------------------------------

## Approved Decisions

| ID | Title | Status |
|---|---|---|
| ED-001 | SpectraLab Archive Structure | Approved |
| ED-002 | Scientific Provenance | Approved |
| ED-003 | Deterministic Scientific Identity | Approved |
| ED-004 | Interactive Instrument Handshake | Approved |
| ED-022 | Colorimetry and Measurement Export Architecture | Approved for v0.8.3-dev implementation |

------------------------------------------------------------------------

# ED-003 --- Deterministic Scientific Identity

**Status:** Approved

A SpectraLab archive shall contain two independent identifiers:

``` matlab
archive.Identity.UUID
archive.Identity.ContentHash
```

`UUID` identifies the archive instance.

`ContentHash` identifies the deterministic scientific measurement
content.

The content hash shall be calculated using SHA-256 from a canonical
scientific payload. It shall not depend on random number generators,
archive creation timestamps, software version strings, filenames or
editable descriptive metadata.

Rationale:

-   Scientific identity must be stable across repeated archive creation.
-   Random number generator changes must not affect scientific identity.
-   Identical measurements shall produce identical content hashes.
-   Archive instances shall still be uniquely distinguishable.

Consequences:

-   UUID may differ between archives of the same measurement.
-   ContentHash shall remain identical for identical scientific content.
-   Metadata may evolve without changing the scientific identity.

------------------------------------------------------------------------

# ED-004 --- Interactive Instrument Handshake

**Status:** Approved

Interactive command-line instruments shall be controlled through a bridge
layer rather than directly from high-level MATLAB session code.

For `spotread`, calibration and measurement require explicit operator
confirmation. SpectraLab shall preserve this interaction model.

The Python bridge is responsible for external process control and ENTER
handshakes.

Rationale:

-   Instrument positioning is a physical action and must remain
    user-controlled.
-   MATLAB session code should remain instrument-agnostic.
-   Command-line interaction is easier to test and diagnose in the bridge
    layer.
-   The same pattern can support future interactive instruments.

Consequences:

-   SpectraLab waits for explicit user confirmation during interactive
    acquisition.
-   External process interaction is isolated from scientific archive and
    session logic.
-   Failures in ENTER handling can be reported as bridge diagnostics.
