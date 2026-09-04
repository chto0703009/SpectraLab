function [wavelength, values, contract] = applyCamera41ExportContract(wavelength, values)
%APPLYCAMERA41EXPORTCONTRACT Restrict and validate Camera-41 spectral data.
contract = spectralab.io.camera41ExportContract();
range = contract.WavelengthRangeNm;
wavelength = double(wavelength(:));
if size(values,1) ~= numel(wavelength)
    error("SpectraLab:Camera41:SampleCountMismatch", ...
        "The first value dimension must match the wavelength count.");
end
if isempty(wavelength) || any(~isfinite(wavelength)) || ...
        any(diff(wavelength) <= 0)
    error("SpectraLab:Camera41:InvalidWavelengthGrid", ...
        "Camera-41 export requires a finite, strictly increasing wavelength grid.");
end
if wavelength(1) > range(1) || wavelength(end) < range(2)
    error("SpectraLab:Camera41:IncompleteWavelengthRange", ...
        "Camera-41 export requires complete %.0f-%.0f nm coverage.", ...
        range(1), range(2));
end
keep = wavelength >= range(1) & wavelength <= range(2);
wavelength = wavelength(keep);
values = values(keep,:);
if wavelength(1) ~= range(1) || wavelength(end) ~= range(2)
    error("SpectraLab:Camera41:MissingBoundarySamples", ...
        "Camera-41 export requires samples at both %.0f and %.0f nm.", ...
        range(1), range(2));
end
end
