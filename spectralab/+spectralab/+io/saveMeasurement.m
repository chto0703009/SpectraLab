function saveMeasurement(spec, filename, options)
%SAVEMEASUREMENT Save a Spectrum as a SpectraLab archive.
%
%   spectralab.io.saveMeasurement(spec, filename)
%
% Saves the spectrum as a SpectraLab archive in a MAT-file.

arguments
    spec (1,1) spectralab.core.Spectrum
    filename (1,1) string
    options.Overwrite (1,1) logical = false
end

% Prevent accidental overwrite
if isfile(filename) && ~options.Overwrite
    error("SpectraLab:IO:FileExists", ...
        "Archive '%s' already exists. Use Overwrite=true to replace it.", ...
        filename);
end

% Create archive
archive = spectralab.archive.create(spec);

% Save archive
save(filename, "archive");

end