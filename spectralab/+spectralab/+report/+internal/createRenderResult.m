function result = createRenderResult( ...
        elementId, elementType, heightUsed, pageBreakRequested, warnings)
%CREATERENDERRESULT Create one canonical document-element render result.
%
%   result = spectralab.report.internal.createRenderResult( ...
%       elementId, elementType, heightUsed, pageBreakRequested, warnings)
%
% RenderResult contains rendering information only. It never contains
% scientific results, measurement metadata, or document content.

arguments
    elementId {mustBeTextScalar}
    elementType {mustBeTextScalar}
    heightUsed (1,1) double
    pageBreakRequested (1,1) logical
    warnings (:,1) string = strings(0,1)
end

elementId = string(elementId);
elementType = string(elementType);

if strlength(strtrim(elementId)) == 0
    error("SpectraLab:Report:InvalidRenderResult", ...
        "RenderResult ElementId must not be empty.");
end

if strlength(strtrim(elementType)) == 0
    error("SpectraLab:Report:InvalidRenderResult", ...
        "RenderResult ElementType must not be empty.");
end

if ~(isnan(heightUsed) || (isfinite(heightUsed) && heightUsed >= 0))
    error("SpectraLab:Report:InvalidRenderResult", ...
        "RenderResult HeightUsed must be NaN or a finite non-negative value.");
end

result = struct( ...
    "ElementId", elementId, ...
    "ElementType", elementType, ...
    "HeightUsed", heightUsed, ...
    "PageBreakRequested", pageBreakRequested, ...
    "Warnings", warnings);
end
