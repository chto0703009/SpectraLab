function result = info(filename)
%INFO Inspect a SpectraLab archive file without restoring a Spectrum.
%
%   result = spectralab.archive.info(filename)
%
%   spectralab.archive.info(filename)
%
% The function:
%   1. loads the archive quietly,
%   2. validates it,
%   3. creates a human-readable summary.

arguments
    filename (1,1) string
end

filename = strtrim(filename);

if ismissing(filename) || strlength(filename) == 0
    error("SpectraLab:Archive:MissingFilename", ...
        "An archive filename is required.");
end

if ~isfile(filename)
    error("SpectraLab:Archive:FileNotFound", ...
        "Archive file not found: %s", filename);
end

archive = spectralab.archive.load(filename, Quiet=true);
validation = spectralab.archive.validate(archive);
summaryText = spectralab.archive.summary(archive);

result = struct();
result.Filename = string(filename);
result.Archive = archive;
result.Validation = validation;
result.Summary = summaryText;

if nargout == 0
    fprintf("%s\n\n", summaryText);
    fprintf("Validation\n");
    fprintf("----------\n");

    if validation.IsValid
        fprintf("Status        : valid\n");
    else
        fprintf("Status        : invalid\n");
    end

    fprintf("Errors        : %d\n", numel(validation.Errors));
    fprintf("Warnings      : %d\n", numel(validation.Warnings));

    if ~isempty(validation.Errors)
        fprintf("\nErrors\n");
        fprintf("------\n");
        for k = 1:numel(validation.Errors)
            fprintf("- %s\n", validation.Errors(k));
        end
    end

    if ~isempty(validation.Warnings)
        fprintf("\nWarnings\n");
        fprintf("--------\n");
        for k = 1:numel(validation.Warnings)
            fprintf("- %s\n", validation.Warnings(k));
        end
    end

    clear result
end
end
