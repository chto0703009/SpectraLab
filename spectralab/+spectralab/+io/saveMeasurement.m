function saveMeasurement(spec, filename, options)
%SAVEMEASUREMENT Save a Spectrum as a SpectraLab MAT archive.
%
%   spectralab.io.saveMeasurement(spec, filename)
%
%   spectralab.io.saveMeasurement(spec, filename, Overwrite=true)
%
% If filename has no extension, ".mat" is appended automatically.
% Any other extension is rejected to prevent binary MAT-files from being
% created with misleading names such as ".csv" or ".txt".
%
% Use spectralab.io.exportCsv() for CSV export.

arguments
    spec (1,1) spectralab.core.Spectrum
    filename (1,1) string
    options.Overwrite (1,1) logical = false
end

filename = strtrim(filename);

if strlength(filename) == 0
    error("SpectraLab:IO:MissingFilename", ...
        "A filename is required.");
end

[folder, name, ext] = fileparts(filename);

if strlength(string(ext)) == 0
    filename = string(fullfile(folder, name + ".mat"));
elseif ~strcmpi(ext, ".mat")
    error("SpectraLab:IO:InvalidArchiveExtension", ...
    ['saveMeasurement writes SpectraLab MAT archives and requires a ' ...
     '''.mat'' extension. Use spectralab.io.exportCsv() for CSV output.']);
end

if isfile(filename) && ~options.Overwrite
    error("SpectraLab:IO:FileExists", ...
        "Archive '%s' already exists. Use Overwrite=true to replace it.", ...
        filename);
end

archive = spectralab.archive.create(spec);

save(filename, "archive", "-mat");

end
