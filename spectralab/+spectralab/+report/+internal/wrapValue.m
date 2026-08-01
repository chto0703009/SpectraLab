function [text, lineCount] = wrapValue(value, maximumCharacters)
%WRAPVALUE Insert deterministic line breaks into long report text.

arguments
    value
    maximumCharacters (1,1) double {mustBeInteger, mustBePositive} = 42
end

text = string(value);
lineCount = 1;
if ~isscalar(text) || ismissing(text)
    return
end

sourceLines = split(text, newline);
wrappedLines = strings(0,1);
for sourceLine = sourceLines(:).'
    remaining = char(sourceLine);
    while numel(remaining) > maximumCharacters
        candidates = find(ismember(remaining, [' ' '_' '-' '/' ';']));
        candidates = candidates(candidates <= maximumCharacters);
        if isempty(candidates)
            splitAt = maximumCharacters;
        else
            splitAt = candidates(end);
        end
        wrappedLines(end + 1,1) = string(strtrim(remaining(1:splitAt))); %#ok<AGROW>
        remaining = strtrim(remaining(splitAt + 1:end));
    end
    wrappedLines(end + 1,1) = string(remaining); %#ok<AGROW>
end

text = join(wrappedLines, newline);
lineCount = numel(wrappedLines);
end
