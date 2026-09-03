# Self-contained spectral artifacts

SpectraLab can export a measured spectrum, a derived mean, a transmission
result, a reflectance result or a complete ColorChecker session as one MAT
file with schema
`spectralab.spectral-artifact/1.0`.

The artifact is the numerical exchange unit for Camera-41. Reference/sample
selection, wavelength alignment and averaging are completed in SpectraLab
before export. Camera-41 therefore receives exactly one file for each spectral
input and never has to reinterpret a group of source files.

An artifact declares whether its primary result is `measured` or `derived`,
its kind (`single_spectrum` or `spectrum_set`) and its quantity. It retains the
SpectraLab archive and source provenance. Transmission artifacts also retain
the original reference and sample archives plus Status M RGB and ISO visual
white density. Reflectance artifacts retain both source archives and the
derived sample/reference reflectance spectrum. ColorChecker artifacts contain
all patch spectra and the latest D50 colorimetry.

Use `export_spectrum_artifact.m` for a measured spectrum or derived mean,
`create_camera41_transmission_input.m` or
`create_camera41_reflectance_input.m` for an explicitly ordered
reference/sample pair, and
`export_colorchecker_spectral_artifact.m` for a completed ColorChecker
session. Artifact files can still be opened by `spectralab.archive.load` when
they contain one spectrum.

The two Camera-41 input routines accept either original measurement archives
or saved mean artifacts. They create no PDF. Each saves one exchange MAT file
and one proof PNG that shows the unnormalised reference and sample together
with the derived ratio. A reflectance pair must contain source readings made
for sample/reference division; do not divide an archive that already contains
a calibrated reflectance factor by another reference a second time.

Transmission, reflectance and ColorChecker spectrum-set artifacts intended
for Camera-41 are restricted to its selected working interval, 400-730 nm.
Input archives may extend beyond that range; their original content is
retained as provenance, while only samples inside the Camera-41 interval are
included in the exported spectral result and proof plot where applicable.
The derived transmission or reflectance panel in each proof PNG is displayed
as percent with a fixed 0-100 % y-axis. This is a presentation conversion
only; the MAT artifact retains the scientific fractional values from 0 to 1.

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
