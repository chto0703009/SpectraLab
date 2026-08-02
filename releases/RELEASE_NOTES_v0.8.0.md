# SpectraLab v0.8.0 Release Notes

## Analysis and Reporting

SpectraLab v0.8.0 adds a verified scientific analysis and reporting layer
to the established measurement and archive platform.

## Highlights

- Spectral transmission and optical-density analysis.
- White, Status A, ISO visual and Status M density analysis.
- CIE XYZ, xyY and CIELAB analysis.
- CIE 13.3 colour-rendering analysis.
- Versioned standard spectral-filter and CIE test-sample data.
- Deterministic A4 PDF reports.
- Full-resolution PNG export for analyses with figures.
- A canonical analysis registry for every reportable analysis.
- Public analysis discovery with `spectralab.report.listAnalyses` and
  `spectralab.report.describeAnalysis`.

## Plotting and Reports

- Standard plots begin at y = 0.
- Plot axes identify wavelength and the reported quantity.
- Measured-spectrum and CRI report figures include the measurement
  summary and legend.
- Report figures are embedded in PDF output and exported separately as
  PNG where the analysis defines a figure.
- `OpenPDF=true` opens the completed report in the system PDF viewer.

Registered analyses with figures:

- `ANL-SPECTRUM` - measured spectrum
- `ANL-CRI` - measured spectrum used for CIE 13.3 analysis
- `ANL-001` - spectral transmission
- `ANL-002` - spectral optical density

Registered analyses without figures:

- `ANL-004` - white density
- `ANL-005` - Status A density
- `ANL-007` - ISO visual density
- `ANL-008` - Status M density

Figureless reports are intentional: their registered results are scalar or
channel-based result tables rather than spectral curves.

## Compatibility

- The established measurement and archive workflows remain supported.
- CSV and text export remain available.
- Released archive formats remain readable.
- The verified instrument workflow uses ArgyllCMS `spotread` with the
  X-Rite i1Pro2.

## Verification

- 65 test files and 434 test cases passed in the final release suite.
- The interactive calibration and measurement workflow was verified with
  an X-Rite i1Pro2.
- All eight registered report analyses passed visual PDF review.
- The packaged release passed startup and the complete regression suite
  after extraction into a clean directory.
