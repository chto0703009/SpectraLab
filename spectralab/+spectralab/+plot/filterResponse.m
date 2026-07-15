function h = filterResponse(result, options)
%FILTERRESPONSE Plot a wavelength-dependent filter-response result.
%
%   h = spectralab.plot.filterResponse(result)
%
%   The function follows the canonical SpectraLab plotting API and returns
%   the MATLAB line handle.

    arguments
        result

        options.Parent = []
        options.Title (1,1) string = "Filter response"
        options.LineWidth (1,1) double {mustBePositive} = 1.5
        options.Color = []
        options.LineStyle (1,1) string = "-"
        options.Marker (1,1) string = "none"
        options.DisplayName (1,1) string = ""
        options.ShowGrid (1,1) logical = true
    end

    validateResult(result);
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
    ylabel(ax, "Weighted spectral response");

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
            "spectralab:plot:filterResponse:InvalidParent", ...
            "Parent must be a valid MATLAB axes object.");
    end

    ax = parent;
end


function validateResult(result)

    if ~isstruct(result) || ...
            ~isfield(result, "Result") || ...
            ~isstruct(result.Result)
        error( ...
            "spectralab:plot:filterResponse:InvalidResult", ...
            "Input must be a SpectraLab filter-response result.");
    end

    required = ["WavelengthNm", "Value"];

    for fieldName = required
        if ~isfield(result.Result, fieldName)
            error( ...
                "spectralab:plot:filterResponse:MissingField", ...
                "Result.%s is required.", ...
                fieldName);
        end
    end

    if numel(result.Result.WavelengthNm) ~= numel(result.Result.Value)
        error( ...
            "spectralab:plot:filterResponse:SizeMismatch", ...
            "Result wavelength and value vectors must have equal length.");
    end
end
