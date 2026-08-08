function tests = test_report_pdfBackend
%TEST_REPORT_PDFBACKEND Verify RP-012 minimal PDF export.

tests = functiontests(localfunctions);
end

function teardown(~)
close all force
end

function testExportsSinglePagePDF(testCase)
[pdfFile, cleanup] = temporaryPDF(); %#ok<ASGLU>
[plan, renderContext] = makeReport(false);
figuresBefore = findall(groot, "Type", "figure");

info = spectralab.report.internal.exportPDF( ...
    pdfFile, plan, renderContext);

verifyTrue(testCase, isfile(pdfFile));
fileInfo = dir(pdfFile);
verifyGreaterThan(testCase, fileInfo.bytes, 500);
verifyEqual(testCase, info.PageCount, 1);
verifyEqual(testCase, info.PageSize, "A4");
verifyEqual(testCase, info.Orientation, "portrait");
verifyEqual(testCase, findall(groot, "Type", "figure"), figuresBefore);
end

function testExportsMultiplePages(testCase)
[pdfFile, cleanup] = temporaryPDF(); %#ok<ASGLU>
[plan, renderContext] = makeReport(true);

info = spectralab.report.internal.exportPDF( ...
    pdfFile, plan, renderContext);

verifyTrue(testCase, isfile(pdfFile));
verifyEqual(testCase, info.PageCount, 2);
end

function testOmitsSideInformationPanelFromPDF(testCase)
[pdfFile, cleanup] = temporaryPDF(); %#ok<ASGLU>
[plan, renderContext] = makeReport(false);
sourceFigure = renderContext.Graphics.Figure;
sourceAxes = renderContext.Graphics.Axes;
lineHandle = findall(sourceAxes, "Type", "line");
lineHandle.DisplayName = "Long source label for right-side wrapping";
legend(sourceAxes, "Location", "eastoutside");
panel = axes("Parent", sourceFigure, "Units", "normalized", ...
    "Position", [0.72 0.22 0.24 0.42], "Visible", "off", ...
    "Tag", "SpectraLabFigureInformationPanel");
text(panel, 0, 1, "Maximum absolute\ndifference: 0.001", ...
    "Units", "normalized", "VerticalAlignment", "top");

info = spectralab.report.internal.exportPDF(pdfFile, plan, renderContext);

verifyTrue(testCase, isfile(pdfFile));
verifyGreaterThan(testCase, dir(pdfFile).bytes, 500);
verifyEqual(testCase, info.PageCount, 1);
end

function testDoesNotOverwriteExistingPDF(testCase)
[pdfFile, cleanup] = temporaryPDF(); %#ok<ASGLU>
fid = fopen(pdfFile, "w");
fwrite(fid, "existing");
fclose(fid);
[plan, renderContext] = makeReport(false);

verifyError(testCase, @() ...
    spectralab.report.internal.exportPDF(pdfFile, plan, renderContext), ...
    "SpectraLab:Report:ReportFileAlreadyExists");
verifyEqual(testCase, string(fileread(pdfFile)), "existing");
end

function testRejectsUnmeasuredElement(testCase)
[pdfFile, cleanup] = temporaryPDF(); %#ok<ASGLU>
[plan, renderContext] = makeReport(false);
plan(1).Measured = false;
plan(1).Height = NaN;

verifyError(testCase, @() ...
    spectralab.report.internal.exportPDF(pdfFile, plan, renderContext), ...
    "SpectraLab:Report:UnmeasuredPDFElement");
verifyFalse(testCase, isfile(pdfFile));
end

function testRejectsUnsupportedElement(testCase)
[pdfFile, cleanup] = temporaryPDF(); %#ok<ASGLU>
[plan, renderContext] = makeReport(false);
renderContext.State.RenderedElements(1).Type = "list";

verifyError(testCase, @() ...
    spectralab.report.internal.exportPDF(pdfFile, plan, renderContext), ...
    "SpectraLab:Report:UnsupportedPDFElement");
