function filter = loadStandardFilter(filename, options)
%LOADSTANDARDFILTER Load and validate a tabulated standard spectral filter.
%
%   FILTER = spectralab.filters.internal.loadStandardFilter(FILENAME)
%
%   loads a two-column spectral dataset containing wavelength in
%   nanometres and corresponding spectral values.
%
%   Relative filenames are resolved against:
%
%       spectralab/+spectralab/+filters/data
%
%   Absolute filenames are used directly.
%
%   Name-value arguments
%   --------------------
%   Name
%       Human-readable filter name.
%
%   Unit
%       Unit or representation of the tabulated values.
%       Default: "relative".
%
%   Source
%       Traceable source description.
%
%   Description
%       Human-readable filter description.
%
%   Log10Values
%       Interpret the second column as base-10 logarithmic values and
%       convert them using:
%
%           value = 10.^storedValue
%
%       Default: false.
%
%   Normalize
%       Normalize the resulting values to a maximum of 1.
%       Default: true.

    arguments
        filename (1,1) string

        options.Name (1,1) string = ""
        options.Unit (1,1) string = "relative"
        options.Source (1,1) string = ""
        options.Description (1,1) string = ""

        options.Log10Values (1,1) logical = false
        options.Normalize (1,1) logical = true
    end

    resolvedFilename = localResolveFilename(filename);

    if ~isfile(resolvedFilename)
        error( ...
            "spectralab:filters:loadStandardFilter:MissingData", ...
            "Required standard-filter dataset was not found: %s", ...
            resolvedFilename);
    end

    data = readmatrix(resolvedFilename);

    if ~isnumeric(data) || size(data,2) ~= 2 || size(data,1) < 2
        error( ...
            "spectralab:filters:loadStandardFilter:InvalidData", ...
            "The standard-filter dataset must contain exactly two " + ...
            "columns: wavelength and value.");
    end

    wavelengthNm = data(:,1);
    value = data(:,2);

    if any(~isfinite(wavelengthNm))
        error( ...
            "spectralab:filters:loadStandardFilter:InvalidWavelength", ...
            "Wavelength values must be finite.");
    end

    if any(diff(wavelengthNm) <= 0)
        error( ...
            "spectralab:filters:loadStandardFilter:InvalidWavelength", ...
            "Wavelength values must be strictly increasing.");
    end

    if options.Log10Values

        if any(isnan(value)) || any(value == Inf)
            error( ...
                "spectralab:filters:loadStandardFilter:InvalidLogValue", ...
                "Logarithmic filter values must be finite or -Inf.");
        end

        value = 10.^value;

    else

        if any(~isfinite(value))
            error( ...
                "spectralab:filters:loadStandardFilter:InvalidValue", ...
                "Linear filter values must be finite.");
        end

        if any(value < 0)
            error( ...
                "spectralab:filters:loadStandardFilter:InvalidValue", ...
                "Linear filter values must be non-negative.");
        end
    end

    if any(~isfinite(value)) || any(value < 0)
        error( ...
            "spectralab:filters:loadStandardFilter:InvalidValue", ...
            "Converted filter values must be finite and non-negative.");
    end

    if options.Normalize

        maximumValue = max(value);

        if maximumValue <= 0
            error( ...
                "spectralab:filters:loadStandardFilter:InvalidNormalization", ...
                "The filter must contain at least one positive value " + ...
                "when normalization is enabled.");
        end

        value = value ./ maximumValue;
    end

    filter = spectralab.core.SpectralFilter.fromTable( ...
        wavelengthNm, ...
        value, ...
        Name=options.Name, ...
        Unit=options.Unit, ...
        Source=options.Source, ...
        Description=options.Description);

end


function resolvedFilename = localResolveFilename(filename)
%LOCALRESOLVEFILENAME Resolve relative filenames against filter data.

    filename = char(filename);

    if localIsAbsolutePath(filename)
        resolvedFilename = string(filename);
        return
    end

    internalFolder = fileparts(mfilename("fullpath"));
    filtersFolder = fileparts(internalFolder);

    resolvedFilename = string(fullfile( ...
        filtersFolder, ...
        "data", ...
        filename));

end


function tf = localIsAbsolutePath(filename)
%LOCALISABSOLUTEPATH Determine whether a path is absolute.

    if ispc
        tf = ~isempty(regexp(filename, ...
            "^[A-Za-z]:[\\/]|^\\\\", ...
            "once"));
    else
        tf = startsWith(filename, filesep);
    end

end
