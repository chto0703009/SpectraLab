# Scientific Notes

> Current v1.3.1 calculation and export contract: see [RELEASE_GUIDE.md](RELEASE_GUIDE.md) and [SCIENTIFIC_REVIEW_20261026.md](SCIENTIFIC_REVIEW_20261026.md). Status A/M and ISO visual use transmission before weighting; whiteDensity retains source weighting. The older framework discussion below is read with these corrections.

## Integrated power

Integrated power is computed numerically over wavelength using trapezoidal integration.

## Normalization

Normalization divides the spectrum by its maximum absolute power.

## Units

SpectraLab does not assume radiometric calibration unless the instrument
workflow and archived calibration information explicitly establish it.
The default power unit is `arbitrary`.

## Traceability

Each saved spectrum stores instrument, calibration and metadata blocks.
