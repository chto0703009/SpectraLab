classdef SpectralFilter
%SPECTRALFILTER Wavelength-dependent spectral weighting function.
%
%   A SpectralFilter represents a wavelength-dependent weighting function
%   used by analyses such as filter response, densitometry, photometry, and
%   colorimetry.
%
%   The filter may be represented by:
%
%       1. Tabulated wavelength/value data
%       2. An analytical function handle
%
%   Create a tabulated filter:
%
%       f = spectralab.core.SpectralFilter.fromTable( ...
%           wavelengthNm, ...
%           value, ...
%           Name="Red filter");
%
%   Create an analytical filter:
%
%       f = spectralab.core.SpectralFilter.fromFunction( ...
%           @(lambdaNm) exp(-0.5*((lambdaNm-550)/20).^2), ...
%           [380 730], ...
%           Name="Gaussian filter");
%
%   Evaluate either representation in the same way:
%
%       value = f.evaluate(lambdaNm);
%
%   Values outside RangeNm are rejected. SpectraLab does not silently
%   extrapolate spectral weighting functions.

    properties (SetAccess = private)
        Name (1,1) string = "Unnamed spectral filter"
        Representation (1,1) string = "table"
        WavelengthNm double = double.empty(0,1)
        Value double = double.empty(0,1)
        Function function_handle = @(lambdaNm) lambdaNm
        RangeNm (1,2) double = [NaN NaN]
        Unit (1,1) string = "relative"
        Source (1,1) string = ""
        Description (1,1) string = ""
    end

    methods (Access = private)
        function obj = SpectralFilter()
        % Private constructor. Use fromTable or fromFunction.
        end
    end

    methods (Static)
        function obj = fromTable(wavelengthNm, value, options)
        %FROMTABLE Create a filter from tabulated wavelength/value data.

            arguments
                wavelengthNm double
                value double

                options.Name (1,1) string = "Unnamed spectral filter"
                options.Unit (1,1) string = "relative"
                options.Source (1,1) string = ""
                options.Description (1,1) string = ""
            end

            wavelengthNm = wavelengthNm(:);
            value = value(:);

            spectralab.core.SpectralFilter.validateTableData( ...
                wavelengthNm, value);

            obj = spectralab.core.SpectralFilter();

            obj.Name = options.Name;
            obj.Representation = "table";
            obj.WavelengthNm = wavelengthNm;
            obj.Value = value;
            obj.Function = @(lambdaNm) interp1( ...
                wavelengthNm, ...
                value, ...
                lambdaNm, ...
                "linear");
            obj.RangeNm = [wavelengthNm(1), wavelengthNm(end)];
            obj.Unit = options.Unit;
            obj.Source = options.Source;
            obj.Description = options.Description;
        end


        function obj = fromFunction(functionHandle, rangeNm, options)
        %FROMFUNCTION Create a filter from an analytical function handle.

            arguments
                functionHandle (1,1) function_handle
                rangeNm (1,2) double

                options.Name (1,1) string = "Unnamed spectral filter"
                options.Unit (1,1) string = "relative"
                options.Source (1,1) string = ""
                options.Description (1,1) string = ""
            end

            spectralab.core.SpectralFilter.validateRange(rangeNm);

            probeWavelength = mean(rangeNm);
            probeValue = functionHandle(probeWavelength);

            if ~isnumeric(probeValue) || ~isscalar(probeValue) || ...
                    ~isfinite(probeValue)
                error( ...
                    "spectralab:core:SpectralFilter:InvalidFunctionOutput", ...
                    "The analytical function must return a finite numeric value.");
            end

            obj = spectralab.core.SpectralFilter();

            obj.Name = options.Name;
            obj.Representation = "function";
            obj.Function = functionHandle;
            obj.RangeNm = double(rangeNm);
            obj.Unit = options.Unit;
            obj.Source = options.Source;
            obj.Description = options.Description;
        end
    end

    methods
        function value = evaluate(obj, wavelengthNm, options)
        %EVALUATE Evaluate the spectral filter at specified wavelengths.
        %
        %   value = filter.evaluate(wavelengthNm)
        %
        %   For tabulated filters, linear interpolation is used by default.
        %   No extrapolation is permitted.

            arguments
                obj (1,1) spectralab.core.SpectralFilter
                wavelengthNm double
                options.InterpolationMethod (1,1) string = "linear"
            end

            originalSize = size(wavelengthNm);
            wavelengthVector = wavelengthNm(:);

            if isempty(wavelengthVector)
                error( ...
                    "spectralab:core:SpectralFilter:EmptyWavelength", ...
                    "Wavelength values must not be empty.");
            end

            if any(~isfinite(wavelengthVector))
                error( ...
                    "spectralab:core:SpectralFilter:NonFiniteWavelength", ...
                    "Wavelength values must be finite.");
            end

            if any(wavelengthVector < obj.RangeNm(1)) || ...
                    any(wavelengthVector > obj.RangeNm(2))
                error( ...
                    "spectralab:core:SpectralFilter:OutsideRange", ...
                    "Requested wavelengths must lie within %.6g to %.6g nm.", ...
                    obj.RangeNm(1), ...
                    obj.RangeNm(2));
            end

            if obj.Representation == "table"
                valueVector = interp1( ...
                    obj.WavelengthNm, ...
                    obj.Value, ...
                    wavelengthVector, ...
                    options.InterpolationMethod);
            else
                valueVector = obj.Function(wavelengthVector);
            end

            if ~isnumeric(valueVector)
                error( ...
                    "spectralab:core:SpectralFilter:InvalidFunctionOutput", ...
                    "The filter function must return numeric values.");
            end

            valueVector = valueVector(:);

            if numel(valueVector) ~= numel(wavelengthVector)
                error( ...
                    "spectralab:core:SpectralFilter:FunctionSizeMismatch", ...
                    "The filter function must return one value per wavelength.");
            end

            if any(~isfinite(valueVector))
                error( ...
                    "spectralab:core:SpectralFilter:NonFiniteOutput", ...
                    "The filter produced non-finite values.");
            end

            value = reshape(valueVector, originalSize);
        end


        function tf = supportsRange(obj, rangeNm)
        %SUPPORTSRANGE True when a requested interval is fully supported.

            arguments
                obj (1,1) spectralab.core.SpectralFilter
                rangeNm (1,2) double
            end

            spectralab.core.SpectralFilter.validateRange(rangeNm);

            tf = rangeNm(1) >= obj.RangeNm(1) && ...
                 rangeNm(2) <= obj.RangeNm(2);
        end


        function output = summaryStruct(obj)
        %SUMMARYSTRUCT Return a concise public summary.

            output = struct();
            output.Name = obj.Name;
            output.Representation = obj.Representation;
            output.RangeNm = obj.RangeNm;
            output.Unit = obj.Unit;
            output.Source = obj.Source;
            output.Description = obj.Description;

            if obj.Representation == "table"
                output.SampleCount = numel(obj.WavelengthNm);
            else
                output.SampleCount = NaN;
            end
        end


        function display(obj)
        %DISPLAY Display a concise human-readable summary.

            fprintf("%s\n", obj.Name);
            fprintf("  Representation: %s\n", obj.Representation);
            fprintf( ...
                "  Range:          %.1f - %.1f nm\n", ...
                obj.RangeNm(1), ...
                obj.RangeNm(2));
            fprintf("  Unit:           %s\n", obj.Unit);

            if strlength(obj.Source) > 0
                fprintf("  Source:         %s\n", obj.Source);
            end
        end
    end

    methods (Static, Access = private)
        function validateTableData(wavelengthNm, value)

            if isempty(wavelengthNm)
                error( ...
                    "spectralab:core:SpectralFilter:EmptyWavelength", ...
                    "Wavelength data must not be empty.");
            end

            if isempty(value)
                error( ...
                    "spectralab:core:SpectralFilter:EmptyValue", ...
                    "Filter values must not be empty.");
            end

            if numel(wavelengthNm) ~= numel(value)
                error( ...
                    "spectralab:core:SpectralFilter:SizeMismatch", ...
                    "Wavelength and filter-value vectors must have equal length.");
            end

            if any(~isfinite(wavelengthNm))
                error( ...
                    "spectralab:core:SpectralFilter:NonFiniteWavelength", ...
                    "Wavelength values must be finite.");
            end

            if any(~isfinite(value))
                error( ...
                    "spectralab:core:SpectralFilter:NonFiniteValue", ...
                    "Filter values must be finite.");
            end

            if numel(wavelengthNm) < 2
                error( ...
                    "spectralab:core:SpectralFilter:TooFewSamples", ...
                    "A tabulated filter requires at least two samples.");
            end

            if any(diff(wavelengthNm) <= 0)
                error( ...
                    "spectralab:core:SpectralFilter:WavelengthNotIncreasing", ...
                    "Wavelength values must be strictly increasing.");
            end
        end


        function validateRange(rangeNm)

            if any(~isfinite(rangeNm))
                error( ...
                    "spectralab:core:SpectralFilter:InvalidRange", ...
                    "The wavelength range must contain finite values.");
            end

            if rangeNm(1) >= rangeNm(2)
                error( ...
                    "spectralab:core:SpectralFilter:InvalidRange", ...
                    "The wavelength range must be [minimum maximum].");
            end
        end
    end
end
