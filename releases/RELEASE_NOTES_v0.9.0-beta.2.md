# SpectraLab v0.9.0-beta.2 Prerelease Notes

Released 2026-08-09 for continued controlled real-world validation.

SpectraLab v0.9.0-beta.2 extends the first validation beta with an immutable,
traceable correction workflow and public ColorChecker quality-control
examples. The current stable production release remains v0.8.2.

## Field validation

- A complete 140-patch ColorChecker was measured and converted under CIE D50.
- Four independent one-shot reflectance measurements agreed with Spotread's
  reported colour values at the second decimal place.
- The nominal X-Rite comparison was used as a chain-level quality check, not
  as a formal inter-laboratory conformity claim.

## Controlled patch remeasurement

- Selected patches can be remeasured without changing the original session or
  its immutable MAT archives.
- Every correction creates a separate amendment record and a corrected session.
- Further corrections can continue from an amended session as a verified chain.
- UUID and SHA-256 checks protect both inherited and replacement measurements.

## Public quality-control examples

- A comparison example writes nominal and measured CIELAB values with signed
  lightness differences to CSV.
- A remeasurement example guides the user through selective, reason-recorded
  patch replacement.
- The documentation links to the official X-Rite ColorChecker Digital SG page
  and X-Rite reference-data documentation.

## Validation status

- The complete automated MATLAB regression suite passes.
- The full ColorChecker acquisition, D50 conversion, comparison and chained
  remeasurement workflows have been exercised with physical measurements.
- Broader field validation remains required before v1.0.0.

## Compatibility

- Original measurement sessions and SLAB-MAT archives remain unchanged.
- This beta must be installed separately from a production v0.8.2 setup.