verifyFalse(testCase, isfile(pdfFile));
end

function testRejectsMissingFigureGraphics(testCase)
[pdfFile, cleanup] = temporaryPDF(); %#ok<ASGLU>
[plan, renderContext] = makeReport(false);
renderContext.Graphics = struct("Figure", gobjects(0), "Axes", gobjects(0));

verifyError(testCase, @() ...
    spectralab.report.internal.exportPDF(pdfFile, plan, renderContext), ...
    "SpectraLab:Report:MissingFigureGraphics");
verifyFalse(testCase, isfile(pdfFile));
end

function [plan, renderContext] = makeReport(twoPages)
records = [ ...
    record("Title", "heading", "reportTitle", "SpectraLab Report")
    record("Results", "table", "analysisResults", resultTable())
    record("Figure", "figure", "primaryFigure", figureModel())];

plan = [ ...
    placement("Title", "heading", 1, 0, 28)
    placement("Results", "table", 1, 36, 62)
    placement("Figure", "figure", 1, 110, 180)];

if twoPages
    plan(3).Page = 2;
    plan(3).Y = 0;
end

sourceFigure = figure("Visible", "off");
sourceAxes = axes(sourceFigure);
plot(sourceAxes, [380 555 730], [0 1 0.2], "LineWidth", 1.0);
xlabel(sourceAxes, "Wavelength (nm)");
ylabel(sourceAxes, "Relative spectral power");
title(sourceAxes, "Measured spectrum");

renderContext = struct( ...
    "Format", "SLAB-REPORT-RENDER-CONTEXT", ...
    "Version", "1.0", ...
    "Graphics", struct("Figure", sourceFigure, "Axes", sourceAxes), ...
    "PageFrame", pageFrame(), ...
    "TemporaryFiles", strings(0,1), ...
    "State", struct("RenderedElements", records));
end

function model = pageFrame()
model = struct( ...
    "Format", "SLAB-REPORT-PAGE-FRAME", ...
    "Version", "1.0", ...
    "HeaderLeft", "SpectraLab", ...
    "HeaderRight", "Color Rendering Index", ...
    "FooterLeft", "Report ID RPT-001", ...
    "FooterCenter", "SpectraLab 0.8.0-test");
end


function item = record(id, type, role, content)
item = struct("Id", string(id), "Type", string(type), ...
    "Role", string(role), "Content", content);
end

function item = placement(id, type, page, y, height)
item = struct( ...
    "ElementId", string(id), ...
    "ElementType", string(type), ...
    "Page", double(page), ...
    "Y", double(y), ...
    "Height", double(height), ...
    "Measured", true, ...
    "ExplicitPageBreak", false, ...
    "AutomaticPageBreak", false);
end

function model = resultTable()
rows = [ ...
    row("CCT", "5045 K")
    row("Duv", "+0.00482")
    row("Ra", "95.4")];
model = struct("Format", "SLAB-REPORT-TABLE", "Version", "1.0", ...
    "Columns", ["Label", "Value"], "Rows", rows);
end

function item = row(label, displayText)
item = struct("Field", string(label), "Label", string(label), ...
    "Value", 0, "Unit", "", "Format", "", ...
    "DisplayValue", string(displayText), ...
    "DisplayText", string(displayText));
end

function model = figureModel()
model = struct("Format", "SLAB-REPORT-FIGURE", "Version", "1.0", ...
    "Role", "primaryFigure", "Units", "points", ...
    "AspectRatio", 3/2, "WidthFraction", 0.8, ...
    "MaxHeight", 260, "Width", 360, "Height", 240);
end

function [pdfFile, cleanup] = temporaryPDF()
folder = string(tempname);
mkdir(folder);
pdfFile = fullfile(folder, "report.pdf");
cleanup = onCleanup(@() removeFolder(folder));
end

function removeFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
