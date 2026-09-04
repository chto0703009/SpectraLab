# SpectraLab v1.2.0 Release Notes

Released 2026-09-04.

SpectraLab v1.2.0 strengthens the spectral exchange with Camera-41 while
preserving the immutable SpectraLab measurement archive and the base-MATLAB
runtime policy.

## Main additions

- One common reference can normalise an arbitrary emission-series selection
  into independent, traceable `T(lambda)` artifacts.
- Each series member is saved as its own compact, automatically revisioned MAT
  artifact with a corresponding proof PNG.
- Camera-41 transmission artifacts expose only their primary `T(lambda)`
  spectrum. Subsequent Status A, Status M, visual-density and spectral-density
  calculations belong to Camera-41.
- Transmission and density pair comparison workflows support two independently
  measured reference/sample pairs.

## Corrections and interface clarity

- Removed the misleading second reference/sample division for calibrated
  i1Pro/i1Pro2 reflectance measurements.
- Comparison plots accept derived transmission artifacts directly and retain
  data-driven display limits.
- The comparison-mode dialog is compact and wide enough to show its three
  choices without horizontal scrolling.
- Camera-41 artifact filenames remain short, semantic and revision safe.

## Compatibility and verification

- Existing SLAB-MAT source archives remain unchanged and readable.
- The release requires only standard/base MATLAB; no MathWorks add-on toolbox
  is introduced.
- The complete automated regression must pass before tagging and publication.
