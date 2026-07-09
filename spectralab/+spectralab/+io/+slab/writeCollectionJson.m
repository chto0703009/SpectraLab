function writeCollectionJson(collection, filename)
%WRITECOLLECTIONJSON  Write SpectrumCollection to JSON.

doc = struct();
doc.format = "spectralab.collection.v1";
doc.schema_version = 1;
doc.created_by = "SpectraLab 0.5.0";
doc.saved_at = char(datetime("now", "TimeZone", "local"));
doc.collection = collection.toStruct();

txt = jsonencode(doc, "PrettyPrint", true);

fid = fopen(filename, "w");
if fid < 0
    error("SpectraLab:SLAB:OpenFailed", ...
        "Could not open file for writing: %s", filename);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "%s\n", txt);

end
