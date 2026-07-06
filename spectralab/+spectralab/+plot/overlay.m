function overlay(spectra, varargin)
%OVERLAY  Plot several Spectrum objects.

if isa(spectra, "spectralab.core.SpectrumCollection")
    spectra.plotOverlay(varargin{:});
    return
end

collection = spectralab.core.SpectrumCollection("Overlay");
for k = 1:numel(spectra)
    collection = collection.add(spectra{k});
end
collection.plotOverlay(varargin{:});

end
