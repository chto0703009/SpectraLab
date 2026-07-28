function text = normalizeTextContent(content)
%NORMALIZETEXTCONTENT Normalize supported text content to one string scalar.

if ischar(content)
    values = string(content);
    if isscalar(values)
        text = values;
    else
        text = join(values(:), newline);
    end

elseif isstring(content)
    values = content(:);
    if any(ismissing(values))
        error("SpectraLab:Report:InvalidTextContent", ...
            "Text layout content must not contain missing values.");
    end
    text = join(values, " ");

elseif iscell(content) && all(cellfun(@isTextScalar, content(:)))
    values = strings(numel(content), 1);
    for k = 1:numel(content)
        values(k) = string(content{k});
    end
    if any(ismissing(values))
        error("SpectraLab:Report:InvalidTextContent", ...
            "Text layout content must not contain missing values.");
    end
    text = join(values, " ");

elseif isstruct(content) && isscalar(content) && isfield(content, "Name")
    text = spectralab.report.internal.normalizeTextContent(content.Name);

else
    error("SpectraLab:Report:InvalidTextContent", ...
        "Text layout requires text, a text vector, a cell array of text scalars, or a scalar structure with a Name field.");
end

if ~isscalar(text) || ismissing(text)
    error("SpectraLab:Report:InvalidTextContent", ...
        "Normalized text layout content must be one nonmissing text scalar.");
end
end

function tf = isTextScalar(value)
tf = ischar(value) || (isstring(value) && isscalar(value));
end
