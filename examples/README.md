# SpectraLab examples

The examples are part of the SpectraLab public documentation. Run
`startup` from the project root before using them.

## Workflow categories

- `measurement/` contains instrument workflows that create measurements.
- `analysis/` contains `calculate_*_report.m` and `plot_*.m` workflows.
- `inventory/` contains read-only `list_*.m` quality tools.
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
```

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

## Physical measurement examples

The following commands require ArgyllCMS `spotread`, a connected i1Pro2
and its matching white calibration plate:

```matlab
measure_spectrum
measure_spectrum_series_5
```

The bounded automatic workflow waits until Spotread reports that it is
ready before the user triggers the instrument. A series calibrates once at
the beginning and recalibrates only if Spotread later requests it.

The retained legacy interactive alternatives are:

```matlab
interactive_measure_reference
interactive_measure_sample
interactive_save_spectrum
```

Before calibration, confirm that the serial number printed on the i1Pro2
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
