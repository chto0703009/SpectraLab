function tests = test_report_analysisRegistry
%TEST_REPORT_ANALYSISREGISTRY Verify RP-020 analysis registry.

tests = functiontests(localfunctions);
end

function testCreatesRegistryWithMeasuredSpectrum(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();

verifyEqual(testCase, numel(registry), 8);
verifyEqual(testCase, ...
    [registry.AnalysisId], ...
    ["ANL-SPECTRUM", "ANL-CRI", "ANL-001", ...
     "ANL-002", "ANL-004", "ANL-005", ...
     "ANL-008", "ANL-007"]);
verifyEqual(testCase, ...
    [registry.Name], ...
    ["Measured Spectrum", "Color Rendering Index", ...
     "Transmission", "Optical Density", ...
     "White Density", "Status A Density", ...
     "Status M Density", "ISO Visual Density"]);
verifyEqual(testCase, registry(1).InputRoles, "Measurement");
verifyEqual(testCase, registry(2).InputRoles, "Measurement");
verifyEqual(testCase, registry(3).InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, registry(4).InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, registry(5).InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, registry(6).InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, registry(7).InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, registry(8).InputRoles, ["Reference", "Sample"]);
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

function testResolvesTransmission(testCase)

entry = spectralab.report.internal.resolveAnalysisSpecification("ANL-001");
definition = entry.DefinitionFactory();

verifyEqual(testCase, entry.InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, definition.AnalysisId, "ANL-001");
verifyTrue(testCase, definition.HasFigure);
verifyEqual(testCase, ...
    [definition.ResultFields.Field], ...
    ["SampleCount", "WavelengthMinimum", ...
     "WavelengthMaximum", "MeanTransmission"]);
end

function testTransmissionRunnerReturnsReportFields(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();
entry = registry([registry.AnalysisId] == "ANL-001");

reference = makeTransmissionArchive(ones(36,1), "Reference");
sample = makeTransmissionArchive(0.5 .* ones(36,1), "Sample");

result = entry.AnalysisRunner(reference, sample);

verifyEqual(testCase, result.SampleCount, 36);
verifyEqual(testCase, result.WavelengthMinimum, 380);
verifyEqual(testCase, result.WavelengthMaximum, 730);
verifyEqual(testCase, result.MeanTransmission, 0.5, AbsTol=1e-12);
verifyTrue(testCase, isfield(result, "TransmissionAnalysis"));
end

function testResolvesOpticalDensity(testCase)

entry = spectralab.report.internal.resolveAnalysisSpecification("ANL-002");
definition = entry.DefinitionFactory();

verifyEqual(testCase, entry.InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, definition.AnalysisId, "ANL-002");
verifyTrue(testCase, definition.HasFigure);
verifyEqual(testCase, ...
    [definition.ResultFields.Field], ...
    ["SampleCount", "WavelengthMinimum", ...
     "WavelengthMaximum", "MeanDensity"]);
end

function testOpticalDensityRunnerReturnsReportFields(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();
entry = registry([registry.AnalysisId] == "ANL-002");

reference = makeTransmissionArchive(ones(36,1), "Reference");
sample = makeTransmissionArchive(0.1 .* ones(36,1), "Sample");

result = entry.AnalysisRunner(reference, sample);

verifyEqual(testCase, result.SampleCount, 36);
verifyEqual(testCase, result.WavelengthMinimum, 380);
verifyEqual(testCase, result.WavelengthMaximum, 730);
verifyEqual(testCase, result.MeanDensity, 1, AbsTol=1e-12);
verifyEqual(testCase, result.Density, ones(36,1), AbsTol=1e-12);
verifyTrue(testCase, isfield(result, "TransmissionAnalysis"));
end

function testResolvesWhiteDensity(testCase)

entry = spectralab.report.internal.resolveAnalysisSpecification("ANL-004");
definition = entry.DefinitionFactory();

verifyEqual(testCase, entry.InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, definition.AnalysisId, "ANL-004");
verifyFalse(testCase, definition.HasFigure);
verifyEqual(testCase, ...
    [definition.ResultFields.Field], ...
    ["Density", "Transmittance"]);
end

function testWhiteDensityRunnerReturnsReportFields(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();
entry = registry([registry.AnalysisId] == "ANL-004");

reference = makeTransmissionArchive(ones(36,1), "Reference");
sample = makeTransmissionArchive(0.1 .* ones(36,1), "Sample");

result = entry.AnalysisRunner(reference, sample);

verifyEqual(testCase, result.Density, 1, AbsTol=1e-12);
verifyEqual(testCase, result.Transmittance, 0.1, AbsTol=1e-12);
end

function testResolvesStatusADensity(testCase)

entry = spectralab.report.internal.resolveAnalysisSpecification("ANL-005");
definition = entry.DefinitionFactory();

verifyEqual(testCase, entry.InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, definition.AnalysisId, "ANL-005");
verifyFalse(testCase, definition.HasFigure);
verifyEqual(testCase, ...
    [definition.ResultFields.Field], ...
    ["RedDensity", "GreenDensity", "BlueDensity", ...
     "RedTransmittance", "GreenTransmittance", ...
     "BlueTransmittance"]);
end

function testStatusADensityRunnerReturnsReportFields(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();
entry = registry([registry.AnalysisId] == "ANL-005");

reference = makeTransmissionArchive(ones(36,1), "Reference");
sample = makeTransmissionArchive(0.1 .* ones(36,1), "Sample");

result = entry.AnalysisRunner(reference, sample);

verifyEqual(testCase, ...
    [result.RedDensity, result.GreenDensity, result.BlueDensity], ...
    [1, 1, 1], ...
    AbsTol=1e-12);

verifyEqual(testCase, ...
    [result.RedTransmittance, ...
     result.GreenTransmittance, ...
     result.BlueTransmittance], ...
    [0.1, 0.1, 0.1], ...
    AbsTol=1e-12);
end

function testResolvesStatusMDensity(testCase)

entry = spectralab.report.internal.resolveAnalysisSpecification("ANL-008");
definition = entry.DefinitionFactory();

verifyEqual(testCase, entry.InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, definition.AnalysisId, "ANL-008");
verifyFalse(testCase, definition.HasFigure);
verifyEqual(testCase, ...
    [definition.ResultFields.Field], ...
    ["RedDensity", "GreenDensity", "BlueDensity", ...
     "RedTransmittance", "GreenTransmittance", ...
     "BlueTransmittance"]);
end

function testStatusMDensityRunnerReturnsReportFields(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();
entry = registry([registry.AnalysisId] == "ANL-008");

reference = makeTransmissionArchive(ones(36,1), "Reference");
sample = makeTransmissionArchive(0.1 .* ones(36,1), "Sample");

result = entry.AnalysisRunner(reference, sample);

verifyEqual(testCase, ...
    [result.RedDensity, result.GreenDensity, result.BlueDensity], ...
    [1, 1, 1], ...
    AbsTol=1e-12);

verifyEqual(testCase, ...
    [result.RedTransmittance, ...
     result.GreenTransmittance, ...
     result.BlueTransmittance], ...
    [0.1, 0.1, 0.1], ...
    AbsTol=1e-12);
end

function testResolvesIsoVisualDensity(testCase)

entry = spectralab.report.internal.resolveAnalysisSpecification("ANL-007");
definition = entry.DefinitionFactory();

verifyEqual(testCase, entry.InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, definition.AnalysisId, "ANL-007");
verifyFalse(testCase, definition.HasFigure);
verifyEqual(testCase, ...
    [definition.ResultFields.Field], ...
    ["Density", "Transmittance"]);
end

function testIsoVisualDensityRunnerReturnsReportFields(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();
entry = registry([registry.AnalysisId] == "ANL-007");

reference = makeTransmissionArchive(ones(36,1), "Reference");
sample = makeTransmissionArchive(0.1 .* ones(36,1), "Sample");

result = entry.AnalysisRunner(reference, sample);

verifyEqual(testCase, result.Density, 1, AbsTol=1e-12);
verifyEqual(testCase, result.Transmittance, 0.1, AbsTol=1e-12);
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

function archive = makeTransmissionArchive(power, name)

wavelength = (380:10:730).';

spec = spectralab.core.Spectrum( ...
    wavelength, ...
    power(:), ...
    name, ...
    struct("Name", "X-Rite i1Pro 2"), ...
    struct(), ...
    struct(), ...
    "relative");

archive = spectralab.archive.create(spec);
end
