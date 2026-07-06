function collection = readCollectionJson(filename)
%READCOLLECTIONJSON  Read SpectrumCollection from JSON.

raw = fileread(filename);
doc = jsondecode(raw);

if ~isfield(doc, "format") || string(doc.format) ~= "spectralab.collection.v1"
    error("SpectraLab:SLAB:UnsupportedFormat", ...
        "Unsupported or missing collection format.");
end

if ~isfield(doc, "collection")
    error("SpectraLab:SLAB:InvalidDocument", ...
        "Missing collection block.");
end

collection = spectralab.core.SpectrumCollection.fromStruct(doc.collection);

end
