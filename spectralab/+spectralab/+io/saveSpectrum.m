function saveSpectrum(spec, filename)
%SAVESPECTRUM  Save a SpectraLab spectrum.

if ~isa(spec, "spectralab.core.Spectrum")
    error("SpectraLab:IO:InvalidSpectrum", ...
        "Input must be a spectralab.core.Spectrum.");
end

filename = string(filename);

if endsWith(lower(filename), ".mat")
    data = spec.toStruct(); %#ok<NASGU>
    save(filename, "data", "-mat");
elseif endsWith(lower(filename), ".json")
    spectralab.io.slab.writeJson(spec, filename);
else
    error("SpectraLab:IO:UnsupportedFormat", ...
        "Unsupported output format. Use .slab.json, .json, or .mat.");
end

end
