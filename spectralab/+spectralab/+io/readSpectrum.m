function spec = readSpectrum(filename)
%READSPECTRUM  Read a SpectraLab spectrum.

filename = string(filename);

if endsWith(lower(filename), ".mat")
    loaded = load(filename, "data");
    spec = spectralab.core.Spectrum.fromStruct(loaded.data);
elseif endsWith(lower(filename), ".json")
    spec = spectralab.io.slab.readJson(filename);
else
    error("SpectraLab:IO:UnsupportedFormat", ...
        "Unsupported input format. Use .slab.json, .json, or .mat.");
end

end
