function tests = test_report_analysisRegistry
%TEST_REPORT_ANALYSISREGISTRY Verify RP-020 analysis registry.

tests = functiontests(localfunctions);
end

function testCreatesRegistryWithMeasuredSpectrum(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();

verifyEqual(testCase, numel(registry), 2);
verifyEqual(testCase, ...
    [registry.AnalysisId], ...
    ["ANL-SPECTRUM", "ANL-CRI"]);
verifyEqual(testCase, ...
    [registry.Name], ...
    ["Measured Spectrum", "Color Rendering Index"]);
verifyTrue(testCase, all(arrayfun(@(x) ...
    isa(x.AnalysisRunner, "function_handle"), registry)));
verifyTrue(testCase, all(arrayfun(@(x) ...
    isa(x.FigureRenderer, "function_handle"), registry)));
verifyTrue(testCase, all(arrayfun(@(x) ...
    isa(x.DefinitionFactory, "function_handle"), registry)));
end

function testAnalysisIdsAreUnique(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();

verifyEqual(testCase, ...
    numel(unique([registry.AnalysisId])), ...
    numel(registry));
end

function testResolvesMeasuredSpectrum(testCase)

entry = spectralab.report.internal.resolveAnalysisSpecification( ...
    "ANL-SPECTRUM");

verifyEqual(testCase, entry.AnalysisId, "ANL-SPECTRUM");

definition = entry.DefinitionFactory();

verifyEqual(testCase, definition.AnalysisId, "ANL-SPECTRUM");
verifyTrue(testCase, definition.HasFigure);
verifyEqual(testCase, ...
    [definition.ResultFields.Field], ...
    ["SampleCount", "WavelengthMinimum", "WavelengthMaximum"]);
end

function testResolvesCri(testCase)

entry = spectralab.report.internal.resolveAnalysisSpecification( ...
    "ANL-CRI");

verifyEqual(testCase, entry.AnalysisId, "ANL-CRI");

definition = entry.DefinitionFactory();

verifyEqual(testCase, definition.AnalysisId, "ANL-CRI");
verifyTrue(testCase, definition.HasFigure);
verifyEqual(testCase, ...
    [definition.ResultFields.Field], ...
    ["CCT", "Duv", "Ra"]);
verifyEqual(testCase, definition.Method, "CIE 13.3");
end

function testCriRunnerReturnsReportFields(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();
entry = registry([registry.AnalysisId] == "ANL-CRI");

archive = makeCriArchive();
result = entry.AnalysisRunner(archive);

verifyTrue(testCase, isfield(result, "CCT"));
verifyTrue(testCase, isfield(result, "Duv"));
verifyTrue(testCase, isfield(result, "Ra"));
verifyTrue(testCase, isfinite(result.CCT));
verifyTrue(testCase, isfinite(result.Duv));
verifyTrue(testCase, isfinite(result.Ra));
end

function testUnknownAnalysisIdIsRejected(testCase)

verifyError(testCase, @() ...
    spectralab.report.internal.resolveAnalysisSpecification( ...
        "ANL-UNKNOWN"), ...
    "SpectraLab:Report:UnknownAnalysisId");
end

function testDuplicateAnalysisIdIsRejected(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();
registry = [registry; registry];

verifyError(testCase, @() ...
    spectralab.report.internal.resolveAnalysisSpecification( ...
        "ANL-SPECTRUM", registry), ...
    "SpectraLab:Report:DuplicateAnalysisId");
end

function archive = makeCriArchive()

wavelength = (380:10:730).';
power = 0.2 + ...
    0.6 * exp(-0.5 * ((wavelength - 455) / 25).^2) + ...
    0.9 * exp(-0.5 * ((wavelength - 545) / 45).^2) + ...
    0.5 * exp(-0.5 * ((wavelength - 610) / 35).^2);

spec = spectralab.core.Spectrum( ...
    wavelength, ...
    power, ...
    "CRI registry test", ...
    struct("Name", "X-Rite i1Pro 2"), ...
    struct(), ...
    struct(), ...
    "relative");

archive = spectralab.archive.create(spec);
end
