function aligned = alignArchiveSet(archives, options)
%ALIGNARCHIVESET Validate and align two or more archived spectra.

arguments
    archives (1,:) cell
    options.Resample (1,1) logical = false
    options.RefinementFactor (1,1) double ...
        {mustBeInteger, mustBePositive} = 1
    options.InterpolationMethod (1,1) string ...
        {mustBeMember(options.InterpolationMethod, ...
        ["pchip", "makima", "spline"])} = "pchip"
end

if numel(archives) < 2
    error("SpectraLab:Analysis:TooFewSources", ...
        "At least two source archives are required for a spectral mean.");
end

count = numel(archives);
wavelengths = cell(1, count);
values = cell(1, count);
units = strings(1, count);
for index = 1:count
    archive = archives{index};
    validation = spectralab.archive.validate(archive);
    if ~validation.IsValid
        error("SpectraLab:Analysis:InvalidSourceArchive", ...
            "Source archive %d is invalid:\n%s", index, ...
            strjoin(validation.Errors, newline));
    end
    wavelengths{index} = double(archive.Measurement.Wavelength(:));
    values{index} = double(archive.Measurement.Value(:));
    units(index) = string(archive.Measurement.Unit);
    if any(~isfinite(values{index}))
        error("SpectraLab:Analysis:InvalidSourceSignal", ...
            "Source spectrum %d must contain finite values.", index);
    end
end

if any(units ~= units(1))
    error("SpectraLab:Analysis:UnitMismatch", ...
        "All source archives must use the same measurement unit.");
end

if ~options.Resample
    referenceWavelength = wavelengths{1};
    for index = 2:count
        if ~isequal(referenceWavelength, wavelengths{index})
            error("SpectraLab:Analysis:WavelengthMismatch", ...
                "Source wavelength grids differ. Set Resample=true to align them.");
        end
    end
    wavelength = referenceWavelength;
    valueMatrix = zeros(numel(wavelength), count);
    for index = 1:count
        valueMatrix(:, index) = values{index};
    end
    alignment = "Exact";
else
    fineWavelengths = cell(1, count);
    fineValues = cell(1, count);
    for index = 1:count
        spectrum = spectralab.core.Spectrum(wavelengths{index}, values{index});
        fine = spectralab.core.resampleSpectrum(spectrum, ...
            RefinementFactor=options.RefinementFactor, ...
            Method=options.InterpolationMethod);
        fineWavelengths{index} = fine.WavelengthNm(:);
        fineValues{index} = fine.Power(:);
    end
    lowerBound = max(cellfun(@(x) x(1), fineWavelengths));
    upperBound = min(cellfun(@(x) x(end), fineWavelengths));
    if lowerBound >= upperBound
        error("SpectraLab:Analysis:NoCommonWavelengthRange", ...
            "The source archives have no common wavelength range.");
    end
    wavelength = zeros(0, 1);
    for index = 1:count
        grid = fineWavelengths{index};
        wavelength = [wavelength; ...
            grid(grid >= lowerBound & grid <= upperBound)]; %#ok<AGROW>
    end
    wavelength = unique(wavelength);
    valueMatrix = zeros(numel(wavelength), count);
    for index = 1:count
        valueMatrix(:, index) = interp1(fineWavelengths{index}, ...
            fineValues{index}, wavelength, options.InterpolationMethod);
    end
    alignment = "Interpolated";
end

aligned = struct( ...
    "WavelengthNm", wavelength(:), ...
    "ValueMatrix", valueMatrix, ...
    "Unit", units(1), ...
    "SourceCount", count, ...
    "Alignment", alignment, ...
    "Resampled", options.Resample, ...
    "RefinementFactor", options.RefinementFactor, ...
    "InterpolationMethod", options.InterpolationMethod);
end
