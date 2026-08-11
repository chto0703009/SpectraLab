# ED-025 — Camera-41 hand-off contract

## Decision

SpectraLab and Camera-41 have separate, hash-bound responsibilities.
SpectraLab characterises the physical reflective target and illumination.
Camera-41 characterises the photographed target, camera response and spatial
capture quality. Neither application rewrites the other's source records.

## SpectraLab hand-off

Camera-41 accepts the following SpectraLab records as read-only inputs:

- a completed target-defined ColorChecker session JSON;
- the embedded canonical target ID and target-definition SHA-256;
- one immutable SLAB-MAT reflectance archive per patch, referenced by
  coordinate, archive UUID and scientific content hash;
- the complete correction and controlled-remeasurement provenance;
- a SpectraLab illuminant-spectrum archive and its UUID and content hash;
- optionally, a verified derived colorimetry JSON for inspection and reporting.

Camera-41 recalculates reference XYZ from the immutable R(lambda) archives and
the selected illuminant whenever calibration requires it. Derived Lab or XYZ
in an existing JSON is never treated as a replacement for the spectra.

## Camera-41-owned target imaging definition

Image-analysis roles are not added retrospectively to SpectraLab patch MAT
archives or to an already hash-locked SpectraLab target definition. Camera-41
owns a separately versioned imaging-role map keyed by SpectraLab's canonical
target ID. For `xrite-colorchecker-digital-sg-140`, that map identifies:

- the expected 10 by 14 image geometry and orientation;
- perimeter patches used for spatial illumination assessment;
- neutral, white, black and gray-scale candidates;
- white-balance candidates;
- patches eligible for camera-model fitting and independent validation.

The imaging-role-map version and SHA-256 are stored in every Camera-41
calibration record. Updating that map creates a new Camera-41 calculation; it
does not change the SpectraLab measurement session.

## RAW capture quality gate

Before camera-profile fitting, Camera-41 must verify and record:

- successful target detection and unambiguous A1--N10 orientation;
- robust linear camera-RGB values from the interior of every accepted patch;
- no clipped RAW channel in any calibration patch;
- usable signal above black-level uncertainty;
- repeated perimeter-patch luminance consistency and spatial gradient;
- repeated neutral-patch chromaticity consistency;
- shadows, glare, patch contamination and local within-patch variation;
- lens/capture falloff separately from illuminant spectral identity.

The gate produces `PASS`, `REVIEW` or `FAIL`, plus rejected-patch reasons and a
spatial deviation map. Camera calibration cannot receive `PASS` when required
source hashes fail, orientation is ambiguous or a required RAW channel clips.

## Calibration provenance

Every Camera-41 profile and TIFF conversion records at least:

- RAW filename and SHA-256;
- camera and lens metadata;
- SpectraLab session UUID, filename and manifest SHA-256;
- target canonical ID and SpectraLab target-definition SHA-256;
- every used patch archive UUID and content hash;
- illuminant archive UUID and content hash;
- Camera-41 imaging-role-map version and SHA-256;
- black/white normalization, demosaicing and white-balance settings;
- fitted camera-RGB-to-XYZ model and residuals;
- output colour space, linearity and TIFF encoding.

This contract lets Camera-41 reproduce RAW-to-linear-ACEScg conversion while
preserving SpectraLab as the authoritative physical measurement record.
