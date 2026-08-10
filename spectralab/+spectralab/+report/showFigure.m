function view = showFigure(archiveSource, analysisId)
%SHOWFIGURE Display one registered analysis figure without saving outputs.
%
%   view = spectralab.report.showFigure(archiveFile, "ANL-SPECTRUM")
%   view = spectralab.report.showFigure(archive, "ANL-SPECTRUM")
%
% This function uses the same registered renderer and graphical profile as
% report generation. It does not create a PDF, PNG or derived data file.

arguments
    archiveSource
    analysisId (1,1) string
end

if isstruct(archiveSource)
    archive = archiveSource;
elseif ischar(archiveSource) || ...
        (isstring(archiveSource) && isscalar(archiveSource))
    archive = spectralab.archive.load( ...
        string(archiveSource), Quiet=true, Validation="error");
else
    error("SpectraLab:Report:InvalidFigureSource", ...
        "Figure source must be one archive structure or MAT filename.");
end

entry = spectralab.report.internal.resolveAnalysisSpecification(analysisId);
if ~entry.AnalysisDefinition.HasFigure
    error("SpectraLab:Report:AnalysisHasNoFigure", ...
        "Analysis %s does not define a registered figure.", analysisId);
end
if numel(entry.InputRoles) ~= 1
    error("SpectraLab:Report:FigureSourceCount", ...
        "Analysis %s requires %d source archives.", ...
        analysisId, numel(entry.InputRoles));
end

result = entry.AnalysisRunner(archive);
profile = spectralab.report.internal.figureLayoutProfile();
fig = figure( ...
    "Name", "SpectraLab - " + entry.AnalysisDefinition.Name, ...
    "NumberTitle", "off", ...
    "Color", "white", ...
    "Position", profile.InteractiveFigurePosition);
ax = axes("Parent", fig);

try
    entry.FigureRenderer(ax, archive, result);
    drawnow;
catch ME
    if isgraphics(fig), close(fig); end
    rethrow(ME)
end

view = struct("Figure", fig, "Axes", ax, ...
    "AnalysisId", string(entry.AnalysisDefinition.AnalysisId), ...
    "Result", result);
end
