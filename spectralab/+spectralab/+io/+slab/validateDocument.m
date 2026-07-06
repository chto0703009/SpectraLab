function validateDocument(doc)
%VALIDATEDOCUMENT  Validate minimal SpectraLab JSON document structure.

if ~isstruct(doc)
    error("SpectraLab:SLAB:InvalidDocument", "Document must be a struct.");
end

if ~isfield(doc, "format") || string(doc.format) ~= "spectralab.spectrum.v1"
    error("SpectraLab:SLAB:UnsupportedFormat", "Unsupported or missing format.");
end

if ~isfield(doc, "spectrum")
    error("SpectraLab:SLAB:InvalidDocument", "Missing spectrum block.");
end

s = doc.spectrum;

requiredSpectrum = ["label", "wavelength_nm", "power"];
for k = 1:numel(requiredSpectrum)
    if ~isfield(s, requiredSpectrum(k))
        error("SpectraLab:SLAB:InvalidSpectrumBlock", ...
            "Missing spectrum field: %s", requiredSpectrum(k));
    end
end

wl = s.wavelength_nm(:);
p = s.power(:);

if numel(wl) ~= numel(p)
    error("SpectraLab:SLAB:SizeMismatch", ...
        "wavelength_nm and power arrays must have equal length.");
end

if numel(wl) < 2
    error("SpectraLab:SLAB:TooFewSamples", ...
        "A spectrum must contain at least two samples.");
end

if any(~isfinite(wl)) || any(~isfinite(p))
    error("SpectraLab:SLAB:NonFiniteData", ...
        "Spectrum arrays must contain finite values.");
end

if any(diff(wl) <= 0)
    error("SpectraLab:SLAB:WavelengthOrder", ...
        "wavelength_nm must be strictly increasing.");
end

end
