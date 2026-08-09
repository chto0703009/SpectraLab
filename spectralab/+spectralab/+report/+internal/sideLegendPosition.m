function position = sideLegendPosition(labels)
%SIDELEGENDPOSITION Return content-aware right-column legend geometry.

profile = spectralab.report.internal.figureLayoutProfile();
labels = string(labels);
lineCount = 0;
maximumLineCharacters = 0;
for index = 1:numel(labels)
    lines = split(labels(index), newline);
    lineCount = lineCount + max(1, numel(lines));
    if ~isempty(lines)
        maximumLineCharacters = max( ...
            maximumLineCharacters, max(strlength(lines)));
    end
end
lineCount = max(1, lineCount);
maximum = profile.SideLegend;
height = min(maximum(4), 0.035 + 0.035 * lineCount);
top = maximum(2) + maximum(4);
width = min(maximum(3), max(0.11, ...
    0.06 + 0.006 * double(maximumLineCharacters)));
right = maximum(1) + maximum(3);
position = [right - width, top - height, width, height];
end
