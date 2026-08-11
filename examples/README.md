# SpectraLab examples

The examples are part of the SpectraLab public documentation. Run
`startup` from the project root before using them.

## Workflow categories

- `measurement/` contains instrument workflows that create measurements.
- `analysis/` contains `calculate_*_report.m` and `plot_*.m` workflows.
- `inventory/` contains read-only `list_*.m` quality tools.
- `colorchecker/` contains controlled patch remeasurement and nominal Lab
  chain-check workflows.
- `data/` contains deterministic, synthetic SLAB-MAT example archives.

Naming communicates the output contract:

- `measure_*` operates an instrument and saves a measurement.
- `calculate_*_report` performs a registered analysis and creates a PDF
  report plus a registered PNG when that analysis defines a figure.
- `plot_*` creates a PNG only and never creates a PDF.
- `list_*` reads and summarizes data without changing it.

## Quick start

```matlab
cd("<SpectraLab project root>")
startup

plot_spectrum
plot_transmission
calculate_cri_report
calculate_spectral_mean_report
calculate_spectral_difference_report
calculate_statusA_iso_visual_density_report
calculate_statusM_iso_visual_density_report
list_archive_folder
measure_emission_spectrum
measure_emission_series
measure_transmission_pair
measure_colorchecker_reflectance
assign_colorchecker_target_definition
calculate_colorchecker_colorimetry
compare_colorchecker_xrite_lab
remeasure_colorchecker_patches
```

## Recommended onboarding path

Start with one complete workflow at a time. Each measurement example owns the
instrument interaction, identity prompts, immutable archive and its registered
presentation outputs.

1. **Emission:** run `measure_emission_spectrum`. Confirm that one MAT archive,
   one ANL-SPECTRUM PDF report and one PNG figure are created. Continue with
   `measure_emission_series` when repeated measurements are needed; the dialog
   selects the series length.
2. **Transmission:** run `measure_transmission_pair`. First measure the source
   without the sample, then insert the sample without changing source,
   geometry or exposure. The workflow preserves both source measurements and
   creates the separate ANL-001 transmission PDF and PNG.
3. **ColorChecker:** run `measure_colorchecker_reflectance`. New X-Rite
   ColorChecker Digital SG sessions contain the controlled target definition
   from creation. Then run `calculate_colorchecker_colorimetry`; use
   `compare_colorchecker_xrite_lab` for the optional nominal-data chain check.
4. **Legacy ColorChecker data:** run
   `assign_colorchecker_target_definition` once before recalculating
   colorimetry. This creates a new JSON and never modifies the source JSON or
   MAT archives.

Read the Command Window summary after every workflow. It lists the saved MAT,
PDF and PNG files explicitly; reports and figures are never silent side
effects and existing files are never overwritten.

Generated files are written below `examples/output/`. Existing files are
never overwritten. Delete the relevant example output before repeating a
workflow.

The archives in `data/` are synthetic. They contain neutral example
metadata and no real operator identity, instrument serial number or
laboratory measurement claim.

## Analysis inputs and outputs

| Command | Inputs | Outputs |
|---|---|---|
| `plot_spectrum` | `example_reference.mat` | one spectrum PNG |
| `plot_transmission` | reference + `example_sample_a.mat` | one optical-density PNG |
| `calculate_cri_report` | `example_reference.mat` | ANL-CRI PDF + PNG |
| `calculate_spectral_mean_report` | sample A + sample B | derived MAT + ANL-009 PDF + PNG |
| `calculate_spectral_difference_report` | sample A + sample B | ANL-010 PDF + PNG; no MAT |
| `calculate_statusA_iso_visual_density_report` | reference + sample A | ANL-005 PDF; no registered figure |
| `calculate_statusM_iso_visual_density_report` | reference + sample A | ANL-008 PDF; no registered figure |
| `list_archive_folder` | all bundled MAT files | read-only Command Window inventory |
| `measure_emission_spectrum` | emitted light + i1Pro/i1Pro2 | immutable MAT + ANL-SPECTRUM PDF + PNG |
| `measure_emission_series` | emitted light series + user-selected count | one immutable MAT + ANL-SPECTRUM PDF + PNG per measurement |
| `measure_transmission_pair` | unfiltered source reference, then same source through sample | reference MAT/PDF/PNG + sample MAT/PDF/PNG + ANL-001 transmission PDF/PNG |
| `measure_colorchecker_reflectance` | X-Rite ColorChecker Digital SG + i1Pro/i1Pro2 | session JSON + one immutable MAT archive per patch |
| `assign_colorchecker_target_definition` | completed legacy ColorChecker session | verified target-defined session JSON; source and MAT files unchanged |
| `calculate_colorchecker_colorimetry` | original, amended or target-defined session JSON | verified colorimetry JSON + PDF; optional CSV |
| `compare_colorchecker_xrite_lab` | converted ColorChecker JSON + licensed nominal Lab TXT | traceable comparison CSV |

