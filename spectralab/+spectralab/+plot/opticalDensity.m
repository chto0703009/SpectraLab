function h = opticalDensity(wavelengthNm, density, options)
%OPTICALDENSITY Plot spectral optical density.
%
%   h = spectralab.plot.opticalDensity(wavelengthNm, density)
%
%   Positive Inf density values are allowed because zero transmission
%   correctly produces infinite optical density.

    arguments
        wavelengthNm
        density
        options.Parent = []
        options.Title (1,1) string = "Optical density spectrum"
        options.LineWidth (1,1) double {mustBePositive, mustBeFinite} = 1.5
        options.Color = []
        options.LineStyle (1,1) string = "-"
        options.Marker (1,1) string = "none"
        options.DisplayName (1,1) string = ""
        options.ShowGrid (1,1) logical = true
    end

    errorPrefix = "spectralab:plot:opticalDensity";
    [wavelengthNm, density] = validateXY( ...
        wavelengthNm, density, errorPrefix, ...
        "Wavelength values", "Optical-density values", true);

    ax = resolveAxes(options.Parent, errorPrefix, "Optical density spectrum");
    plotArguments = lineArguments(options);
    h = plot(ax, wavelengthNm, density, plotArguments{:});
    styleAxes(ax, "Wavelength (nm)", "Optical density", options.Title, options.ShowGrid);
end
