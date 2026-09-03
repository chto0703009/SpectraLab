# SpectraLab v1.1.0 Release Notes

Released 2026-09-03.

SpectraLab v1.1.0 introduces a controlled spectral-exchange layer for
scientific reuse and Camera-41 without changing the preserved SLAB-MAT source
measurement record.

## Main additions

- A single typed MAT artifact can carry a measured spectrum or a traceable
  arithmetic mean as one reusable input.
- Transmission and reflectance artifacts retain their reference and sample
  archives, calculated spectrum and derivation provenance.
- ColorChecker export carries the controlled 140-patch reflectance set.
- Camera-41 exports use 400-730 nm and produce a proof PNG on a 0-100 percent
  scale where applicable.
- Transmission and density results from two independent reference/sample
  pairs can be compared directly.

## User safeguards

The Camera-41 transmission and reflectance scripts label the two file roles
explicitly and show a final assignment summary. Cancelling that confirmation
creates no artifact or proof image.

## Runtime policy

SpectraLab continues to require only standard/base MATLAB. ArgyllCMS and its
`spotread` command provide communication with supported X-Rite instruments.
