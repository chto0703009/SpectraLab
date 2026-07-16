function h = spectrum(spec, options)
%SPECTRUM Plot a SpectraLab Spectrum object.
%
%   h = spectralab.plot.spectrum(spec)
%
%   h = spectralab.plot.spectrum(spec, ...
%       Parent=ax, ...
%       Normalize=false, ...
%       Title="Measured spectrum", ...
%       LineWidth=1.5, ...
%       Color="r", ...
%       LineStyle="-", ...
%       Marker="none", ...
%       DisplayName="Reference", ...
%       ShowGrid=true, ...
%       ShowSummary=true, ...
%       SummaryLocation="east")
%
%   SummaryLocation may be "east", "west", "northeast", "northwest",
%   "southeast", or "southwest".

    arguments
        spec (1,1) spectralab.core.Spectrum
        options.Parent = []
        options.Normalize (1,1) logical = false
        options.Title (1,1) string = ""
        options.LineWidth (1,1) double {mustBePositive, mustBeFinite} = 1.5
        options.Color = []
        options.LineStyle (1,1) string = "-"
        options.Marker (1,1) string = "none"
        options.DisplayName (1,1) string = ""
        options.ShowGrid (1,1) logical = true
        options.ShowSummary (1,1) logical = true
        options.SummaryLocation (1,1) string {mustBeMember(options.SummaryLocation, ...
            ["east", "west", "northeast", "northwest", "southeast", "southwest"])} = "east"
    end

    errorPrefix = "spectralab:plot:spectrum";
    ax = resolveAxes(options.Parent, errorPrefix, spec.Label);

    if options.Normalize
        y = spec.normalizedPower();
        yLabelText = "Relative spectral power";
    else
        y = spec.Power;
        yLabelText = "Spectral power";
    end

    [wavelengthNm, y] = validateXY( ...
        spec.WavelengthNm, y, errorPrefix, ...
        "Spectrum wavelengths", "Spectrum power", false);

    plotArguments = lineArguments(options);
    h = plot(ax, wavelengthNm, y, plotArguments{:});

    titleText = options.Title;
    if strlength(titleText) == 0 && isempty(options.Parent)
        titleText = spec.Label;
    end

    styleAxes(ax, "Wavelength (nm)", yLabelText, titleText, options.ShowGrid);

    if options.ShowSummary
        addSummaryText(ax, spec, options.SummaryLocation);
    end
end


function addSummaryText(ax, spec, location)

    ss = spec.summaryStruct();
    info = sprintf( ...
        "Peak: %.0f nm\nSamples: %d\nPower: %.4g", ...
        ss.peak_wavelength_nm, ss.samples, ss.integrated_power);

    [x, y, horizontalAlignment, verticalAlignment] = summaryPosition(location);

    text(ax, x, y, info, ...
        "Units", "normalized", ...
        "HorizontalAlignment", horizontalAlignment, ...
        "VerticalAlignment", verticalAlignment, ...
        "BackgroundColor", "w", ...
        "EdgeColor", [0.8 0.8 0.8], ...
        "Margin", 6, ...
        "FontSize", 9, ...
        "Interpreter", "none", ...
        "HandleVisibility", "off", ...
        "Tag", "SpectraLabSummary");
end


function [x, y, horizontalAlignment, verticalAlignment] = summaryPosition(location)

    switch location
        case "east"
            x = 0.98; y = 0.50;
            horizontalAlignment = "right";
            verticalAlignment = "middle";
        case "west"
            x = 0.02; y = 0.50;
            horizontalAlignment = "left";
            verticalAlignment = "middle";
        case "northeast"
            x = 0.98; y = 0.98;
            horizontalAlignment = "right";
            verticalAlignment = "top";
        case "northwest"
            x = 0.02; y = 0.98;
            horizontalAlignment = "left";
            verticalAlignment = "top";
        case "southeast"
            x = 0.98; y = 0.02;
            horizontalAlignment = "right";
            verticalAlignment = "bottom";
        case "southwest"
            x = 0.02; y = 0.02;
            horizontalAlignment = "left";
            verticalAlignment = "bottom";
    end
end
