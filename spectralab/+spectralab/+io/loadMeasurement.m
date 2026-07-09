function spec = loadMeasurement(filename)
%LOADMEASUREMENT Load a SpectraLab archive from a MAT-file.
%
%   spec = spectralab.io.loadMeasurement(filename)
%
% Loads a SpectraLab archive and restores the corresponding
% Spectrum object.

arguments
    filename (1,1) string
end

%----------------------------------------------------------
% Check file exists
%----------------------------------------------------------

if ~isfile(filename)
    error("SpectraLab:IO:FileNotFound", ...
        "Archive '%s' was not found.", filename);
end

%----------------------------------------------------------
% Load MAT-file
%----------------------------------------------------------

S = load(filename);

%----------------------------------------------------------
% Validate archive
%----------------------------------------------------------

if ~isfield(S,"archive")
    error("SpectraLab:IO:InvalidArchive", ...
        "File '%s' is not a valid SpectraLab archive.", filename);
end

archive = S.archive;

%----------------------------------------------------------
% Restore Spectrum
%----------------------------------------------------------

spec = spectralab.archive.restore(archive);

end