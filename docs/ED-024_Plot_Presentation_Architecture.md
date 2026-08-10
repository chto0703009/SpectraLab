# ED-024 — Plot presentation architecture

**Status:** Approved  
**Decision owner:** SpectraLab  
**Applies to:** Interactive figures, exported PNG figures and PDF report figures  
**Normative profile:** `GP-001_Graphical_Presentation_Profile.md`

## Decision

All public SpectraLab plots shall use one shared graphical presentation
architecture. Plot renderers may select content appropriate to an analysis,
but shall not define independent figure geometry, typography or placement.
The interactive figure is the visual reference. A saved PNG shall preserve
that figure's proportions and visual hierarchy rather than inherit the PDF
page or report-figure dimensions.

## Canonical geometry

- Interactive figures use a 1400 x 700 pixel, 2:1 layout.
- PNG figures use the same 2:1 layout and normally export as 1400 x 700
  pixels.
- The spectral axes occupy the left area. The right area is reserved for a
  dynamic legend and, where applicable, an information panel.
- Titles shall remain inside the figure. A long measurement identity shall be
  placed on a second title line.
- Text, legends and information panels shall neither cover plotted data nor be
  clipped at export.
- Space between title, axes, legend and information panel shall make each
  component visually distinct.

The canonical numeric geometry is owned by
`spectralab.report.internal.figureLayoutProfile`. Renderers and exporters
shall read that profile instead of copying layout constants.

## Axes and spectral guide

- Wavelength is shown on the x-axis in nanometres.
- A spectral wavelength colour guide is placed along the lower edge of a
  spectral plot where the analysis supports it.
- All y-axes expressed in percent use 0–100 % as their default range.
- Spectral transmission is calculated internally as a dimensionless ratio but
  plotted as percent and labelled `Transmission (%)`.
- Spectral reflectance is plotted as percent, labelled
  `Relative reflectance (%)`, and defaults to 0–100 %.
- Emission remains in its recorded power unit. Its y-axis is scaled to its
  data and shall not be presented as percent merely because a normalized
  spectral shape is displayed.
- Explicit public plot options may override an automatic non-percent range;
  the standard public percent presentation remains 0–100 %.

## Legend

- The legend is outside the axes in the upper part of the right column.
- Its size is dynamic: a single curve shall not produce an unnecessarily
  large legend box.
- Long labels may wrap during presentation or export, but wrapping shall not
  modify the plotted object's scientific `DisplayName`.
- Interactive, PNG and PDF outputs shall retain the same curve identities.

## Information panel

Interactive figures and PNG files may use the lower part of the right column
for concise evaluated information:

- emission: integrated power, peak wavelength, peak height and available CRI
  context such as CCT, Duv and Ra;
- reflectance outputs that explicitly evaluate colour: XYZ and CIELAB,
  together with a square patch showing the evaluated display colour;
- provenance: relevant project, operator, date, instrument and serial number.

The generic `plot_spectrum` viewer shall not perform or display XYZ or CIELAB
as an implicit side effect. Derived colour information is shown only by an
explicit colour-evaluating workflow. Every numerical analysis value presented
in a registered figure shall also exist in the registered Results definition.

## PDF rule

A PDF report figure contains the axes, title, curve legend and any explicitly
approved square colour patch. It does not duplicate the interactive/PNG
information panel. Numerical results and provenance belong in the PDF
**Results** and quality/provenance sections, where they remain readable and
authoritative.

## Output consistency and verification

Changes to a plot renderer, the shared profile or an exporter shall be checked
in all applicable forms:

1. interactive MATLAB figure;
2. saved PNG at the canonical dimensions;
3. PDF report figure and Results section.

Automated tests shall protect percent conversion and 0–100 % limits, canonical
PNG dimensions, title containment, external legend placement, side-panel
geometry and the separation between PNG information and PDF Results.

## Consequences

- Work scripts call public SpectraLab plotting and reporting functions rather
  than implementing a separate graphical profile.
- New analyses inherit a recognizable SpectraLab appearance.
- Screen approval is meaningful because PNG export preserves the approved
  screen composition.
- Scientific values remain separate from presentation conversions such as
  displaying a dimensionless transmission ratio as percent.
