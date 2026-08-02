function model = buildFigureCaption(content)
%BUILDFIGURECAPTION Build the canonical primary-figure caption model.
%
%   model = spectralab.report.internal.buildFigureCaption(content)
%
% The model contains presentation text only and explicitly identifies the
% primary figure to which the caption belongs.

text = spectralab.report.internal.normalizeTextContent(content);
text = strtrim(text);
if strlength(text) == 0
    error("SpectraLab:Report:InvalidFigureCaption", ...
        "Figure caption text must not be empty.");
end

model = struct( ...
    "Format", "SLAB-REPORT-FIGURE-CAPTION", ...
    "Version", "1.0", ...
    "Role", "primaryFigureCaption", ...
    "FigureRole", "primaryFigure", ...
    "Text", text);
end
