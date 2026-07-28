function save(archive, filename)
%SAVE Save a SpectraLab archive to a MAT-file.
%
%   spectralab.archive.save(archive, filename)
%
% Saves the archive structure using the standard variable name
% "archive". This function defines the public persistence API.
%
% An existing archive is never overwritten. The existing file must be
% deliberately deleted or renamed outside SpectraLab before saving again.

arguments
    archive (1,1) struct
    filename {mustBeTextScalar}
end

filename = char(string(filename));

% MATLAB appends ".mat" when SAVE is called without a file extension.
% Resolve the actual target name before checking whether it already exists.
[~, ~, extension] = fileparts(filename);

if isempty(extension)
    targetFilename = [filename ".mat"];
else
    targetFilename = filename;
end

targetFilename = char(targetFilename);

if isfile(targetFilename)
    error( ...
        "SpectraLab:ArchiveFileAlreadyExists", ...
        ["Archive file already exists and will not be overwritten:\n" ...
         "  %s\n" ...
         "Delete or rename the existing file before saving again."], ...
        targetFilename);
end

% Use the built-in SAVE explicitly because this public function is also
% named save.
builtin("save", targetFilename, "archive", "-mat");

end
