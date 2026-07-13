function lineHandle = transmission(wavelengthNm, transmittance, options)
%TRANSMISSION Plot spectral transmittance.
%
%   spectralab.plot.transmission(wavelengthNm, transmittance)
%
%   plots spectral transmittance as a function of wavelength.
%
%   h = spectralab.plot.transmission(...)
%
%   returns the MATLAB Line object.
%
%   Name-value options
%   ------------------
%   Title
%       Plot title.
%       Default: "Transmission spectrum".
%
%   LineWidth
%       Line width.
%       Default: 1.5.
%
%   ShowGrid
%       Show grid.
%       Default: true.
%
%   Parent
%       Parent axes.
%
%   See also spectralab.analysis.transmission
%            spectralab.plot.opticalDensity
%            spectralab.plot.spectrum

arguments
    wavelengthNm {mustBeNumeric,mustBeReal}
    transmittance {mustBeNumeric,mustBeReal}

    options.Title (1,1) string = "Transmission spectrum"
    options.LineWidth (1,1) double {mustBePositive,mustBeFinite} = 1.5
    options.ShowGrid (1,1) logical = true
    options.Parent = []
end

if isempty(wavelengthNm)
    error( ...
        "spectralab:plot:transmission:EmptyWavelength", ...
        "Wavelength values must not be empty.");
end

if isempty(transmittance)
    error( ...
        "spectralab:plot:transmission:EmptyTransmission", ...
        "Transmission values must not be empty.");
end

if numel(wavelengthNm) ~= numel(transmittance)
    error( ...
        "spectralab:plot:transmission:SizeMismatch", ...
        "Wavelength and transmission inputs must contain the same number of values.");
end

if any(~isfinite(wavelengthNm),"all")
    error( ...
        "spectralab:plot:transmission:NonFiniteWavelength", ...
        "Wavelength values must be finite.");
end

if any(~isfinite(transmittance),"all")
    error( ...
        "spectralab:plot:transmission:NonFiniteTransmission", ...
        "Transmission values must be finite.");
end

wavelengthNm = wavelengthNm(:);
transmittance = transmittance(:);

if isempty(options.Parent)
    ax = gca;
else
    ax = options.Parent;

    if ~isa(ax,"matlab.graphics.axis.Axes") || ~isvalid(ax)
        error( ...
            "spectralab:plot:transmission:InvalidParent", ...
            "Parent must be a valid MATLAB axes object.");
    end
end

lineHandle = plot( ...
    ax, ...
    wavelengthNm, ...
    transmittance, ...
    "LineWidth", options.LineWidth);

xlabel(ax,"Wavelength (nm)");
ylabel(ax,"Transmission");
title(ax,options.Title);

if options.ShowGrid
    grid(ax,"on");
else
    grid(ax,"off");
end

box(ax,"on");