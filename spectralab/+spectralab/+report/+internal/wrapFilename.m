function [text, lineCount] = wrapFilename(value)
%WRAPFILENAME Wrap a long report filename at a readable separator.

text = string(value);
lineCount = 1;

if ~isscalar(text) || ismissing(text) || strlength(text) <= 42
    return
end

characters = char(text);
midpoint = floor(numel(characters) / 2);
separators = find(ismember(characters, ['_' '-' '.']));
if isempty(separators)
    splitAt = midpoint;
else
    [~, nearest] = min(abs(separators - midpoint));
    splitAt = separators(nearest);
end

text = string(sprintf("%s\n%s", ...
    characters(1:splitAt), characters(splitAt + 1:end)));
lineCount = 2;
end
