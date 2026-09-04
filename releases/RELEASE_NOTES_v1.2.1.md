# SpectraLab v1.2.1 Release Notes

Released 2026-09-04.

SpectraLab v1.2.1 fixes the Camera-41 spectral interchange boundary as a
single architecture-level contract.

## Camera-41 export contract

- Visible light is defined centrally as the inclusive 400-730 nm interval.
- ColorChecker, transmission and transmission-series exports all reference
  the same versioned contract.
- Callers cannot override the Camera-41 wavelength interval.
- Exports fail when the source does not cover the complete interval or lacks
  samples at either 400 or 730 nm.
- Export provenance records the Camera-41 contract and its visible-light
  domain definition.

## Presentation consistency

- Spectral colour guides use the same architecture-level 400-730 nm visible
  interval and render wavelengths outside it as black.

## Compatibility and verification

- Existing SLAB-MAT source archives remain unchanged and readable.
- The runtime remains standard/base MATLAB with no added MathWorks toolbox
  dependency.
- The complete automated regression must pass before tagging and publication.
