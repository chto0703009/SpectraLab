# RP-020 — Canonical Analysis Registry

## Purpose

The analysis registry is the only authoritative description of analyses
that can be rendered as SpectraLab reports.

Every reportable analysis is represented by one internal registry entry
containing:

- one complete `AnalysisDefinition`;
- ordered archive `InputRoles`;
- one `AnalysisRunner`;
- a `FigureRenderer` exactly when `HasFigure=true`.

`AnalysisDefinition` owns the public identity and presentation contract:
`AnalysisId`, name, description, method, standard, definition version,
result fields, and optional figure definition.

## Public API

```matlab
analyses = spectralab.report.listAnalyses();
description = spectralab.report.describeAnalysis("ANL-002");
info = spectralab.report.generate( ...
    [referenceFile, sampleFile], "ANL-002", outputFolder);
```

The list and description APIs return data only. Internal runners and figure
renderers are not exposed.

`spectralab.report.generate` accepts an `AnalysisId`, not an ad-hoc report
specification. Unknown identifiers fail before archive loading or output
creation.

## Registry invariants

Registry construction rejects:

- duplicate or empty analysis identifiers;
- incomplete definitions or result-field declarations;
- duplicate result fields;
- invalid or duplicate input roles;
- missing runners;
- disagreement between `HasFigure`, `FigureDefinition`, and
  `FigureRenderer`;
- invalid figure geometry or captions.

After an analysis runs, report generation verifies that its scalar result
structure contains every result field declared by the registered
definition.

## Registered analyses

| AnalysisId | Analysis | Inputs | Figure |
|---|---|---|---|
| `ANL-SPECTRUM` | Measured Spectrum | Measurement | Yes |
| `ANL-CRI` | Color Rendering Index | Measurement | Yes |
| `ANL-001` | Transmission | Reference, Sample | Yes |
| `ANL-002` | Optical Density | Reference, Sample | Yes |
| `ANL-004` | White Density | Reference, Sample | No |
| `ANL-005` | Status A RGB + ISO visual white density | Reference, Sample | No |
| `ANL-008` | Status M RGB + ISO visual white density | Reference, Sample | No |
| `ANL-007` | ISO Visual Density | Reference, Sample | No |
| `ANL-009` | Spectral Mean | Source A, Source B | Yes |
| `ANL-010` | Spectral Difference | Minuend (A), Subtrahend (B) | Yes |

ANL-009 may additionally save a traceable derived MAT archive. ANL-010 is
reportable as PDF and PNG but intentionally creates no MAT archive. See
ED-018 for the scientific and provenance contract.

Adding a reportable analysis requires adding one canonical registry entry
and its tests. No second metadata definition is permitted in examples or
public orchestration code.
