function description = describeAnalysis(analysisId)
%DESCRIBEANALYSIS Describe one registered reportable analysis.
%
%   description = spectralab.report.describeAnalysis(analysisId)
%
% Returns the authoritative analysis definition and its ordered archive
% input roles. Execution function handles remain internal.

arguments
    analysisId {mustBeTextScalar}
end

entry = spectralab.report.internal.resolveAnalysisSpecification(analysisId);

description = entry.AnalysisDefinition;
description.InputRoles = entry.InputRoles;
end
