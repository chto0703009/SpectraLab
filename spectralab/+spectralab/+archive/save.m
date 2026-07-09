function save(archive, filename)
%SAVE Save a SpectraLab archive to a MAT-file.
%
%   spectralab.archive.save(archive, filename)
%
% Saves the archive structure using the standard variable name
% "archive". This function defines the public persistence API.

arguments
    archive (1,1) struct
    filename {mustBeTextScalar}
end

filename = char(string(filename));

save(filename, "archive", "-mat");

end