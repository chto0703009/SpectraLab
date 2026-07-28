function h = spectrum(spec, options)
%SPECTRUM Plot a SpectraLab Spectrum object.
%
%   h = spectralab.plot.spectrum(spec)
%
%   h = spectralab.plot.spectrum(spec, ...
%       Parent=ax, ...
%       Normalize=false, ...
%       Title="Measured spectrum", ...
%       LineWidth=1.0, ...
%       Color="r", ...
%       LineStyle="-", ...
%       Marker="none", ...
%       DisplayName="Reference", ...
%       ShowGrid=true, ...
%       ShowSummary=true, ...
%       ShowSpectralColorBar=true, ...
%       YLimits=[0 1], ...
%       SummaryLocation="east")
%
%   SummaryLocation may be "east", "west", "northeast", "northwest",
%   "southeast", or "southwest".

    arguments
        spec (1,1) spectralab.core.Spectrum
        options.Parent = []
        options.Normalize (1,1) logical = false
        options.Title (1,1) string = ""
        options.LineWidth (1,1) double {mustBePositive, mustBeFinite} = 1.0
        options.Color = []
        options.LineStyle (1,1) string = "-"
        options.Marker (1,1) string = "none"
        options.DisplayName (1,1) string = ""
        options.ShowGrid (1,1) logical = true
        options.ShowSummary (1,1) logical = true
        options.ShowSpectralColorBar (1,1) logical = true
        options.YLimits = []
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

	originalHoldState = ishold(ax);
	holdCleanup = onCleanup( ...
	    @() restoreHoldState(ax, originalHoldState)); %#ok<NASGU>

	hold(ax, "on");

	plotArguments = lineArguments(options);
	h = plot(ax, wavelengthNm, y, plotArguments{:});

    titleText = options.Title;
    if strlength(titleText) == 0 && isempty(options.Parent)
        titleText = spec.Label;
    end

    styleAxes(ax, "Wavelength (nm)", yLabelText, titleText, options.ShowGrid);
    applyYLimits(ax, options.YLimits);

    if options.ShowSummary
        addSummaryText(ax, spec, options.SummaryLocation);
    end

    if options.ShowSpectralColorBar
        addSpectralColorBar(ax);
    else
        delete(findall(ax, "Tag", "SpectraLabSpectralColorBar"));
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


function applyYLimits(ax, requestedLimits)

    if isempty(requestedLimits)
        limits = ylim(ax);
        upper = limits(2);
        if ~(isfinite(upper) && upper > 0)
            upper = 1;
        end
        ylim(ax, [0 upper]);
        return
    end

    validateattributes(requestedLimits, {'numeric'}, ...
        {'real', 'finite', 'vector', 'numel', 2}, ...
        "spectralab.plot.spectrum", "YLimits");
    requestedLimits = double(requestedLimits(:).');
    if requestedLimits(2) <= requestedLimits(1)
        error("spectralab:plot:spectrum:InvalidYLimits", ...
            "YLimits must contain two strictly increasing values.");
    end
    ylim(ax, requestedLimits);
end
	
	
function restoreHoldState(ax, holdState)

	    if ~isgraphics(ax, "axes")
	        return
	    end

	    if holdState
	        hold(ax, "on");
	    else
	        hold(ax, "off");
	    end
end
