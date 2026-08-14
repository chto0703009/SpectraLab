function tests = test_report_spectralPairAnalyses
%TEST_REPORT_SPECTRALPAIRANALYSES ANL-009 and ANL-010 report contracts.
tests = functiontests(localfunctions);
end

function setup(testCase)
folder = string(tempname);
mkdir(folder);
testCase.TestData.Folder = folder;
testCase.addTeardown(@() rmdir(folder, "s"));
end

function testMeanReportNamesBothSourceFiles(testCase)
[firstFile, secondFile] = createSources(testCase.TestData.Folder);
outputFolder = fullfile(testCase.TestData.Folder, "mean-report");
info = spectralab.report.generate( ...
    [firstFile, secondFile], "ANL-009", outputFolder, ...
    DerivedArchiveFile=fullfile(testCase.TestData.Folder, "mean_result.mat"));

verifyTrue(testCase, isfile(info.PDFFile));
verifyTrue(testCase, isfile(info.PNGFile));
verifyEqual(testCase, info.InputRoles, ["Source A", "Source B"]);
verifyEqual(testCase, info.Context.Result.SourceAFile, "first.mat");
verifyEqual(testCase, info.Context.Result.SourceBFile, "second.mat");
verifyEqual(testCase, info.Context.Result.SourceFiles, ...
    ["first.mat", "second.mat"]);
verifyEqual(testCase, info.Context.Result.SourceFilesText, ...
    "first.mat"+newline+"second.mat");
verifyEqual(testCase, info.Context.Result.DerivedArchiveFile, ...
    "mean_result.mat");
verifyEqual(testCase, info.Context.Result.Value, [2; 4; 6; 8]);
verifyTrue(testCase, ...
    spectralab.archive.validate(info.Context.Result.DerivedArchive).IsValid);
verifyEqual(testCase, [info.Context.SourceArchives.Filename], ...
    ["first.mat", "second.mat"]);

measurementTable = spectralab.report.internal.buildKeyValueTable( ...
    "measurementInformation", info.Context);
verifyTrue(testCase, any([measurementTable.Rows.Label] == ...
    "Source A measurement"));
verifyTrue(testCase, any([measurementTable.Rows.Label] == ...
    "Source B measurement"));

provenanceTable = spectralab.report.internal.buildKeyValueTable( ...
    "provenance", info.Context);
verifyTrue(testCase, any([provenanceTable.Rows.Label] == ...
    "Source A archive"));
verifyTrue(testCase, any([provenanceTable.Rows.Label] == ...
    "Source B archive"));
verifyTrue(testCase, any([provenanceTable.Rows.Label] == ...
    "Source A instrument"));
verifyTrue(testCase, any([provenanceTable.Rows.Label] == ...
    "Source B instrument"));
verifyTrue(testCase, any([provenanceTable.Rows.Label] == ...
    "Source A instrument serial number"));
verifyTrue(testCase, any([provenanceTable.Rows.Label] == ...
    "Source B instrument serial number"));
labels = [provenanceTable.Rows.Label];
verifyEqual(testCase, ...
    find(labels == "Source A instrument serial number", 1), ...
    find(labels == "Source A instrument", 1) + 1);
verifyEqual(testCase, ...
    find(labels == "Source B instrument serial number", 1), ...
    find(labels == "Source B instrument", 1) + 1);
end

function testDifferenceReportIsSignedAndCreatesNoMat(testCase)
[firstFile, secondFile] = createSources(testCase.TestData.Folder);
outputFolder = fullfile(testCase.TestData.Folder, "difference-report");
info = spectralab.report.generate( ...
    [firstFile, secondFile], "ANL-010", outputFolder);

verifyTrue(testCase, isfile(info.PDFFile));
verifyTrue(testCase, isfile(info.PNGFile));
verifyEqual(testCase, info.InputRoles, ...
    ["Minuend (A)", "Subtrahend (B)"]);
verifyEqual(testCase, info.Context.Result.Value, [-2; -4; -6; -8]);
verifyFalse(testCase, isfield(info.Context.Result, "DerivedArchive"));
verifyEmpty(testCase, dir(fullfile(outputFolder, "*.mat")));
verifyEqual(testCase, [info.Context.SourceArchives.Filename], ...
    ["first.mat", "second.mat"]);
end

function testMeanReportDocumentsEverySelectedSource(testCase)
[firstFile, secondFile] = createSources(testCase.TestData.Folder);
thirdFile = fullfile(testCase.TestData.Folder, "third.mat");
saveArchive(thirdFile, [5; 10; 15; 20], "Third");
outputFolder = fullfile(testCase.TestData.Folder, "multi-mean-report");

info = spectralab.report.generate( ...
    [firstFile, secondFile, thirdFile], "ANL-009", outputFolder);

verifyEqual(testCase, info.InputRoles, ...
    ["Source 1", "Source 2", "Source 3"]);
verifyEqual(testCase, info.Context.Result.SourceCount, 3);
verifyEqual(testCase, info.Context.Result.SourceFiles, ...
    ["first.mat", "second.mat", "third.mat"]);
verifyEqual(testCase, info.Context.Result.SourceFilesText, ...
    "first.mat"+newline+"second.mat"+newline+"third.mat");
