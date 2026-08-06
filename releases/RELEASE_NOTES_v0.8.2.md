# SpectraLab v0.8.2 Release Notes

Released 2026-08-06.

SpectraLab v0.8.2 establishes a consistent professional presentation
standard for spectral figures while strengthening analysis stability and
report-output reliability.

## Presentation profile

GP-001 defines the required layout for public plots and report figures.
Data curves remain unobscured; legends and concise analysis information
are placed in a consistent right-side information area. The same legend
is preserved in interactive figures, PNG output and PDF reports.

## Analysis improvements

- ANL-009 Spectral Mean reports pointwise standard deviation and mean
  relative standard deviation with three decimal places.
- ANL-010 Spectral Difference reports RMS difference and maximum absolute
  difference in both the figure and report result table.
- ANL-CRI figures include correlated colour temperature and CRI (Ra).

## Workflow improvements

- Measurement archive folders can be selected and remembered for the
  current MATLAB session.
- File-selection dialogs identify the requested analysis and archive role.
- Report PNG output is written directly to the configured plot folder,
  avoiding temporary figures in the report folder.
- The public examples now use the same output and presentation contracts as
  the Work workflows.

## Compatibility

The release preserves the SLAB-MAT archive format and the established
public report-analysis identifiers.
