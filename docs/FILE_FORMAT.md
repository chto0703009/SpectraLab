# SpectraLab File Format

Native extension:

```text
.slab.json
```

Schema:

```text
spectralab.spectrum.v1
```

The file stores:
- label
- timestamp
- wavelength array in nm
- power array
- units
- instrument metadata
- calibration metadata
- free metadata
- summary values

The format is designed to be readable without MATLAB.
