% compare_transmission_pairs
%
% Select two independent reference/sample pairs, calculate both spectral
% transmissions, overlay them, and plot their signed difference.

scriptFile = string(mfilename("fullpath"));
examplesRoot = string(fileparts(fileparts(scriptFile)));
archiveFolder = fullfile(examplesRoot, "data");
if ~isfolder(archiveFolder)
    error("SpectraLab:Work:ArchiveFolderNotFound", ...
        "Archive folder not found:\n%s", archiveFolder);
end

[referenceAFile, sampleAFile] = select_transmission_archives( ...
    archiveFolder, "transmission comparison - PAIR A");
if referenceAFile == "" || sampleAFile == ""
    disp("Transmission comparison cancelled."); return
end
[referenceBFile, sampleBFile] = select_transmission_archives( ...
    fileparts(sampleAFile), "transmission comparison - PAIR B");
if referenceBFile == "" || sampleBFile == ""
    disp("Transmission comparison cancelled."); return
end

referenceA = spectralab.archive.load(referenceAFile, Quiet=true, Validation="error");
sampleA = spectralab.archive.load(sampleAFile, Quiet=true, Validation="error");
referenceB = spectralab.archive.load(referenceBFile, Quiet=true, Validation="error");
sampleB = spectralab.archive.load(sampleBFile, Quiet=true, Validation="error");

comparison = spectralab.analysis.compareTransmissionPairs( ...
    referenceA, sampleA, referenceB, sampleB, ...
    Resample=true, RefinementFactor=4, InterpolationMethod="pchip");
wavelength = comparison.Result.WavelengthNm;

[~, sampleAName] = fileparts(sampleAFile);
[~, sampleBName] = fileparts(sampleBFile);
sampleAName = string(sampleAName); sampleBName = string(sampleBName);
profile = spectralab.report.internal.figureLayoutProfile();
fig = figure("Name", "Compare transmission pairs", "NumberTitle", "off", ...
    "Color", "white", "Position", profile.InteractiveFigurePosition);
axTop = axes("Parent", fig, "Position", [0.09 0.56 0.63 0.35]);
plot(axTop, wavelength, 100*comparison.Result.TransmissionA, ...
    "Color", [0.85 0.15 0.15], "LineWidth", 1.6, ...
    "DisplayName", "Pair A: " + sampleAName);
hold(axTop, "on");
plot(axTop, wavelength, 100*comparison.Result.TransmissionB, ...
    "Color", [0.10 0.35 0.85], "LineWidth", 1.6, ...
    "DisplayName", "Pair B: " + sampleBName);
hold(axTop, "off"); grid(axTop, "on");
ylabel(axTop, "Transmission (%)"); title(axTop, "Transmission comparison");
legend(axTop, "Location", "best", "Interpreter", "none");
axTop.Toolbar.Visible = "off";

axBottom = axes("Parent", fig, "Position", [0.09 0.14 0.63 0.28]);
plot(axBottom, wavelength, 100*comparison.Result.Difference, ...
    "Color", [0.15 0.15 0.15], "LineWidth", 1.4);
yline(axBottom, 0, ":"); grid(axBottom, "on");
xlabel(axBottom, "Wavelength (nm)");
ylabel(axBottom, "A - B (percentage points)");
axBottom.Toolbar.Visible = "off";

information = sprintf([ ...
    'PAIR A (red)\nReference: %s\nSample: %s\n\n' ...
    'PAIR B (blue)\nReference: %s\nSample: %s\n\n' ...
    'COMMON COMPARISON\nRange: %.1f-%.1f nm\n' ...
    'RMS difference: %.3f percentage points\n' ...
    'Maximum absolute difference: %.3f percentage points\n\n' ...
    'Alignment: %s; pchip refinement factor 4'], ...
    referenceAFile, sampleAFile, referenceBFile, sampleBFile, ...
    wavelength(1), wavelength(end), ...
    100*comparison.Result.RMSDifference, ...
    100*comparison.Result.MaximumAbsoluteDifference, ...
    comparison.Parameters.Alignment);
annotation(fig, "textbox", [0.75 0.13 0.23 0.76], ...
    "String", information, "Interpreter", "none", ...
    "EdgeColor", [0.75 0.75 0.75], "BackgroundColor", "white", ...
    "FitBoxToText", "off", "VerticalAlignment", "top", "FontSize", 8);
drawnow;

locations = resolve_analysis_output_folders(sampleAFile);
safeA = regexprep(sampleAName, "[^A-Za-z0-9._-]+", "_");
safeB = regexprep(sampleBName, "[^A-Za-z0-9._-]+", "_");
pngFile = fullfile(locations.PlotFolder, ...
    "compare_transmission_" + safeA + "_vs_" + safeB + ".png");
if isfile(pngFile)
    error("SpectraLab:Work:OutputFileAlreadyExists", ...
        "SpectraLab refuses to overwrite the existing file:\n%s", pngFile);
end
exportgraphics(fig, pngFile, "Resolution", 300);

fprintf("\nSpectraLab transmission-pair comparison completed.\n");
fprintf("  Pair A: %s / %s\n", referenceAFile, sampleAFile);
fprintf("  Pair B: %s / %s\n", referenceBFile, sampleBFile);
fprintf("  RMS difference: %.3f percentage points\n", ...
    100*comparison.Result.RMSDifference);
fprintf("  PNG: %s\n\n", pngFile);