verifyEqual(testCase, info.Context.Result.Value, [3; 6; 9; 12]);
verifyEqual(testCase, info.Context.Result.StandardDeviation, [2; 4; 6; 8]);
verifyEqual(testCase, info.Context.Result.RMSDifference, ...
    sqrt(mean([4; 16; 36; 64] * 2 / 3)), AbsTol=1e-12);
verifyEqual(testCase, info.Context.Result.RMSDifferencePercent, ...
    100 * sqrt(20) / sqrt(mean([3; 6; 9; 12].^2)), AbsTol=1e-12);
verifyEqual(testCase, [info.Context.SourceArchives.Filename], ...
    ["first.mat", "second.mat", "third.mat"]);
provenance = spectralab.report.internal.buildKeyValueTable( ...
    "provenance", info.Context);
labels = [provenance.Rows.Label];
verifyTrue(testCase, any(labels == "Source 1 archive"));
verifyTrue(testCase, any(labels == "Source 2 archive"));
verifyTrue(testCase, any(labels == "Source 3 archive"));
verifyTrue(testCase, isfile(info.PDFFile));
verifyTrue(testCase, isfile(info.PNGFile));
end

function testDifferenceFigureUsesZeroAxisAndSymmetricLimits(testCase)
[firstFile, secondFile] = createSources(testCase.TestData.Folder);
firstArchive = spectralab.archive.load(firstFile, Quiet=true);
secondArchive = spectralab.archive.load(secondFile, Quiet=true);
registry = spectralab.report.internal.createAnalysisRegistry();
ids = arrayfun(@(entry) entry.AnalysisDefinition.AnalysisId, registry);
entry = registry(ids == "ANL-010");
result = entry.AnalysisRunner(firstArchive, secondArchive);

fig = figure("Visible", "off");
cleanup = onCleanup(@() close(fig));
ax = axes(fig);
entry.FigureRenderer(ax, firstArchive, secondArchive, result);

maximumAbsoluteDifference = max(abs(result.Value));
expectedLimit = maximumAbsoluteDifference + ...
    0.05 * maximumAbsoluteDifference;
verifyEqual(testCase, string(ax.XAxisLocation), "origin");
verifyEqual(testCase, ax.YLim, [-expectedLimit, expectedLimit], ...
    AbsTol=1e-12);
verifyEqual(testCase, result.RMSDifference, sqrt(30), AbsTol=1e-12);
verifyEqual(testCase, result.MaximumAbsoluteDifference, 8);
verifyEqual(testCase, numel(findall(ax, ...
    "Tag", "SpectraLabSpectralColorBar")), 1);
summary = findall(ancestor(ax, "figure"), "Type", "text", ...
    "Tag", "SpectraLabDifferenceSummary");
verifyEqual(testCase, numel(summary), 1);
verifyTrue(testCase, any(contains( ...
    string(summary.String), "RMS difference")));
differenceLine = findobj(ax, "Type", "line", "-property", "DisplayName");
verifyEqual(testCase, string(differenceLine.DisplayName), ...
    result.SourceAFile + " - " + result.SourceBFile);
end

function testMeanFigureStartsAtZeroAndUses105PercentMaximum(testCase)
[firstFile, secondFile] = createSources(testCase.TestData.Folder);
firstArchive = spectralab.archive.load(firstFile, Quiet=true);
secondArchive = spectralab.archive.load(secondFile, Quiet=true);
registry = spectralab.report.internal.createAnalysisRegistry();
ids = arrayfun(@(entry) entry.AnalysisDefinition.AnalysisId, registry);
entry = registry(ids == "ANL-009");
result = entry.AnalysisRunner(firstArchive, secondArchive);

fig = figure("Visible", "off");
cleanup = onCleanup(@() close(fig));
ax = axes(fig);
entry.FigureRenderer(ax, firstArchive, secondArchive, result);

maximumDisplayedValue = max([result.Value; ...
    firstArchive.Measurement.Value(:); secondArchive.Measurement.Value(:)]);
verifyEqual(testCase, ax.YLim, [0, 1.05 * maximumDisplayedValue], ...
    AbsTol=1e-12);
verifyEqual(testCase, numel(findall(ax, ...
    "Tag", "SpectraLabSpectralColorBar")), 1);
summary = findall(ancestor(ax, "figure"), "Type", "text", ...
    "Tag", "SpectraLabMeanStabilitySummary");
verifyEqual(testCase, numel(summary), 1);
verifyEqual(testCase, join(string(summary.String), " "), ...
    "RMS difference: 2.73861 arbitrary (50.000 %)");
lines = findobj(ax, "Type", "line", "-property", "DisplayName");
displayNames = string(get(lines, "DisplayName"));
verifyTrue(testCase, any(displayNames == ...
    "Source A: " + result.SourceAFile));
verifyTrue(testCase, any(displayNames == ...
    "Source B: " + result.SourceBFile));
end

function [firstFile, secondFile] = createSources(folder)
firstFile = fullfile(folder, "first.mat");
secondFile = fullfile(folder, "second.mat");
saveArchive(firstFile, [1; 2; 3; 4], "First");
saveArchive(secondFile, [3; 6; 9; 12], "Second");
end

function saveArchive(filename, value, name)
wavelength = [400; 500; 600; 700];
spec = spectralab.core.Spectrum(wavelength, value, name, ...
    struct("Name", "Test instrument"), struct(), ...
    struct("Operator", "Test"), "arbitrary");
spectralab.archive.save(spectralab.archive.create(spec), filename);
end
