function height = estimateTextHeight(content, style, contentWidth)
%ESTIMATETEXTHEIGHT Deterministically estimate wrapped text height.
%
% This is a layout estimate, not a font-engine measurement. The algorithm
% is deliberately platform independent so identical input produces
% identical report geometry on every supported system.

arguments
    content
    style (1,1) struct
    contentWidth (1,1) double {mustBeFinite, mustBePositive}
end

required = ["FontSize", "LineHeight", "SpaceAfter", "AverageGlyphWidthFactor"];
for k = 1:numel(required)
    if ~isfield(style, required(k))
        error("SpectraLab:Report:InvalidLayoutStyle", ...
            "Layout style is missing required field '%s'.", required(k));
    end
end

text = spectralab.report.internal.normalizeTextContent(content);
availableCharacters = max(1, floor(contentWidth / ...
    (style.FontSize * style.AverageGlyphWidthFactor)));

physicalLines = splitlines(text);
lineCount = 0;
for k = 1:numel(physicalLines)
    n = strlength(physicalLines(k));
    lineCount = lineCount + max(1, ceil(double(n) / availableCharacters));
end

height = lineCount * style.LineHeight + style.SpaceAfter;
end

