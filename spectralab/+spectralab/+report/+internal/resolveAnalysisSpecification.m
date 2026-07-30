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

if ~isfield(registry, "AnalysisId")
    error("SpectraLab:Report:InvalidAnalysisRegistry", ...
        "Analysis registry must contain AnalysisId.");
end

matches = [registry.AnalysisId] == analysisId;

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
