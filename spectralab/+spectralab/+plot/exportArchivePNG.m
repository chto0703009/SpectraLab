function info = exportArchivePNG(archiveSource, pngFile, options)
%EXPORTARCHIVEPNG Export one standalone spectrum PNG without creating PDF.
arguments
    archiveSource
    pngFile (1,1) string
    options.Information (1,1) logical = true
    options.ShowFigure (1,1) logical = true
end
if isstruct(archiveSource)
    archive = archiveSource;
else
    archive = spectralab.archive.load( ...
        string(archiveSource), Quiet=true, Validation="error");
end
if isfile(pngFile)
    error("SpectraLab:Plot:OutputFileAlreadyExists", ...
        "SpectraLab refuses to overwrite the existing file:\n%s", pngFile);
end
folder = string(fileparts(pngFile));
if folder ~= "" && ~isfolder(folder), mkdir(folder); end

view = spectralab.report.showFigure(archive, "ANL-SPECTRUM");
cleanup = onCleanup(@() closeIfHidden(view.Figure, options.ShowFigure));
if options.Information
    spec = spectralab.archive.restore(archive);
    [~, archiveName] = fileparts(pngFile);
    spectralab.plot.archiveInformationPanel( ...
        view.Axes, spec, archive, ArchiveName=string(archiveName));
    legendHandle = findall(view.Figure, "Type", "legend");
    if isscalar(legendHandle)
        legendHandle.Units = "normalized";
        legendHandle.Position = ...
            spectralab.report.internal.sideLegendPosition(legendHandle.String);
    end
end
view.Figure.Visible = "off";
drawnow;
exportgraphics(view.Figure, pngFile, Resolution=300);
if options.ShowFigure, view.Figure.Visible = "on"; end
info = struct("PNGFile", pngFile, "Figure", view.Figure, ...
    "Information", options.Information);
clear cleanup
end

function closeIfHidden(fig, showFigure)
if ~showFigure && isgraphics(fig), close(fig); end
end
