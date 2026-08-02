function value = resolveContextPath(context, sourcePath)
%RESOLVECONTEXTPATH Resolve a canonical dotted path in ReportContext.
%
%   value = spectralab.report.internal.resolveContextPath( ...
%       context, sourcePath)
%
% The function reads ReportContext without modifying it. Source paths use
% canonical dotted field notation, for example "Measurement" or
% "Report.Warnings". Dynamic expressions, indexing, and method calls are
% deliberately not supported.

arguments
    context (1,1) struct
    sourcePath {mustBeTextScalar}
end

sourcePath = string(sourcePath);
sourcePath = strtrim(sourcePath);

if strlength(sourcePath) == 0
    error("SpectraLab:Report:InvalidSourcePath", ...
        "Document source path must not be empty.");
end

parts = split(sourcePath, ".");
if any(strlength(parts) == 0) || ...
        any(~arrayfun(@isValidFieldName, parts))
    error("SpectraLab:Report:InvalidSourcePath", ...
        "Invalid ReportContext source path '%s'.", sourcePath);
end

value = context;
for part = reshape(parts, 1, [])
    if ~isstruct(value) || ~isscalar(value) || ...
            ~isfield(value, char(part))
        error("SpectraLab:Report:MissingContextSource", ...
            "ReportContext does not contain source path '%s'.", ...
            sourcePath);
    end
    value = value.(char(part));
end
end

function tf = isValidFieldName(value)
%ISVALIDFIELDNAME True for one canonical MATLAB structure field name.

tf = isvarname(char(value));
end
