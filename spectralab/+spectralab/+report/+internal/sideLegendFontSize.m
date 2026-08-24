function fontSize = sideLegendFontSize(labels)
%SIDELEGENDFONTSIZE Fit a wrapped legend in its reserved side column.

profile = spectralab.report.internal.figureLayoutProfile();
labels = string(labels);
lineCount = 0;
for index = 1:numel(labels)
    wrapped = spectralab.report.internal.wrapValue( ...
        labels(index), profile.MaximumSideLegendCharacters);
    lineCount = lineCount + max(1, numel(split(wrapped, newline)));
end

% Preserve the normal report typography for short legends. Reduce the
% font progressively before changing any plot or sidebar geometry.
if lineCount <= 6
    fontSize = 8;
elseif lineCount <= 12
    fontSize = 7;
elseif lineCount <= 18
    fontSize = 6;
else
    fontSize = 5;
end
end
