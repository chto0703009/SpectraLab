function [renderContext, result] = renderTable( ...
        element, context, renderContext)
%RENDERTABLE Render one table document element.
%
% RP-010 implements the analysisResults role. Other table roles remain
% intentionally unmeasured until their dedicated reporting steps.

if string(element.Role) == "informationBox"
    boxModel = spectralab.report.internal.buildInformationBox(context);
    renderedElement = element;
    renderedElement.Content = boxModel;

    [renderContext, ~] = ...
        spectralab.report.internal.elementRenderers.renderElementCore( ...
            renderedElement, context, renderContext, "table");

    height = spectralab.report.internal.estimateInformationBoxHeight(boxModel);
    result = spectralab.report.internal.createRenderResult( ...
        element.Id, element.Type, height, false, strings(0,1));
    return
end

if any(string(element.Role) == ["measurementInformation", "analysisInformation", "provenance"])
    tableModel = spectralab.report.internal.buildKeyValueTable( ...
        string(element.Role), context);
    renderedElement = element;
    renderedElement.Content = tableModel;

    [renderContext, ~] = ...
        spectralab.report.internal.elementRenderers.renderElementCore( ...
            renderedElement, context, renderContext, "table");

    height = spectralab.report.internal.estimateResultsTableHeight(tableModel);
    result = spectralab.report.internal.createRenderResult( ...
        element.Id, element.Type, height, false, strings(0,1));
    return
end

if string(element.Role) == "analysisResults"
    tableModel = spectralab.report.internal.buildResultsTable( ...
        element.Content, context.Analysis);
    renderedElement = element;
    renderedElement.Content = tableModel;

    [renderContext, ~] = ...
        spectralab.report.internal.elementRenderers.renderElementCore( ...
            renderedElement, context, renderContext, "table");

    height = spectralab.report.internal.estimateResultsTableHeight(tableModel);
    result = spectralab.report.internal.createRenderResult( ...
        element.Id, element.Type, height, false, strings(0,1));
    return
end

[renderContext, result] = ...
    spectralab.report.internal.elementRenderers.renderElementCore( ...
        element, context, renderContext, "table");
end
