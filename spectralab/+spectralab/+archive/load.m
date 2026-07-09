function archive = load(filename)
%LOAD Load a SpectraLab archive from a MAT-file.
%
%   archive = spectralab.archive.load(filename)
%
% Loads a SpectraLab archive previously written by
% spectralab.archive.save().

arguments
    filename {mustBeTextScalar}
end

filename = char(string(filename));

S = load(filename, "-mat");

if ~isfield(S, "archive")
    error("SpectraLab:Archive:InvalidFile", ...
        "MAT-file does not contain a SpectraLab archive.");
end

archive = S.archive;

% Basic validation
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

end