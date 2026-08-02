function [renderContext, result] = renderFigure( ...
        element, context, renderContext)
%RENDERFIGURE Render one primary figure document element.
%
% RP-011 creates a deterministic figure geometry model only. No MATLAB
% graphics object is created or retained by this renderer.

if string(element.Role) ~= "primaryFigure"
    [renderContext, result] = ...
        spectralab.report.internal.elementRenderers.renderElementCore( ...
            element, context, renderContext, "figure");
    return
end

layout = spectralab.report.internal.createLayoutState();
figureModel = spectralab.report.internal.buildFigureModel( ...
    element.Content, layout);

element.Content = figureModel;
[renderContext, result] = ...
    spectralab.report.internal.elementRenderers.renderElementCore( ...
        element, context, renderContext, "figure");

result = spectralab.report.internal.createRenderResult( ...
    element.Id, element.Type, figureModel.Height, false, strings(0,1));
end
