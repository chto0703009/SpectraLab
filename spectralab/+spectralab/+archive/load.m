function archive = load(filename, options)
%LOAD Load a SpectraLab archive from a MAT-file.
%
%   archive = spectralab.archive.load(filename)
%
%   archive = spectralab.archive.load(filename, Quiet=true)
%
% By default, a concise archive summary is displayed after loading.
% Set Quiet=true for scripts and batch processing.

arguments
    filename {mustBeTextScalar}
    options.Quiet (1,1) logical = false
end

filename = char(string(filename));

S = load(filename, "-mat");

if ~isfield(S, "archive")
    error("SpectraLab:Archive:InvalidFile", ...
        "MAT-file does not contain a SpectraLab archive.");
end

archive = S.archive;

required = [ ...
    "Identity"
    "Version"
    "Measurement"
    "Metadata"
    "Instrument"
    "Quality"
    "History"];

for k = 1:numel(required)
    if ~isfield(archive, required(k))
        error("SpectraLab:Archive:InvalidArchive", ...
            "Archive is missing required field '%s'.", required(k));
    end
end

if ~options.Quiet
    spectralab.archive.summary(archive);
end

end
