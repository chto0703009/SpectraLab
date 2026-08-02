function density = opticalDensity(transmittance, options)
%OPTICALDENSITY Calculate optical density from spectral transmittance.
%
%   density = spectralab.analysis.opticalDensity(transmittance)
%
%   calculates optical density according to
%
%       D = -log10(T)
%
%   where T is fractional transmittance:
%
%       T = 1       -> D = 0
%       T = 0.1     -> D = 1
%       T = 0.01    -> D = 2
%
%   Transmittance must therefore be expressed as a fraction rather than
%   as a percentage.
%
%   density = spectralab.analysis.opticalDensity(transmittance, ...
%       MinimumTransmittance=value)
%
%   specifies the smallest permitted transmittance. Values below this
%   limit are replaced by the limit before calculating density. This
%   prevents infinite density values for zero transmittance.
%
%   Inputs
%   ------
%   transmittance
%       Numeric scalar, vector or array containing fractional
%       transmittance values.
%
%   Name-value options
%   ------------------
%   MinimumTransmittance
%       Positive scalar defining the numerical lower limit.
%       Default: 1e-12.
%
%   Output
%   ------
%   density
%       Optical density values with the same size as transmittance.
%
%   Notes
%   -----
%   Negative values, NaN values and infinite values are rejected.
%
%   Transmittance values greater than one are accepted because small
%   measurement differences can produce values slightly above unity.
%   These values result in negative optical density.
%
%   See also spectralab.analysis.transmission

    arguments
        transmittance {mustBeNumeric, mustBeReal}
        options.MinimumTransmittance (1,1) double ...
            {mustBeReal, mustBeFinite, mustBePositive} = 1e-12
    end

    if isempty(transmittance)
        error( ...
            "spectralab:analysis:opticalDensity:EmptyInput", ...
            "Transmittance must not be empty.");
    end

    if any(~isfinite(transmittance), "all")
        error( ...
            "spectralab:analysis:opticalDensity:NonFiniteInput", ...
            "Transmittance must contain only finite values.");
    end

    if any(transmittance < 0, "all")
        error( ...
            "spectralab:analysis:opticalDensity:NegativeTransmittance", ...
            "Transmittance must not contain negative values.");
    end

	if any(transmittance > 1, "all")
	    warning( ...
	        "spectralab:analysis:opticalDensity:AboveUnity", ...
	        "Transmittance contains values greater than one. " + ...
	        "The corresponding optical-density values will be negative.");
	end

    limitedTransmittance = max( ...
        double(transmittance), ...
        options.MinimumTransmittance);

    density = -log10(limitedTransmittance);
end