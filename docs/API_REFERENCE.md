# API Reference

## Core

- `spectralab.core.Spectrum`
- `spectralab.core.SpectrumCollection`
- `spectralab.core.Calibration`
- `spectralab.core.Instrument`
- `spectralab.core.Session`
- `spectralab.core.Status`
- `spectralab.core.MeasurementResult`

## Drivers

- `spectralab.drivers.createInstrument`
- `spectralab.drivers.MockInstrument`
- `spectralab.drivers.SpotreadInstrument`

`SpotreadInstrument` supports the v0.8.0-compatible `interactive` mode and
the v0.8.1 bounded `automatic` one-shot mode. Automatic calibration uses
Spotread `-O`; automatic measurement uses `-N -O` after successful
calibration and validates the saved Argyll `.sp` file against console output.
The default automatic trigger is a separate modal confirmation for each
operation. Pass `AutomaticTrigger="instrument"` to use the physically verified
i1Pro2 switch workflow instead.

Pass `HighResolution=true` to request the physically verified i1Pro2 `-H`
mode. The setting is applied to both calibration and measurement. Standard
resolution remains the default.

## Single-spectrum measurement

`spectralab.measurement.oneShot` is the public shared API for one complete
calibrate–measure–archive operation. Set `MeasurementKind="emissive"` for an
emitted-light spectrum or `MeasurementKind="reflectance"` for a reflected-light
spectrum. The user-facing `measure_emission_spectrum` and
`measure_reflectance_spectrum` workflows are mode-specific front ends to this
same operation; the API is not a `private` implementation detail.

```matlab
[measurement, archive, outputs] = spectralab.measurement.oneShot( ...
    "i1Pro2", "sample_name", archiveFolder, ...
    MeasurementKind="emissive", GenerateReport=true, ...
    PNGSpectrumSummary=true);
```

`PNGSpectrumSummary=true` adds peak wavelength and value, spectral integral,
wavelength range, sample count, project, operator, timestamp and instrument
identity to the ANL-SPECTRUM PNG. The single-emission workflow enables it;
series workflows leave it disabled so repeated-series plots remain compact.

## IO

- `spectralab.io.saveSpectrum`
- `spectralab.io.readSpectrum`
- `spectralab.io.saveCollection`
- `spectralab.io.readCollection`
- `spectralab.io.exportCsv`
- `spectralab.io.exportTxt`

## Plot

- `spectralab.plot.spectrum`

## Pair-spectrum analyses

```matlab
meanResult = spectralab.analysis.spectralMean(archiveA, archiveB, ...
    SourceFiles=["source_A.mat", "source_B.mat"]);
derivedArchive = meanResult.Result.DerivedArchive;

differenceResult = spectralab.analysis.spectralDifference( ...
    archiveA, archiveB);  % A minus B; no derived archive
```

Both functions require identical wavelength grids by default. Set
`Resample=true` to explicitly align differing grids over their common range.
ANL-009 is reportable and produces a reusable derived archive. ANL-010 is a
diagnostic, reportable analysis and never produces a MAT archive.
