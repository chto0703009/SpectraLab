% plot_spectrum
%
% Plot the bundled synthetic reference spectrum and export one PNG file.
% This example does not create a PDF report.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
archiveFile = fullfile(examplesRoot, "data", "example_reference.mat");
plotFolder = fullfile(examplesRoot, "output", "plot");
if ~isfolder(plotFolder), mkdir(plotFolder); end

pngFile = fullfile(plotFolder, "example_reference.png");
if isfile(pngFile)
    error("SpectraLab:Examples:OutputFileAlreadyExists", ...
        "SpectraLab refuses to overwrite the existing file:\n%s", pngFile);
end

archive = spectralab.archive.load( ...
    archiveFile, Quiet=true, Validation="error");
spec = spectralab.archive.restore(archive);

fig = figure("Name", spec.Label, "Color", "white");
ax = axes("Parent", fig);
spectralab.plot.spectrum(spec, Parent=ax, ...
    Title=spec.Label, DisplayName=spec.Label, ShowSummary=false);
spectralab.plot.archiveInformationPanel( ...
    ax, spec, archive, ArchiveName="example_reference");
legend(ax, "Location", "eastoutside", "Interpreter", "none");
exportgraphics(fig, pngFile, "Resolution", 300);

fprintf("SpectraLab spectrum PNG created:\n  %s\n", pngFile);
