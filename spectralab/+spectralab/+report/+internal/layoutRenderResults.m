function [renderContext, layoutPlan] = layoutRenderResults( ...
        renderContext, renderResults)
%LAYOUTRENDERRESULTS Place measured render results in document order.
%
%   [renderContext, layoutPlan] = ...
%       spectralab.report.internal.layoutRenderResults( ...
%           renderContext, renderResults)
%
% Element renderers measure and describe content. This Layout Engine is the
% sole owner of page selection and vertical placement.
%
% Explicit pageBreak elements always start a new page. Measured elements are
% automatically moved to a new page when they do not fit in the remaining
% content height. RP-009 performs page breaking only between complete
% elements; splitting an individual element is intentionally out of scope.

arguments
    renderContext (1,1) struct
    renderResults (:,1) struct
end

renderContext = spectralab.report.internal.ensureLayoutState(renderContext);
validateRenderResults(renderResults);

layoutPlan = repmat(emptyPlacement(), 0, 1);

for k = 1:numel(renderResults)
    result = renderResults(k);

    if result.PageBreakRequested
        renderContext.State.Layout.CurrentPage = ...
            renderContext.State.Layout.CurrentPage + 1;
        renderContext.State.Layout.CursorY = 0;

        placement = makePlacement(result, ...
            renderContext.State.Layout.CurrentPage, 0, 0, ...
            false, true, false);
        layoutPlan(end+1,1) = placement; %#ok<AGROW>
        continue
    end

    layout = renderContext.State.Layout;
    page = layout.CurrentPage;
    y = layout.CursorY;
    measured = isfinite(result.HeightUsed);
    automaticPageBreak = false;

    if measured
        height = double(result.HeightUsed);

        if height > layout.ContentHeight
            error("SpectraLab:Report:ElementTooTall", ...
                "Document element '%s' requires %.3f points, but the available page content height is %.3f points.", ...
                result.ElementId, height, layout.ContentHeight);
        end

        requiredHeight = height;
        if isFigureCaptionPair(renderResults, k)
            captionHeight = double(renderResults(k+1).HeightUsed);
            if ~isfinite(captionHeight)
                error("SpectraLab:Report:InvalidFigureCaptionLayout", ...
                    "A figure caption must have a finite measured height.");
            end
            requiredHeight = height + captionHeight;
            if requiredHeight > layout.ContentHeight
                error("SpectraLab:Report:FigureCaptionTooTall", ...
                    "Figure and caption require %.3f points, but the available page content height is %.3f points.", ...
                    requiredHeight, layout.ContentHeight);
            end
        end

        if y > 0 && y + requiredHeight > layout.ContentHeight
            page = page + 1;
            y = 0;
            automaticPageBreak = true;
        end

        renderContext.State.Layout.CurrentPage = page;
        renderContext.State.Layout.CursorY = y + height;
    else
        height = NaN;
    end

    placement = makePlacement(result, page, y, height, measured, ...
        false, automaticPageBreak);
    layoutPlan(end+1,1) = placement; %#ok<AGROW>
end

renderContext.State.CurrentPage = ...
    renderContext.State.Layout.CurrentPage;
renderContext.State.CursorY = renderContext.State.Layout.CursorY;
end

function tf = isFigureCaptionPair(results, index)
%ISFIGURECAPTIONPAIR True for a figure immediately followed by its caption.

tf = string(results(index).ElementType) == "figure" && ...
    index < numel(results) && ...
    string(results(index+1).ElementType) == "caption";
end

function placement = makePlacement( ...
        result, page, y, height, measured, explicitPageBreak, automaticPageBreak)
placement = struct( ...
    "ElementId", string(result.ElementId), ...
    "ElementType", string(result.ElementType), ...
    "Page", double(page), ...
    "Y", double(y), ...
    "Height", double(height), ...
    "Measured", logical(measured), ...
    "ExplicitPageBreak", logical(explicitPageBreak), ...
    "AutomaticPageBreak", logical(automaticPageBreak));
end

function validateRenderResults(results)
required = [ ...
    "ElementId"
    "ElementType"
    "HeightUsed"
    "PageBreakRequested"
    "Warnings"];

for k = 1:numel(results)
    result = results(k);
    if ~isstruct(result) || ~isscalar(result)
        error("SpectraLab:Report:InvalidRenderResult", ...
            "Layout Engine requires scalar RenderResult structures.");
    end

    for j = 1:numel(required)
        fieldName = required(j);
        if ~isfield(result, fieldName)
            error("SpectraLab:Report:InvalidRenderResult", ...
                "RenderResult is missing required field '%s'.", fieldName);
        end
    end

    if ~isnumeric(result.HeightUsed) || ~isscalar(result.HeightUsed) || ...
            ~(isnan(result.HeightUsed) || ...
            (isfinite(result.HeightUsed) && result.HeightUsed >= 0))
        error("SpectraLab:Report:InvalidRenderResult", ...
            "RenderResult HeightUsed must be NaN or a finite non-negative scalar.");
    end

    if ~islogical(result.PageBreakRequested) || ...
            ~isscalar(result.PageBreakRequested)
        error("SpectraLab:Report:InvalidRenderResult", ...
            "RenderResult PageBreakRequested must be a logical scalar.");
    end
end
end

function placement = emptyPlacement()
placement = struct( ...
    "ElementId", "", ...
    "ElementType", "", ...
    "Page", 0, ...
    "Y", NaN, ...
    "Height", NaN, ...
    "Measured", false, ...
    "ExplicitPageBreak", false, ...
    "AutomaticPageBreak", false);
end
