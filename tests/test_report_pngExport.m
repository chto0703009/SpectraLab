function tests = test_report_pngExport
%TEST_REPORT_PNGEXPORT Verify RP-015 report-owned PNG export.

tests = functiontests(localfunctions);
end

function testExportsFullResolutionPNG(testCase)
[pngFile, cleanupFolder] = temporaryPNG(); %#ok<ASGLU>
[renderContext, cleanupGraphics] = makeRenderContext(); %#ok<ASGLU>

info = spectralab.report.internal.exportPNG(pngFile, renderContext);

verifyTrue(testCase, isfile(pngFile));
fileInfo = dir(pngFile);
verifyGreaterThan(testCase, fileInfo.bytes, 1000);
verifyEqual(testCase, info.Format, "PNG");
verifyEqual(testCase, info.Resolution, 100);
verifyEqual(testCase, info.WidthPoints / info.HeightPoints, 2, ...
    "AbsTol", 1e-12);

imageInfo = imfinfo(pngFile);
verifyEqual(testCase, imageInfo.Width / imageInfo.Height, 2, ...
    "RelTol", 0.02);
verifyEqual(testCase, imageInfo.Width, 1400);
verifyEqual(testCase, imageInfo.Height, 700);
end

function testUsesRequestedResolution(testCase)
[pngFile, cleanupFolder] = temporaryPNG(); %#ok<ASGLU>
[renderContext, cleanupGraphics] = makeRenderContext(); %#ok<ASGLU>

info = spectralab.report.internal.exportPNG( ...
    pngFile, renderContext, Resolution=72);
imageInfo = imfinfo(pngFile);

verifyEqual(testCase, info.Resolution, 72);
verifyEqual(testCase, imageInfo.Width, 1008);
verifyEqual(testCase, imageInfo.Height, 504);
end

function testDoesNotOverwriteExistingPNG(testCase)
[pngFile, cleanupFolder] = temporaryPNG(); %#ok<ASGLU>
fid = fopen(pngFile, "w");
fwrite(fid, "existing");
fclose(fid);
[renderContext, cleanupGraphics] = makeRenderContext(); %#ok<ASGLU>

verifyError(testCase, @() ...
    spectralab.report.internal.exportPNG(pngFile, renderContext), ...
    "SpectraLab:Report:ReportFileAlreadyExists");
verifyEqual(testCase, string(fileread(pngFile)), "existing");
end

function testRejectsInvalidExtension(testCase)
folder = string(tempname);
mkdir(folder);
cleanupFolder = onCleanup(@() removeFolder(folder));
[renderContext, cleanupGraphics] = makeRenderContext(); %#ok<ASGLU>

verifyError(testCase, @() ...
    spectralab.report.internal.exportPNG( ...
        fullfile(folder, "figure.jpg"), renderContext), ...
    "SpectraLab:Report:InvalidPNGFile");
end

function testRejectsMissingGraphics(testCase)
[pngFile, cleanupFolder] = temporaryPNG(); %#ok<ASGLU>
[renderContext, cleanupGraphics] = makeRenderContext(); %#ok<ASGLU>
renderContext.Graphics.Axes = gobjects(0);

verifyError(testCase, @() ...
    spectralab.report.internal.exportPNG(pngFile, renderContext), ...
    "SpectraLab:Report:MissingReportFigure");
verifyFalse(testCase, isfile(pngFile));
end

function testRejectsMissingFigureModel(testCase)
[pngFile, cleanupFolder] = temporaryPNG(); %#ok<ASGLU>
[renderContext, cleanupGraphics] = makeRenderContext(); %#ok<ASGLU>
renderContext.State.RenderedElements = renderContext.State.RenderedElements([]);

verifyError(testCase, @() ...
    spectralab.report.internal.exportPNG(pngFile, renderContext), ...
    "SpectraLab:Report:MissingReportFigure");
verifyFalse(testCase, isfile(pngFile));
end

function testPreservesSourceGraphics(testCase)
[pngFile, cleanupFolder] = temporaryPNG(); %#ok<ASGLU>
[renderContext, cleanupGraphics] = makeRenderContext(); %#ok<ASGLU>
fig = renderContext.Graphics.Figure;
ax = renderContext.Graphics.Axes;
figurePosition = fig.Position;
axesPosition = ax.Position;
visibility = fig.Visible;
lineCount = numel(findall(ax, "Type", "line"));
figuresBefore = findall(groot, "Type", "figure");

