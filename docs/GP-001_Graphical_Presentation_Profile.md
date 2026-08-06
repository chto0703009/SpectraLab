# GP-001 --- SpectraLab Graphical Presentation Profile

**Document ID:** GP-001  
**Version:** 1.0  
**Status:** Approved  
**Applies from:** SpectraLab v0.8.2

## Purpose

This profile defines the required visual presentation of SpectraLab
plots. A user shall find the same kind of information in the same place,
regardless of the analysis or output format.

## Required Plot Layout

Every public plot and every report figure shall use two distinct areas:

1. **Plot area** -- reserved exclusively for axes, data curves, grid,
   labels and spectral colour bar.
2. **Right information area** -- reserved for the legend and any
   measurement or analysis information.

The plot area shall not contain a legend, summary box, annotation box or
other explanatory text that can obscure a curve.

## Legend

- A legend shall be placed to the right of the plot area.
- A legend shall not cover data, axes or the spectral colour bar.
- The same legend shall be present in the interactive figure, exported
  PNG and report PDF.

## Measurement and Analysis Information

- Context such as archive identity, measurement metadata, CCT, CRI and
  stability metrics shall be placed in the right information area.
- Text shall wrap or be split into short lines; it shall never be clipped.
- The result table remains the authoritative detailed record in a PDF;
  the plot-side information is a concise visual summary.

## Output Consistency

Interactive figures, Work PNG files and report PNG/PDF figures shall
apply this profile consistently. A visual improvement in one output path
shall be implemented in the other output paths at the same time.

## Verification

New plot types shall be reviewed against this profile. Automated tests
shall verify that registered report legends use the right-side placement
and that exported figures preserve a legend.
