function entry = resolveAnalysisSpecification(analysisId, registry)
%RESOLVEANALYSISSPECIFICATION Resolve one canonical RP-020 registry entry.
%
%   entry = spectralab.report.internal.resolveAnalysisSpecification( ...
%       analysisId)
%
%   entry = spectralab.report.internal.resolveAnalysisSpecification( ...
%       analysisId, registry)

arguments
    analysisId {mustBeTextScalar}
    registry (:,1) struct = ...
        spectralab.report.internal.createAnalysisRegistry()
end

analysisId = string(analysisId);

if ~isfield(registry, "AnalysisDefinition") || ...
        ~all(arrayfun(@(entry) ...
            isstruct(entry.AnalysisDefinition) && ...
            isscalar(entry.AnalysisDefinition) && ...
            isfield(entry.AnalysisDefinition, "AnalysisId"), ...
            registry))
    error("SpectraLab:Report:InvalidAnalysisRegistry", ...
        "Analysis registry must contain AnalysisDefinition.AnalysisId.");
end

registeredIds = strings(1, numel(registry));

for k = 1:numel(registry)
    registeredIds(k) = registry(k).AnalysisDefinition.AnalysisId;
end

matches = registeredIds == analysisId;

if ~any(matches)
    error("SpectraLab:Report:UnknownAnalysisId", ...
        "No report specification is registered for AnalysisId '%s'.", ...
        analysisId);
end

if nnz(matches) > 1
    error("SpectraLab:Report:DuplicateAnalysisId", ...
        "Multiple report specifications are registered for AnalysisId '%s'.", ...
        analysisId);
end

entry = registry(matches);
end
