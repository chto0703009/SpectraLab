function collection = readCollection(filename)
%READCOLLECTION  Read a SpectrumCollection.

filename = string(filename);

if endsWith(lower(filename), ".mat")
    loaded = load(filename, "data");
    collection = spectralab.core.SpectrumCollection.fromStruct(loaded.data);
elseif endsWith(lower(filename), ".json")
    collection = spectralab.io.slab.readCollectionJson(filename);
else
    error("SpectraLab:IO:UnsupportedFormat", ...
        "Unsupported input format. Use .slab.json, .json, or .mat.");
end

end