## ColorChecker quality workflows

`measure_colorchecker_reflectance` uses the architecture-controlled
`xrite-colorchecker-digital-sg-140` definition for new X-Rite ColorChecker
Digital SG sessions. `assign_colorchecker_target_definition` adds that same
verified contract to a completed legacy session without modifying its source
JSON or patch MAT archives. `calculate_colorchecker_colorimetry` then derives
and verifies XYZ and Lab from the immutable reflectance archives.

`compare_colorchecker_xrite_lab` is a measurement-chain consistency check,
not a formal metrological validation. The user selects the separately licensed
nominal X-Rite Lab text file; proprietary nominal data is not distributed with
SpectraLab. See X-Rite's official
[ColorChecker Digital SG product information](https://www.xrite.com/categories/calibration-profiling/colorchecker-digital-sg)
and [custom reference-data guidance](https://www.xrite.com/-/media/xrite/files/apps_engineering_techdocuments/c/custom_reference_data_en.pdf).

`remeasure_colorchecker_patches` creates immutable replacement MAT archives,
an amendment JSON and a new amended session JSON. Original session data is
never overwritten. A subsequent correction must select the latest
`colorchecker_session_amended_NNN.json` so that the complete correction chain
is preserved.

## Physical measurement examples

The following commands require ArgyllCMS `spotread` and a connected i1Pro
or i1Pro2 with its matching white calibration plate:

```matlab
measure_spectrum
measure_spectrum_series_5
measure_emission_spectrum
measure_emission_series
measure_transmission_pair
```

The explicitly named emission and transmission commands are recommended for
new users. `measure_transmission_pair` guides the operator through the
unfiltered reference first and the sample second, preserves each source
measurement independently, and then creates the registered transmission
report and figure. The older generic `measure_spectrum` names remain available
for compatibility and lower-level experimentation.

The examples have been physically verified with both an X-Rite i1Pro2 and
an original GretagMacbeth Eye-One Pro Rev. B. SpectraLab records the latter
model as `i1Pro`. Standard and high-resolution acquisition were verified
with the Eye-One Pro Rev. B. This is consistent with ArgyllCMS Spotread's
device identification and documented instrument support.

The bounded automatic workflow waits until Spotread reports that it is
ready before the user triggers the instrument. A series calibrates once at
the beginning and recalibrates only if Spotread later requests it.

Before calibration, the examples show Spotread's USB identification and ask
the user to confirm the physical model. The serial number reported after
calibration is locked for the workflow and verified after every measurement.
If the instrument changes or its serial number cannot be verified, no MAT,
PDF or PNG output is saved.

The retained legacy interactive alternatives are:

```matlab
interactive_measure_reference
interactive_measure_sample
interactive_save_spectrum
```

Before calibration, confirm that the serial number printed on the instrument
matches the serial number printed on its calibration plate. The plate
number is an operator check and is not stored as separate archive metadata.

Measurement examples use neutral default metadata. Replace `Example
operator` and `SpectraLab example measurement` in the dialog with the real
measurement identity required by your laboratory workflow.

## Repeating an example

All workflows refuse to overwrite existing output. To repeat a workflow,
remove only its corresponding files below:

```text
examples/output/archive/
examples/output/report/
examples/output/plot/
```
