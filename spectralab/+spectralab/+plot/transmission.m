function lineHandle = transmission(wavelengthNm, transmittance, options)
%TRANSMISSION Plot spectral transmittance.
%
%   spectralab.plot.transmission(wavelengthNm, transmittance)
%
%   h = spectralab.plot.transmission(...)
%
%   returns the MATLAB Line object.
%
%   Name-value options
%   ------------------
%   Title
%       Default: "Transmission spectrum".
%
%   LineWidth
%       Default: 1.5.
%
%   ShowGrid
%       Default: true.
%
%   Parent
%       Parent axes.
%
%   See also spectralab.analysis.transmission
%            spectralab.plot.opticalDensity
%            spectralab.plot.spectrum

    arguments
        wavelengthNm {mustBeNumeric, mustBeReal}
        transmittance {mustBeNumeric, mustBeReal}

        options.Title (1,1) string = "Transmission spectrum"
        options.LineWidth (1,1) double ...
            {mustBePositive, mustBeFinite} = 1.5
        options.ShowGrid (1,1) logical = true
        options.Parent = []
    end

    try
        lineHandle = plotSpectralSeries( ...
            wavelengthNm, ...
            transmittance, ...
            "Transmission", ...
            "Transmission spectrum", ...
            "spectralab:plot:transmission", ...
            Title=options.Title, ...
            LineWidth=options.LineWidth, ...
            ShowGrid=options.ShowGrid, ...
            Parent=options.Parent);

    catch exception
        throwMappedException(exception);
    end
end


function throwMappedException(exception)
% Preserve the established public error identifiers.

    identifier = string(exception.identifier);

    mappings = [
        "spectralab:plot:transmission:EmptyValues", ...
        "spectralab:plot:transmission:EmptyTransmission";
        "spectralab:plot:transmission:NonFiniteValues", ...
        "spectralab:plot:transmission:NonFiniteTransmission"
    ];

    for index = 1:size(mappings, 1)
        if identifier == mappings(index, 1)
            mapped = MException( ...
                mappings(index, 2), ...
                "%s", ...
                exception.message);

            throwAsCaller(mapped);
        end
    end

    rethrow(exception);
end