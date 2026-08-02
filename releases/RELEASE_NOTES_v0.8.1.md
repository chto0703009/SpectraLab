# SpectraLab v0.8.1 Release Notes

## Measurement Workflow and Reproducible Examples

SpectraLab v0.8.1 completes the bounded Spotread one-shot workflow for the
X-Rite i1Pro2 and adds traceable pair-spectrum analyses plus curated,
release-ready examples.

## Highlights

- Bounded automatic calibration and measurement without a persistent
  ENTER-controlled Spotread process.
- Controlled recalibration and one retry when calibration has expired.
- Optional, physically verified i1Pro2 high-resolution mode.
- Physical instrument serial-number provenance in new archives and reports.
- ANL-009 Spectral Mean with a reusable, traceable derived MAT archive.
- ANL-010 Spectral Difference for signed light-source stability diagnostics.
- Categorized `measure_*`, `calculate_*_report`, `plot_*`, `interactive_*`
  and `list_*` examples.
- Three synthetic, non-identifying SLAB-MAT example archives.

## Spotread and i1Pro2

Automatic mode runs one bounded Spotread process for calibration and one for
measurement. SpectraLab waits for an explicit ready state, rejects incomplete
or dark signals and creates an archive only after console and `.sp` spectral
data agree.

The default trigger uses separate modal placement confirmations. The physical
i1Pro2 switch remains available through `AutomaticTrigger="instrument"`.
The previously verified interactive workflow remains supported.

Measurement feedback uses one tone frequency:

- one beep when an operation starts;
- two beeps after success;
- five beeps after failure.

## Derived spectral analyses

ANL-009 calculates the pointwise mean of two source archives. Its derived
archive records both source filenames, UUIDs, content hashes, roles and the
registered analysis definition.

ANL-010 calculates the signed difference `A - B`. It is intentionally
diagnostic and produces PDF and PNG outputs without saving a derived MAT
archive.

## Release examples

Run `startup` from the project root. The categorized examples then provide:

```matlab
measure_spectrum
measure_spectrum_series_5
calculate_cri_report
calculate_spectral_mean_report
calculate_spectral_difference_report
calculate_statusA_iso_visual_density_report
calculate_statusM_iso_visual_density_report
plot_spectrum
plot_transmission
list_archive_folder
```

Generated example outputs are written below `examples/output/` and are never
overwritten.

## Compatibility

- The SLAB-MAT archive format remains version 0.6.
- Archives released by v0.8.0 remain readable.
- The interactive Spotread workflow remains available.
- CSV and text exports remain supported.
- Standard spectral resolution remains the default.

## Verification

- MATLAB R2025b on macOS.
- Python 3.12.13, `pexpect` 4.9.0 and `ptyprocess` 0.7.0.
- ArgyllCMS 3.5.0 and `/usr/local/bin/spotread`.
- Physical X-Rite i1Pro2 single-measurement workflow: passed.
- Physical five-measurement series: passed with five MAT, PDF and PNG sets.
- All non-hardware release workflows: passed in a temporary clean tree.
- Full regression: 73 test files, 465 test cases, 0 failed, 0 incomplete.
