function tests = test_report_analysisRegistry
%TEST_REPORT_ANALYSISREGISTRY Verify RP-020 analysis registry.

tests = functiontests(localfunctions);
end

function testCreatesRegistryWithMeasuredSpectrum(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();
analysisIds = registryAnalysisIds(registry);
analysisNames = strings(1, numel(registry));

for k = 1:numel(registry)
    analysisNames(k) = registry(k).AnalysisDefinition.Name;
end

verifyEqual(testCase, numel(registry), 10);
verifyEqual(testCase, ...
    analysisIds, ...
    ["ANL-SPECTRUM", "ANL-CRI", "ANL-001", ...
     "ANL-002", "ANL-009", "ANL-010", "ANL-004", "ANL-005", ...
     "ANL-008", "ANL-007"]);
verifyEqual(testCase, ...
    analysisNames, ...
    ["Measured Spectrum", "Color Rendering Index", ...
     "Transmission", "Optical Density", "Spectral Mean", ...
     "Spectral Difference", ...
     "White Density", "Status A Density", ...
     "Status M Density", "ISO Visual Density"]);
verifyEqual(testCase, registry(1).InputRoles, "Measurement");
verifyEqual(testCase, registry(2).InputRoles, "Measurement");
verifyEqual(testCase, registry(3).InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, registry(4).InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, registry(5).InputRoles, ["Source A", "Source B"]);
verifyEqual(testCase, registry(6).InputRoles, ...
    ["Minuend (A)", "Subtrahend (B)"]);
verifyEqual(testCase, registry(7).InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, registry(8).InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, registry(9).InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, registry(10).InputRoles, ["Reference", "Sample"]);
verifyTrue(testCase, all(arrayfun(@(x) ...
    isa(x.AnalysisRunner, "function_handle"), registry)));
verifyTrue(testCase, all(arrayfun(@(x) ...
    x.AnalysisDefinition.HasFigure == ...
    isa(x.FigureRenderer, "function_handle"), registry)));
verifyFalse(testCase, isfield(registry, "DefinitionFactory"));
verifyFalse(testCase, isfield(registry, "AnalysisId"));
verifyFalse(testCase, isfield(registry, "Name"));
end

function testAnalysisIdsAreUnique(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();

verifyEqual(testCase, ...
    numel(unique(registryAnalysisIds(registry))), ...
    numel(registry));
end

function testResolvesMeasuredSpectrum(testCase)

entry = spectralab.report.internal.resolveAnalysisSpecification( ...
    "ANL-SPECTRUM");

verifyEqual(testCase, ...
    entry.AnalysisDefinition.AnalysisId, ...
    "ANL-SPECTRUM");

definition = entry.AnalysisDefinition;

verifyEqual(testCase, definition.AnalysisId, "ANL-SPECTRUM");
verifyTrue(testCase, definition.HasFigure);
verifyEqual(testCase, ...
    [definition.ResultFields.Field], ...
    ["SampleCount", "WavelengthMinimum", "WavelengthMaximum", ...
     "ColorimetrySource", "XYZText", "LabText", "VerificationText"]);
end

function testResolvesCri(testCase)

entry = spectralab.report.internal.resolveAnalysisSpecification( ...
    "ANL-CRI");

verifyEqual(testCase, entry.AnalysisDefinition.AnalysisId, "ANL-CRI");

definition = entry.AnalysisDefinition;

verifyEqual(testCase, definition.AnalysisId, "ANL-CRI");
verifyTrue(testCase, definition.HasFigure);
verifyEqual(testCase, ...
    [definition.ResultFields.Field], ...
    ["CCT", "Duv", "Ra"]);
verifyEqual(testCase, definition.Method, "CIE 13.3");
end

function testCriRunnerReturnsReportFields(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();
entry = findEntry(registry, "ANL-CRI");

archive = makeCriArchive();
result = entry.AnalysisRunner(archive);

verifyTrue(testCase, isfield(result, "CCT"));
verifyTrue(testCase, isfield(result, "Duv"));
verifyTrue(testCase, isfield(result, "Ra"));
verifyTrue(testCase, isfinite(result.CCT));
verifyTrue(testCase, isfinite(result.Duv));
verifyTrue(testCase, isfinite(result.Ra));
end

function testSpectrumReportFiguresPlaceLegendsOutsidePlot(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();
archive = makeCriArchive();

for analysisId = ["ANL-SPECTRUM", "ANL-CRI"]
    entry = findEntry(registry, analysisId);
    fig = figure("Visible", "off");
    cleanup = onCleanup(@() close(fig));
    ax = axes("Parent", fig);

    result = struct();
    if analysisId == "ANL-CRI"
        result = entry.AnalysisRunner(archive);
    end
    entry.FigureRenderer(ax, archive, result);

    verifyEmpty(testCase, findall(ax, "Tag", "SpectraLabSummary"));
    legendHandle = findall(fig, "Type", "legend");
    verifyNotEmpty(testCase, legendHandle);
    titleText = string(ax.Title.String);
    verifyTrue(testCase, contains(join(titleText, newline), ...
        string(archive.Measurement.Name)));

    if analysisId == "ANL-CRI"
        profile = spectralab.report.internal.figureLayoutProfile();
        verifyEqual(testCase, string(legendHandle.Location), "none");
        summary = findall(fig, "Tag", "SpectraLabCriSummary");
        verifyNotEmpty(testCase, summary);
        summaryText = replace(join(string(summary.String), newline), newline, " ");
        verifyTrue(testCase, contains(summaryText, ...
            "Correlated color temperature"));
        verifyTrue(testCase, contains(summaryText, "CRI (Ra)"));
        verifyEqual(testCase, ax.Position, profile.AxesWithSidebar, ...
            "AbsTol", 1e-12);
        informationPanel = findall(fig, "Type", "axes", ...
            "Tag", "SpectraLabFigureInformationPanel");
        verifyEqual(testCase, informationPanel.Position, profile.SidePanel, ...
            "AbsTol", 1e-12);
        verifyEqual(testCase, legendHandle.Position, profile.SideLegend, ...
            "AbsTol", 1e-12);
    else
        verifyEqual(testCase, string(legendHandle.Location), "eastoutside");
    end

    clear cleanup
end
end

function testReflectanceFigureKeepsColorimetryOutOfPlot(testCase)
registry = spectralab.report.internal.createAnalysisRegistry();
entry = findEntry(registry, "ANL-SPECTRUM");
archive = makeCriArchive();
archive.Measurement.Unit = "relative reflectance (%)";
archive.Measurement.Context = struct( ...
    "InstrumentReportedColorimetry", struct( ...
        "available", true, ...
        "xyz", [55.309789 56.724391 5.550868], ...
        "lab", [80.024327 1.547991 84.210804], ...
        "illuminant", "D50", ...
        "observer", "1931_2"));
payload = struct("Measurement", archive.Measurement, ...
    "Instrument", archive.Instrument, "Quality", archive.Quality);
archive.Identity.ContentHash = spectralab.archive.contentHash(payload);
fig = figure("Visible", "off");
cleanup = onCleanup(@() close(fig));
ax = axes("Parent", fig);
result = entry.AnalysisRunner(archive);
entry.FigureRenderer(ax, archive, result);

panelText = findall(fig, "Tag", "SpectraLabReflectanceColorimetry");
verifyEmpty(testCase, panelText);
verifyEqual(testCase, result.XYZText, "XYZ: 55.310, 56.724, 5.551");
verifyEqual(testCase, result.LabText, "Lab: 80.024, 1.548, 84.211");
verifyTrue(testCase, contains(textValue, "Lab: 80.024, 1.548, 84.211"));
end

function testResolvesTransmission(testCase)

entry = spectralab.report.internal.resolveAnalysisSpecification("ANL-001");
definition = entry.AnalysisDefinition;

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
entry = findEntry(registry, "ANL-001");

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
definition = entry.AnalysisDefinition;

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
entry = findEntry(registry, "ANL-002");

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
definition = entry.AnalysisDefinition;

verifyEqual(testCase, entry.InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, definition.AnalysisId, "ANL-004");
verifyFalse(testCase, definition.HasFigure);
verifyEqual(testCase, ...
    [definition.ResultFields.Field], ...
    ["Density", "Transmittance"]);
end

function testWhiteDensityRunnerReturnsReportFields(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();
entry = findEntry(registry, "ANL-004");

reference = makeTransmissionArchive(ones(36,1), "Reference");
sample = makeTransmissionArchive(0.1 .* ones(36,1), "Sample");

result = entry.AnalysisRunner(reference, sample);

verifyEqual(testCase, result.Density, 1, AbsTol=1e-12);
verifyEqual(testCase, result.Transmittance, 0.1, AbsTol=1e-12);
end

function testResolvesStatusADensity(testCase)

entry = spectralab.report.internal.resolveAnalysisSpecification("ANL-005");
definition = entry.AnalysisDefinition;

verifyEqual(testCase, entry.InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, definition.AnalysisId, "ANL-005");
verifyFalse(testCase, definition.HasFigure);
verifyEqual(testCase, ...
    [definition.ResultFields.Field], ...
    ["RedDensity", "GreenDensity", "BlueDensity", ...
     "WhiteDensity", ...
     "RedTransmittance", "GreenTransmittance", ...
     "BlueTransmittance", "WhiteTransmittance"]);
verifyEqual(testCase, ...
    string({definition.ResultFields(5:8).Format}), ...
    repmat("%.4f", 1, 4));
end

function testStatusADensityRunnerReturnsReportFields(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();
entry = findEntry(registry, "ANL-005");

reference = makeTransmissionArchive(ones(36,1), "Reference");
sample = makeTransmissionArchive(0.1 .* ones(36,1), "Sample");

result = entry.AnalysisRunner(reference, sample);

verifyEqual(testCase, ...
    [result.RedDensity, result.GreenDensity, result.BlueDensity], ...
    [1, 1, 1], ...
    AbsTol=1e-12);
verifyEqual(testCase, [result.WhiteDensity, result.WhiteTransmittance], ...
    [1, 0.1], AbsTol=1e-12);

verifyEqual(testCase, ...
    [result.RedTransmittance, ...
     result.GreenTransmittance, ...
     result.BlueTransmittance], ...
    [0.1, 0.1, 0.1], ...
    AbsTol=1e-12);
end

function testResolvesStatusMDensity(testCase)

entry = spectralab.report.internal.resolveAnalysisSpecification("ANL-008");
definition = entry.AnalysisDefinition;

verifyEqual(testCase, entry.InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, definition.AnalysisId, "ANL-008");
verifyFalse(testCase, definition.HasFigure);
verifyEqual(testCase, ...
    [definition.ResultFields.Field], ...
    ["RedDensity", "GreenDensity", "BlueDensity", ...
     "WhiteDensity", ...
     "RedTransmittance", "GreenTransmittance", ...
     "BlueTransmittance", "WhiteTransmittance"]);
verifyEqual(testCase, ...
    string({definition.ResultFields(5:8).Format}), ...
    repmat("%.4f", 1, 4));
end

function testStatusMDensityRunnerReturnsReportFields(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();
entry = findEntry(registry, "ANL-008");

reference = makeTransmissionArchive(ones(36,1), "Reference");
sample = makeTransmissionArchive(0.1 .* ones(36,1), "Sample");

result = entry.AnalysisRunner(reference, sample);

verifyEqual(testCase, ...
    [result.RedDensity, result.GreenDensity, result.BlueDensity], ...
    [1, 1, 1], ...
    AbsTol=1e-12);
verifyEqual(testCase, [result.WhiteDensity, result.WhiteTransmittance], ...
    [1, 0.1], AbsTol=1e-12);

verifyEqual(testCase, ...
    [result.RedTransmittance, ...
     result.GreenTransmittance, ...
     result.BlueTransmittance], ...
    [0.1, 0.1, 0.1], ...
    AbsTol=1e-12);
end

function testResolvesIsoVisualDensity(testCase)

entry = spectralab.report.internal.resolveAnalysisSpecification("ANL-007");
definition = entry.AnalysisDefinition;

verifyEqual(testCase, entry.InputRoles, ["Reference", "Sample"]);
verifyEqual(testCase, definition.AnalysisId, "ANL-007");
verifyTrue(testCase, definition.HasFigure);
verifyEqual(testCase, ...
    [definition.ResultFields.Field], ...
    ["Density", "Transmittance"]);
end

function testIsoVisualDensityRunnerReturnsReportFields(testCase)

registry = spectralab.report.internal.createAnalysisRegistry();
entry = findEntry(registry, "ANL-007");

reference = makeTransmissionArchive(ones(36,1), "Reference");
sample = makeTransmissionArchive(0.1 .* ones(36,1), "Sample");

result = entry.AnalysisRunner(reference, sample);

verifyEqual(testCase, result.Density, 1, AbsTol=1e-12);
verifyEqual(testCase, result.Transmittance, 0.1, AbsTol=1e-12);
verifyEqual(testCase, result.SpectralDensity, ...
    ones(36,1), AbsTol=1e-12);
verifyEqual(testCase, result.WavelengthNm, ...
    reference.Measurement.Wavelength(:));
end

function testIsoVisualDensityFigureKeepsResultOutOfTitle(testCase)
registry = spectralab.report.internal.createAnalysisRegistry();
entry = findEntry(registry, "ANL-007");
reference = makeTransmissionArchive(ones(36,1), "Reference");
sample = makeTransmissionArchive(0.1 .* ones(36,1), "Sample");
result = entry.AnalysisRunner(reference, sample);
fig = figure("Visible", "off");
cleanup = onCleanup(@() close(fig));
ax = axes("Parent", fig);
entry.FigureRenderer(ax, reference, sample, result);

verifyEqual(testCase, string(ax.Title.String), ...
    "Spectral optical density (ISO visual)");
verifyFalse(testCase, contains(string(ax.Title.String), "1.0000"));
end

function testListsPublicAnalysisSummaries(testCase)

analyses = spectralab.report.listAnalyses();

verifyEqual(testCase, numel(analyses), 10);
verifyEqual(testCase, ...
    [analyses.AnalysisId], ...
    ["ANL-SPECTRUM", "ANL-CRI", "ANL-001", ...
     "ANL-002", "ANL-009", "ANL-010", "ANL-004", "ANL-005", ...
     "ANL-008", "ANL-007"]);
verifyTrue(testCase, all(strlength([analyses.Description]) > 0));
verifyFalse(testCase, isfield(analyses, "AnalysisRunner"));
verifyFalse(testCase, isfield(analyses, "FigureRenderer"));
end

function testDescribesRegisteredAnalysis(testCase)

description = spectralab.report.describeAnalysis("ANL-002");

verifyEqual(testCase, description.AnalysisId, "ANL-002");
verifyEqual(testCase, description.Name, "Optical Density");
verifyEqual(testCase, description.InputRoles, ["Reference", "Sample"]);
verifyTrue(testCase, description.HasFigure);
verifyTrue(testCase, isfield(description, "FigureDefinition"));
verifyFalse(testCase, isfield(description, "AnalysisRunner"));
verifyFalse(testCase, isfield(description, "FigureRenderer"));
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

function entry = findEntry(registry, analysisId)

entry = registry(registryAnalysisIds(registry) == analysisId);
end

function analysisIds = registryAnalysisIds(registry)

analysisIds = strings(1, numel(registry));

for k = 1:numel(registry)
    analysisIds(k) = registry(k).AnalysisDefinition.AnalysisId;
end
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
