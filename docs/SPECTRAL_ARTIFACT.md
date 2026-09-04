# Self-contained spectral artifacts

SpectraLab can export a measured spectrum, a derived mean, a transmission
result or a complete ColorChecker session as one MAT
file with schema
`spectralab.spectral-artifact/1.0`.

The artifact is the numerical exchange unit for Camera-41. Reference/sample
selection, wavelength alignment and averaging are completed in SpectraLab
before export. Camera-41 therefore receives exactly one file for each spectral
input and never has to reinterpret a group of source files.

An artifact declares whether its primary result is `measured` or `derived`,
its kind (`single_spectrum` or `spectrum_set`) and its quantity. It retains the
SpectraLab archive and source provenance. A transmission artifact delivers
only its primary `T(lambda)` spectrum; Camera-41 calculates spectral, Status A,
Status M and ISO visual density from that curve. A measured reflectance archive
already contains the i1Pro/i1Pro2 reflectance factor and is never divided by a
second user-selected reference. ColorChecker artifacts contain
all patch spectra and the latest D50 colorimetry.

Use `export_spectrum_artifact.m` for a measured spectrum or derived mean,
`create_camera41_transmission_input.m` for an explicitly ordered
transmission reference/sample pair,
`create_camera41_transmission_series_input.m` for N sample spectra sharing
one explicitly selected reference, and
`export_colorchecker_spectral_artifact.m` for a completed ColorChecker
session. Artifact files can still be opened by `spectralab.archive.load` when
they contain one spectrum.

The Camera-41 transmission-input routines accept either original measurement
archives or saved mean artifacts. The series routine calculates an independent
`T_i(lambda) = S_i(lambda) / R(lambda)` artifact for every selected sample;
the same reference and its provenance are retained in every result. They
create no PDF and save one exchange MAT file plus one proof PNG per result.
Reflectance is exported directly from a calibrated
reflectance archive with `export_spectrum_artifact.m`, or as the complete
ColorChecker spectrum set with `export_colorchecker_spectral_artifact.m`.

Transmission and ColorChecker spectrum-set artifacts intended for Camera-41
are governed by `spectralab.io.camera41ExportContract`. Every such export must
contain the complete inclusive 400-730 nm visible-light interval; callers cannot override
this interchange boundary.
Input archives may extend beyond that range; their original content is
retained as provenance, while only samples inside the Camera-41 interval are
included in the exported spectral result and proof plot where applicable.
The derived transmission panel in its proof PNG is displayed as percent with
data-driven limits. This is a presentation conversion only; the MAT artifact
retains the scientific fractional values.

## Short filenames and revisions

Camera-41 exchange files use the compact pattern
`<artifact-id>_<type>_vNN.mat`; a proof image uses the identical stem followed
by `_proof.png`. The operator supplies only a short semantic artifact ID, for
example `portra160_fb01`. SpectraLab normalises it to lowercase ASCII letters,
digits and underscores, limits it to 40 characters and chooses the next free
revision automatically. The complete filename is limited to 80 characters.

Examples include `portra160_fb01_transmission_v01.mat` and
`sg140_target_reflectance_set_v02.mat`. Source filenames, measurement times,
averaging history and other provenance remain inside the MAT artifact; they
are deliberately not concatenated into its filename. Existing files are never
overwritten.
