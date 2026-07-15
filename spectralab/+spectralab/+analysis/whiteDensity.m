function result = whiteDensity(reference, sample)
%WHITEDENSITY Calculate photopically weighted visual density.
%
%   RESULT = spectralab.analysis.whiteDensity(REFERENCE, SAMPLE)
%
%   calculates density using the CIE photopic luminous-efficiency
%   weighting function V(lambda).
%
%   The same weighted-density engine is used for white, red, green, blue,
%   and other weighted density measurements. Only the weighting function
%   differs.

    weighting = spectralab.filters.photopic();

    result = spectralab.core.weightedDensity( ...
        reference, ...
        sample, ...
        weighting, ...
        WeightingName="CIE photopic V(lambda)");
end