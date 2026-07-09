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

  ID       Title                          Status
  -------- ------------------------------ ----------
  ED-001   SpectraLab Archive Structure   Approved
  ED-002   Scientific Provenance          Approved
