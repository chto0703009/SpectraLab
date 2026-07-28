function [renderContext, result] = renderSpacer( ...
        element, context, renderContext)
%RENDERSPACER Measure and record one spacer without changing layout state.

height = validateSpacerHeight(element.Content);
[renderContext, ~] = ...
    spectralab.report.internal.elementRenderers.renderElementCore( ...
        element, context, renderContext, "spacer");
result = spectralab.report.internal.createRenderResult( ...
    element.Id, element.Type, height, false, strings(0,1));
end

function height = validateSpacerHeight(content)
if ~isnumeric(content) || ~isscalar(content) || ...
        ~isreal(content) || ~isfinite(content) || content < 0
    error("SpectraLab:Report:InvalidSpacerContent", ...
        "Spacer content must be one finite non-negative numeric height in points.");
end
height = double(content);
end
