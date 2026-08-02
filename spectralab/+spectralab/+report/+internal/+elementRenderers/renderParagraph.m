function [renderContext, result] = renderParagraph( ...
        element, context, renderContext)
%RENDERPARAGRAPH Measure and record one paragraph document element.

if string(element.Role) == "reportFooter"
    element.Content = buildFooter(context);
end

style = struct( ...
    "FontSize", 10, ...
    "LineHeight", 14, ...
    "SpaceAfter", 6, ...
    "AverageGlyphWidthFactor", 0.52);

[renderContext, result] = ...
    spectralab.report.internal.elementRenderers.renderMeasuredText( ...
        element, context, renderContext, "paragraph", style);
end

function text = buildFooter(context)
parts = strings(0,1);
if isfield(context,"Report")
    if isfield(context.Report,"ReportId") && strlength(string(context.Report.ReportId)) > 0
        parts(end+1,1) = "Report ID " + string(context.Report.ReportId); %#ok<AGROW>
    end
    if isfield(context.Report,"SpectraLabVersion")
        parts(end+1,1) = "SpectraLab " + string(context.Report.SpectraLabVersion); %#ok<AGROW>
    end
end
if isempty(parts), text = "SpectraLab report"; else, text = strjoin(parts,"  |  "); end
end
