function value = validateMetadataText(value, fieldName, options)
%VALIDATEMETADATEXT Normalize and validate textual metadata.
arguments
    value (1,1) string
    fieldName (1,1) string
    options.MaxLength (1,1) double {mustBeInteger,mustBePositive} = 200
    options.AllowMultiline (1,1) logical = false
end

if ismissing(value)
    error("SpectraLab:Metadata:MissingValue", ...
        "%s metadata must not be missing.", fieldName);
end

value = strtrim(value);

if contains(value, char(0))
    error("SpectraLab:Metadata:InvalidCharacter", ...
        "%s metadata must not contain NUL characters.", fieldName);
end

if ~options.AllowMultiline && ...
        (contains(value, newline) || contains(value, sprintf("\r")))
    error("SpectraLab:Metadata:MultilineNotAllowed", ...
        "%s metadata must be a single line.", fieldName);
end

if strlength(value) > options.MaxLength
    error("SpectraLab:Metadata:ValueTooLong", ...
        "%s metadata must not exceed %d characters.", ...
        fieldName, options.MaxLength);
end
end
