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
%       ShowSummary=true)
%
%   The function returns the MATLAB line handle. Additional graphics
%   properties may therefore be changed directly:
%
%       h = spectralab.plot.spectrum(spec);
%       h.MarkerSize = 8;
%
%   Several spectra may be plotted in the same axes by supplying Parent.

    arguments
        spec (1,1) spectralab.core.Spectrum

        options.Parent = []
        options.Normalize (1,1) logical = false
        options.Title (1,1) string = ""
        options.LineWidth (1,1) double {mustBePositive} = 1.5
        options.Color = []
        options.LineStyle (1,1) string = "-"
        options.Marker (1,1) string = "none"
        options.DisplayName (1,1) string = ""
        options.ShowGrid (1,1) logical = true
        options.ShowSummary (1,1) logical = true
    end

    ax = resolveAxes(options.Parent, spec.Label);

    if options.Normalize
        y = spec.normalizedPower();
        yLabel = "Relative spectral power";
    else
        y = spec.Power;
        yLabel = "Spectral power";
    end

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
        spec.WavelengthNm, ...
        y, ...
        plotArguments{:});

    xlabel(ax, "Wavelength (nm)");
    ylabel(ax, yLabel);

    if strlength(options.Title) > 0
        title(ax, options.Title, "Interpreter", "none");
    elseif isempty(options.Parent)
        title(ax, spec.Label, "Interpreter", "none");
    end

    grid(ax, matlab.lang.OnOffSwitchState(options.ShowGrid));
    box(ax, "on");

    if options.ShowSummary
        addSummaryText(ax, spec, y, options.Normalize);
    end
end


function ax = resolveAxes(parent, label)

    if isempty(parent)
        fig = figure("Name", char(label));
        ax = axes(fig);
        return
    end

    if ~isa(parent, "matlab.graphics.axis.Axes") || ~isvalid(parent)
        error( ...
            "spectralab:plot:spectrum:InvalidParent", ...
            "Parent must be a valid MATLAB axes object.");
    end

    ax = parent;
end


function addSummaryText(ax, spec, y, normalize)

    ss = spec.summaryStruct();

    info = sprintf( ...
        "Peak: %.0f nm\nSamples: %d\nPower: %.4g", ...
        ss.peak_wavelength_nm, ...
        ss.samples, ...
        ss.integrated_power);

    wavelength = spec.WavelengthNm;

    x = min(wavelength) + 0.63 * range(wavelength);

    if normalize
        yTop = 0.88;
    else
        yRange = range(y);

        if yRange == 0
            yTop = y(1);
        else
            yTop = min(y) + 0.88 * yRange;
        end
    end

    text( ...
        ax, ...
        x, ...
        yTop, ...
        info, ...
        "BackgroundColor", "w", ...
        "EdgeColor", [0.8 0.8 0.8], ...
        "Margin", 6, ...
        "FontSize", 9, ...
        "HandleVisibility", "off");
end