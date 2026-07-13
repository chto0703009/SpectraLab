function lineHandle = plotSpectralSeries( ...
        wavelengthNm, values, yLabelText, defaultTitle, errorPrefix, options)
%PLOTSPECTRALSERIES Shared implementation for spectral line plots.
%
% This is a private helper for functions in spectralab.plot.

    arguments
        wavelengthNm {mustBeNumeric, mustBeReal}
        values {mustBeNumeric, mustBeReal}
        yLabelText (1,1) string
        defaultTitle (1,1) string
        errorPrefix (1,1) string

        options.Title (1,1) string = defaultTitle
        options.LineWidth (1,1) double ...
            {mustBePositive, mustBeFinite} = 1.5
        options.ShowGrid (1,1) logical = true
        options.Parent = []
    end

    if isempty(wavelengthNm)
        error( ...
            errorPrefix + ":EmptyWavelength", ...
            "Wavelength values must not be empty.");
    end

    if isempty(values)
        error( ...
            errorPrefix + ":EmptyValues", ...
            "Spectral values must not be empty.");
    end

    if numel(wavelengthNm) ~= numel(values)
        error( ...
            errorPrefix + ":SizeMismatch", ...
            "Wavelength and spectral values must contain the same number of values.");
    end

    if any(~isfinite(wavelengthNm), "all")
        error( ...
            errorPrefix + ":NonFiniteWavelength", ...
            "Wavelength values must be finite.");
    end

    if any(~isfinite(values), "all")
        error( ...
            errorPrefix + ":NonFiniteValues", ...
            "Spectral values must be finite.");
    end

    wavelengthNm = wavelengthNm(:);
    values = values(:);

    if isempty(options.Parent)
        axesHandle = gca;
    else
        axesHandle = options.Parent;

        if ~isa(axesHandle, "matlab.graphics.axis.Axes") || ...
                ~isvalid(axesHandle)
            error( ...
                errorPrefix + ":InvalidParent", ...
                "Parent must be a valid MATLAB axes object.");
        end
    end

    lineHandle = plot( ...
        axesHandle, ...
        wavelengthNm, ...
        values, ...
        "LineWidth", options.LineWidth);

    xlabel(axesHandle, "Wavelength (nm)");
    ylabel(axesHandle, yLabelText);
    title(axesHandle, options.Title);

    if options.ShowGrid
        grid(axesHandle, "on");
    else
        grid(axesHandle, "off");
    end

    box(axesHandle, "on");
end