function writeJson(spec, filename)
%WRITEJSON  Write Spectrum to SpectraLab .slab.json file.

doc = spectralab.io.slab.makeDocument(spec);
spectralab.io.slab.validateDocument(doc);

txt = jsonencode(doc, "PrettyPrint", true);

fid = fopen(filename, "w");
if fid < 0
    error("SpectraLab:SLAB:OpenFailed", ...
        "Could not open file for writing: %s", filename);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "%s\n", txt);

end
