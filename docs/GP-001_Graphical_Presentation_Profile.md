# GP-001 --- SpectraLab Graphical Presentation Profile

**Document ID:** GP-001  
**Version:** 1.2
**Status:** Approved  
**Applies from:** SpectraLab v0.8.2
**Architectural decision:** `ED-024_Plot_Presentation_Architecture.md`

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

The standard interactive and PNG composition has a 2:1 aspect ratio and a
nominal size of 1400 x 700 pixels. A PNG shall preserve the approved screen
composition; it shall not use the PDF report figure's aspect ratio.

## Axes

- Wavelength axes use nanometres.
- Every percent y-axis defaults to 0–100 %.
- Transmission ratios are multiplied by 100 for plotting and labelled
  `Transmission (%)`; the stored and calculated transmission remains
  dimensionless.
- Reflectance is labelled `Relative reflectance (%)` and defaults to 0–100 %.
- Emission uses its recorded power quantity and data-dependent range.

## Legend

- A legend shall be placed to the right of the plot area.
- A legend shall not cover data, axes or the spectral colour bar.
- The same legend shall be present in the interactive figure, exported
  PNG and report PDF.
- Legend height shall adapt to its content. One curve shall use a compact
  legend.
- Presentation wrapping shall not alter a curve's `DisplayName`.

## Measurement and Analysis Information

- In interactive figures and exported PNG files, context such as archive
  identity, measurement metadata, XYZ, Lab, CCT, CRI and stability metrics
  shall be placed in the right information area.
- Text shall wrap or be split into short lines; it shall never be clipped.
- Every value shown in a right-side information area shall also be declared
  as a Result field for the corresponding analysis.
- A colour-evaluating reflectance output may include a square evaluated-colour
  patch. The generic spectrum viewer does not implicitly calculate XYZ or Lab.

## PDF Figure Rule

- A figure embedded in a PDF shall contain only its plot content and its
  right-side legend.
- A PDF figure shall not contain a side information panel, summary box or
  other explanatory text.
- A PDF figure title shall identify the plot and method, but shall not
  embed calculated numerical results.
- Numerical and descriptive information belongs in the report's **Results**
  table. The Results table is the authoritative record in a PDF.
- This rule applies to every registered analysis, including measured
  spectra, CRI, spectral mean, spectral difference and density reports.

## Output Consistency

Interactive figures and Work PNG files use the right information area for
a concise summary. Report PDFs use the same plot, title and right-side
legend geometry, but move all summary information to Results. A visual
improvement in one output path shall be reviewed in the other paths at the
same time.

## Verification

New plot types shall be reviewed against this profile. Automated tests
shall verify that registered report legends use the right-side placement,
that exported figures preserve a legend, and that PDF export omits
right-side information panels. Review shall confirm that every interactive
or PNG side-panel value has a corresponding Results field.
