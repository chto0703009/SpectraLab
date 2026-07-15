function h = transmission(result, options)
%TRANSMISSION Plot a SpectraLab transmission-analysis result.
%
%   h = spectralab.plot.transmission(result)
%
%   h = spectralab.plot.transmission(result, ...
%       Parent=ax, ...
%       Title="Transmission spectrum", ...
%       LineWidth=1.5, ...
%       Color="r", ...
%       LineStyle="-", ...
%       Marker="none", ...
%       DisplayName="Sample", ...
%       ShowGrid=true)
%
%   The function returns the MATLAB line handle. This permits additional
%   customization using standard MATLAB graphics properties.
%
%   Several results may be plotted in the same axes by supplying Parent.

    arguments
        result

        options.Parent = []
        options.Title (1,1) string = "Transmission spectrum"
        options.LineWidth (1,1) double {mustBePositive} = 1.5
        options.Color = []
        options.LineStyle (1,1) string = "-"
        options.Marker (1,1) string = "none"
        options.DisplayName (1,1) string = ""
        options.ShowGrid (1,1) logical = true
    end

    validateTransmissionResult(result);

    ax = resolveAxes(options.Parent);

    plotArguments = { ...
        "LineWidth", options.LineWidth, ...
        "LineStyle", options.LineStyle, ...
        "Marker", options.Marker};

    if ~isempty(options.Color)
        plotArguments(end+1:end+2) = {"Color", options.Color};
    end

    if strlength(options.DisplayName) > 0
        plotArguments(end+1:end+2) = { ...
            "DisplayName", options.DisplayName};
    end

    h = plot( ...
        ax, ...
        result.Result.WavelengthNm, ...
        result.Result.Value, ...
        plotArguments{:});

    xlabel(ax, "Wavelength (nm)");
    ylabel(ax, "Transmission");

    if strlength(options.Title) > 0
        title(ax, options.Title);
    end

    grid(ax, matlab.lang.OnOffSwitchState(options.ShowGrid));
    box(ax, "on");
end


function ax = resolveAxes(parent)

    if isempty(parent)
        fig = figure;
        ax = axes(fig);
        return
    end

    if ~isa(parent, "matlab.graphics.axis.Axes") || ~isvalid(parent)
        error( ...
            "spectralab:plot:transmission:InvalidParent", ...
            "Parent must be a valid MATLAB axes object.");
    end

    ax = parent;
end


function validateTransmissionResult(result)

    if ~isstruct(result)
        error( ...
            "spectralab:plot:transmission:InvalidResult", ...
            "Input must be a SpectraLab transmission result structure.");
    end

    if ~isfield(result, "Result") || ~isstruct(result.Result)
        error( ...
            "spectralab:plot:transmission:MissingResult", ...
            "Input does not contain the required Result section.");
    end

    requiredFields = ["WavelengthNm", "Value"];

    for fieldName = requiredFields
        if ~isfield(result.Result, fieldName)
            error( ...
                "spectralab:plot:transmission:MissingField", ...
                "Result.%s is required.", ...
                fieldName);
        end
    end

    wavelength = result.Result.WavelengthNm;
    value = result.Result.Value;

    if ~isnumeric(wavelength) || ~isvector(wavelength)
        error( ...
            "spectralab:plot:transmission:InvalidWavelength", ...
            "Result.WavelengthNm must be a numeric vector.");
    end

    if ~isnumeric(value) || ~isvector(value)
        error( ...
            "spectralab:plot:transmission:InvalidValue", ...
            "Result.Value must be a numeric vector.");
    end

    if numel(wavelength) ~= numel(value)
        error( ...
            "spectralab:plot:transmission:SizeMismatch", ...
            "Result.WavelengthNm and Result.Value must contain the same number of elements.");
    end
end
