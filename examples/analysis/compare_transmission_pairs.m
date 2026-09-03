% Compare two independently calculated transmission spectra.
%
% Pair A and pair B may use the same reference archive or two different
% references. This bundled example uses one common synthetic reference.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
dataFolder = fullfile(examplesRoot, "data");
plotFolder = fullfile(examplesRoot, "output", "plot");
if ~isfolder(plotFolder), mkdir(plotFolder); end

referenceA = spectralab.archive.load( ...
    fullfile(dataFolder, "example_reference.mat"), Quiet=true);
sampleA = spectralab.archive.load( ...
    fullfile(dataFolder, "example_sample_a.mat"), Quiet=true);
referenceB = spectralab.archive.load( ...
    fullfile(dataFolder, "example_reference.mat"), Quiet=true);
sampleB = spectralab.archive.load( ...
    fullfile(dataFolder, "example_sample_b.mat"), Quiet=true);

comparison = spectralab.analysis.compareTransmissionPairs( ...
    referenceA, sampleA, referenceB, sampleB);
wavelength = comparison.Result.WavelengthNm;

fig = figure("Name", "Transmission-pair comparison", "Color", "white");
tiledlayout(fig, 2, 1, "TileSpacing", "compact", "Padding", "compact");
axTop = nexttile;
plot(axTop, wavelength, 100*comparison.Result.TransmissionA, ...
    "Color", [0.85 0.15 0.15], "LineWidth", 1.6, "DisplayName", "Pair A");
hold(axTop, "on");
plot(axTop, wavelength, 100*comparison.Result.TransmissionB, ...
    "Color", [0.10 0.35 0.85], "LineWidth", 1.6, "DisplayName", "Pair B");
hold(axTop, "off"); grid(axTop, "on"); legend(axTop, "Location", "best");
ylabel(axTop, "Transmission (%)"); title(axTop, "Transmission comparison");

axBottom = nexttile;
plot(axBottom, wavelength, 100*comparison.Result.Difference, ...
    "Color", [0.15 0.15 0.15], "LineWidth", 1.4);
yline(axBottom, 0, ":"); grid(axBottom, "on");
xlabel(axBottom, "Wavelength (nm)");
ylabel(axBottom, "A - B (percentage points)");

pngFile = fullfile(plotFolder, "example_transmission_pair_comparison.png");
if isfile(pngFile)
    error("SpectraLab:Examples:OutputFileAlreadyExists", ...
        "SpectraLab refuses to overwrite the existing file:\n%s", pngFile);
end
exportgraphics(fig, pngFile, "Resolution", 300);
fprintf("Transmission-pair comparison created:\n  %s\n", pngFile);
