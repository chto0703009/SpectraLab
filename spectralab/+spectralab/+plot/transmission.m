function h = transmission(result, options)
%TRANSMISSION Plot a SpectraLab transmission-analysis result.

    arguments
        result
        options.Parent = []
        options.Title (1,1) string = "Transmission spectrum"
        options.LineWidth (1,1) double {mustBePositive, mustBeFinite} = 1.5
        options.Color = []
        options.LineStyle (1,1) string = "-"
        options.Marker (1,1) string = "none"
        options.DisplayName (1,1) string = ""
        options.ShowGrid (1,1) logical = true
    end

    errorPrefix = "spectralab:plot:transmission";
    [wavelengthNm, value] = unpackResult(result, errorPrefix);
    ax = resolveAxes(options.Parent, errorPrefix, "Transmission spectrum");

    plotArguments = lineArguments(options);
    h = plot(ax, wavelengthNm, value, plotArguments{:});
    styleAxes(ax, "Wavelength (nm)", "Transmission", options.Title, options.ShowGrid);
end


function [wavelengthNm, value] = unpackResult(result, errorPrefix)

    if ~isstruct(result)
        error(errorPrefix + ":InvalidResult", ...
            "Input must be a SpectraLab transmission result structure.");
    end

    if ~isfield(result, "Result") || ~isstruct(result.Result)
        error(errorPrefix + ":MissingResult", ...
            "Input does not contain the required Result section.");
    end

    requiredFields = ["WavelengthNm", "Value"];
    for fieldName = requiredFields
        if ~isfield(result.Result, fieldName)
            error(errorPrefix + ":MissingField", "Result.%s is required.", fieldName);
        end
    end

    [wavelengthNm, value] = validateXY( ...
        result.Result.WavelengthNm, result.Result.Value, errorPrefix, ...
        "Result.WavelengthNm", "Result.Value", false);
end
