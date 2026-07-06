function h = spectrum(spec, varargin)
%SPECTRUM  Clean plot for one Spectrum object.
%
% Usage:
%   spectralab.plot.spectrum(spec)
%   spectralab.plot.spectrum(spec, "Normalize", true)
%
% Returns:
%   h - line handle

if ~isa(spec, "spectralab.core.Spectrum")
    error("SpectraLab:Plot:InvalidSpectrum", ...
        "Input must be a spectralab.core.Spectrum.");
end

p = inputParser;
addParameter(p, "Normalize", false, @(x)islogical(x) || isnumeric(x));
addParameter(p, "NewFigure", true, @(x)islogical(x) || isnumeric(x));
parse(p, varargin{:});

normalize = logical(p.Results.Normalize);
newFigure = logical(p.Results.NewFigure);

if newFigure
    figure("Name", char(spec.Label));
end

if normalize
    y = spec.normalizedPower();
    yLabel = "Relative spectral power";
else
    y = spec.Power;
    yLabel = "Spectral power";
end

h = plot(spec.WavelengthNm, y, "LineWidth", 1.5);
grid on;
box off;

xlabel("Wavelength (nm)");
ylabel(yLabel);
title(spec.Label, "Interpreter", "none");

ss = spec.summaryStruct();
info = sprintf("Peak: %.0f nm\nSamples: %d\nPower: %.4g", ...
    ss.peak_wavelength_nm, ss.samples, ss.integrated_power);

x = min(spec.WavelengthNm) + 0.63 * range(spec.WavelengthNm);

if normalize
    yTop = 0.88;
else
    yr = range(y);
    if yr == 0
        yTop = y(1);
    else
        yTop = min(y) + 0.88 * yr;
    end
end

text(x, yTop, info, ...
    "BackgroundColor", "w", ...
    "EdgeColor", [0.8 0.8 0.8], ...
    "Margin", 6, ...
    "FontSize", 9);
end
