function saveCollection(collection, filename)
%SAVECOLLECTION  Save a SpectrumCollection.

if ~isa(collection, "spectralab.core.SpectrumCollection")
    error("SpectraLab:IO:InvalidCollection", ...
        "Input must be a spectralab.core.SpectrumCollection.");
end

filename = string(filename);

if endsWith(lower(filename), ".mat")
    data = collection.toStruct();
    save(filename, "data", "-mat");
elseif endsWith(lower(filename), ".json")
    spectralab.io.slab.writeCollectionJson(collection, filename);
else
    error("SpectraLab:IO:UnsupportedFormat", ...
        "Unsupported output format. Use .slab.json, .json, or .mat.");
end

end
