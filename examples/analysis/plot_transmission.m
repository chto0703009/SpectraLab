% plot_transmission
%
% Plot optical density for the bundled synthetic reference and sample.
% This example creates one PNG file and no PDF report.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
dataFolder = fullfile(examplesRoot, "data");
plotFolder = fullfile(examplesRoot, "output", "plot");
if ~isfolder(plotFolder), mkdir(plotFolder); end

referenceFile = fullfile(dataFolder, "example_reference.mat");
sampleFile = fullfile(dataFolder, "example_sample_a.mat");
pngFile = fullfile(plotFolder, "example_sample_a_optical_density.png");
if isfile(pngFile)
    error("SpectraLab:Examples:OutputFileAlreadyExists", ...
        "SpectraLab refuses to overwrite the existing file:\n%s", pngFile);
end

referenceArchive = spectralab.archive.load( ...
    referenceFile, Quiet=true, Validation="error");
sampleArchive = spectralab.archive.load( ...
    sampleFile, Quiet=true, Validation="error");
transmission = spectralab.analysis.transmission( ...
    referenceArchive, sampleArchive);
density = spectralab.analysis.opticalDensity( ...
    transmission.Result.Value);

fig = figure("Name", "Synthetic sample optical density", "Color", "white");
ax = axes("Parent", fig);
spectralab.plot.opticalDensity( ...
    transmission.Result.WavelengthNm, density, Parent=ax, ...
    Title="Synthetic sample optical density", ...
    DisplayName="example_sample_a", ShowGrid=true);
ylim(ax, [0, 1.05 * max(density)]);
legend(ax, "Location", "eastoutside", "Interpreter", "none");
exportgraphics(fig, pngFile, "Resolution", 300);

fprintf("SpectraLab transmission PNG created:\n  %s\n", pngFile);
