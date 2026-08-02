# ED-018 — Derived spectral mean and diagnostic difference

**Status:** Accepted for SpectraLab v0.8.1
**Analyses:** ANL-009 and ANL-010

## Decision

ANL-009 calculates the pointwise arithmetic mean of two validated
SpectraLab MAT archives:

`M(lambda) = (A(lambda) + B(lambda)) / 2`

The mean is a reusable derived spectrum and may therefore be saved as a new
SpectraLab MAT archive. This is a deliberate exception to the normal rule
that an analysis reports a result without creating measurement data.
Its intended scientific use is to reduce the influence of measurement-to-
measurement variation before the derived spectrum is used in a subsequent
analysis. It does not conceal the sources: both measurements remain fully
identified in the derived archive and report.

ANL-010 calculates the signed diagnostic difference:

`D(lambda) = A(lambda) - B(lambda)`

The difference may be shown in a PNG figure and documented in a PDF report,
but it must not create a MAT archive.
Its intended scientific use is diagnostic comparison, in particular to
investigate the stability of a light source between two measurements. The
signed convention A minus B makes the direction and magnitude of change
explicit across wavelength.

## Scientific provenance

An ANL-009 derived archive records, for both source archives:

- the selected MAT filename;
- measurement name;
- archive UUID;
- content hash;
- role in the calculation.

It also records the analysis identifier, expression, wavelength alignment,
interpolation method, refinement factor, and effective wavelength range.
The derivation is part of the derived archive's deterministic content hash.

ANL-010 reports both selected MAT filenames and their ordered roles. The
first file is always the minuend A and the second file the subtrahend B.
The in-memory analysis result also retains both UUIDs and content hashes.

## Wavelength and unit rules

Exact wavelength grids are required by default. If the grids differ, the
user must explicitly approve interpolation onto their common wavelength
range. Both archives must use the same measurement unit.

## User workflow

Select the desired registered analysis by running its workflow:

```matlab
run("/Users/christer/Desktop/SpectraLab/SpectraLab_Work/scripts/spectral_mean.m")
run("/Users/christer/Desktop/SpectraLab/SpectraLab_Work/scripts/spectral_difference.m")
```

ANL-009 requests Source A and Source B. ANL-010 requests Minuend (A) and
Subtrahend (B). There is no separate mean/difference choice inside either
analysis. The GUI selects alignment when necessary.
By default, output names use the first source basename plus `_Mean` or
`_Diff`. A custom script under `SpectraLab_Work/scripts` may set the optional
workspace variable `pairOutputName` before running the shared workflow.
Existing files are never overwritten.