spectralab.report.internal.exportPNG(pngFile, renderContext);

verifyTrue(testCase, isgraphics(fig, "figure"));
verifyTrue(testCase, isgraphics(ax, "axes"));
verifyEqual(testCase, fig.Position, figurePosition);
verifyEqual(testCase, ax.Position, axesPosition);
verifyEqual(testCase, fig.Visible, visibility);
verifyEqual(testCase, numel(findall(ax, "Type", "line")), lineCount);
verifyEqual(testCase, findall(groot, "Type", "figure"), figuresBefore);
end

function testPreservesVisibleSourceGraphics(testCase)
[pngFile, cleanupFolder] = temporaryPNG(); %#ok<ASGLU>
[renderContext, cleanupGraphics] = makeRenderContext(); %#ok<ASGLU>
fig = renderContext.Graphics.Figure;
ax = renderContext.Graphics.Axes;
fig.Visible = "on";
figure(fig);

spectralab.report.internal.exportPNG(pngFile, renderContext);

verifyTrue(testCase, isgraphics(fig, "figure"));
verifyTrue(testCase, isgraphics(ax, "axes"));
verifyEqual(testCase, string(fig.Visible), "on");
end

function testExportsSideInformationPanel(testCase)
[pngFile, cleanupFolder] = temporaryPNG(); %#ok<ASGLU>
[renderContext, cleanupGraphics] = makeRenderContext(); %#ok<ASGLU>
fig = renderContext.Graphics.Figure;
ax = renderContext.Graphics.Axes;
lineHandle = findall(ax, "Type", "line");
lineHandle.DisplayName = "Measured spectrum";
legend(ax, "Location", "eastoutside");
ax.Units = "normalized";
ax.Position = [0.06 0.12 0.60 0.80];
panel = axes("Parent", fig, "Units", "normalized", ...
    "Position", [0.70 0.22 0.26 0.56], "Visible", "off", ...
    "Tag", "SpectraLabFigureInformationPanel");
text(panel, 0, 1, "Correlated color temperature: 5000 K", ...
    "Units", "normalized", "VerticalAlignment", "top");

spectralab.report.internal.exportPNG(pngFile, renderContext);

verifyTrue(testCase, isfile(pngFile));
verifyGreaterThan(testCase, dir(pngFile).bytes, 1000);
verifyTrue(testCase, isgraphics(ax, "axes"));
end

function [renderContext, cleanup] = makeRenderContext()
fig = figure("Visible", "off", "Name", "Report source figure");
ax = axes("Parent", fig);
plot(ax, 380:10:730, sin((380:10:730)/45), "LineWidth", 1.5);
xlabel(ax, "Wavelength (nm)");
ylabel(ax, "Relative spectral power");
title(ax, "Measured spectrum");
grid(ax, "on");

model = struct( ...
    "Format", "SLAB-REPORT-FIGURE", ...
    "Version", "1.0", ...
    "Role", "primaryFigure", ...
    "Units", "points", ...
    "AspectRatio", 3/2, ...
    "WidthFraction", 0.8, ...
    "MaxHeight", 260, ...
    "Width", 432, ...
    "Height", 288);
record = struct( ...
    "Id", "Figure", ...
    "Type", "figure", ...
    "Role", "primaryFigure", ...
    "Content", model);

renderContext = struct( ...
    "Format", "SLAB-REPORT-RENDER-CONTEXT", ...
    "Version", "1.0", ...
    "Graphics", struct("Figure", fig, "Axes", ax), ...
    "TemporaryFiles", strings(0,1), ...
    "State", struct("RenderedElements", record));
cleanup = onCleanup(@() closeIfValid(fig));
end

function [pngFile, cleanup] = temporaryPNG()
folder = string(tempname);
mkdir(folder);
pngFile = fullfile(folder, "report_figure.png");
cleanup = onCleanup(@() removeFolder(folder));
end

function removeFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end

function closeIfValid(fig)
if isgraphics(fig, "figure")
    close(fig);
end
end
