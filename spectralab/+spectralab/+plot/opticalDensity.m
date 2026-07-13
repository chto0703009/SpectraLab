function lineHandle = opticalDensity(wavelengthNm, density, options)
%OPTICALDENSITY Plot spectral optical density.
%
%   spectralab.plot.opticalDensity(wavelengthNm, density)
%
%   plots optical density as a function of wavelength.
%
%   h = spectralab.plot.opticalDensity(...)
%
%   returns the MATLAB Line object.
%
%   Name-value options
%   ------------------
%   Title
%       Plot title. Default: "Optical density spectrum".
%
%   LineWidth
%       Width of the plotted line. Default: 1.5.
%
%   ShowGrid
%       Logical value controlling the grid. Default: true.
%
%   Parent
%       Axes object in which to draw the plot. If omitted, the current
%       axes are used.
%
%   Example
%   -------
%       wavelengthNm = (400:10:700)';
%       transmission = linspace(1, 0.01, numel(wavelengthNm))';
%       density = spectralab.analysis.opticalDensity(transmission);
%
%       spectralab.plot.opticalDensity(wavelengthNm, density);
%
%   See also spectralab.analysis.opticalDensity
%            spectralab.plot.spectrum

    arguments
        wavelengthNm {mustBeNumeric, mustBeReal}
        density {mustBeNumeric, mustBeReal}
        options.Title (1,1) string = "Optical density spectrum"
        options.LineWidth (1,1) double ...
            {mustBePositive, mustBeFinite} = 1.5
        options.ShowGrid (1,1) logical = true
        options.Parent = []
    end

    if isempty(wavelengthNm)
        error( ...
            "spectralab:plot:opticalDensity:EmptyWavelength", ...
            "Wavelength values must not be empty.");
    end

    if isempty(density)
        error( ...
            "spectralab:plot:opticalDensity:EmptyDensity", ...
            "Optical-density values must not be empty.");
    end

    if numel(wavelengthNm) ~= numel(density)
        error( ...
            "spectralab:plot:opticalDensity:SizeMismatch", ...
            ["Wavelength and optical-density inputs must contain " + ...
             "the same number of values."]);
    end

    if any(~isfinite(wavelengthNm), "all")
        error( ...
            "spectralab:plot:opticalDensity:NonFiniteWavelength", ...
            "Wavelength values must be finite.");
    end

    if any(~isfinite(density), "all")
        error( ...
            "spectralab:plot:opticalDensity:NonFiniteDensity", ...
            "Optical-density values must be finite.");
    end

    wavelengthNm = wavelengthNm(:);
    density = density(:);

    if isempty(options.Parent)
        axesHandle = gca;
    else
        axesHandle = options.Parent;

        if ~isa(axesHandle, "matlab.graphics.axis.Axes") || ...
                ~isvalid(axesHandle)
            error( ...
                "spectralab:plot:opticalDensity:InvalidParent", ...
                "Parent must be a valid MATLAB axes object.");
        end
    end

    lineHandle = plot( ...
        axesHandle, ...
        wavelengthNm, ...
        density, ...
        "LineWidth", options.LineWidth);

    xlabel(axesHandle, "Wavelength (nm)");
    ylabel(axesHandle, "Optical density");
    title(axesHandle, options.Title);

    if options.ShowGrid
        grid(axesHandle, "on");
    else
        grid(axesHandle, "off");
    end

    box(axesHandle, "on");
end