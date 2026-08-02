function filter = flat(rangeNm, options)
%FLAT Create a flat spectral weighting function.
%
%   filter = spectralab.filters.flat()
%   filter = spectralab.filters.flat([380 730])
%
%   The returned SpectralFilter has value 1 throughout its valid range.

    arguments
        rangeNm (1,2) double = [380 730]
        options.Name (1,1) string = "Flat spectral weighting"
    end

    if any(~isfinite(rangeNm)) || rangeNm(1) >= rangeNm(2)
        error( ...
            "spectralab:filters:flat:InvalidRange", ...
            "rangeNm must be a finite [minimum maximum] wavelength interval.");
    end

    filter = spectralab.core.SpectralFilter.fromFunction( ...
        @(lambdaNm) ones(size(lambdaNm)), ...
        rangeNm, ...
        Name=options.Name, ...
        Unit="relative", ...
        Source="SpectraLab definition", ...
        Description="Uniform unit weighting across the declared wavelength range.");
end
