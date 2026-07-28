function tests = test_report_renderManifest
%TEST_REPORT_RENDERMANIFEST Tests for renderer registry and dispatch engine.

    tests = functiontests(localfunctions);
end

function testCanonicalRegistryHasUniqueComponents(testCase)

    registry = spectralab.report.internal.createRendererRegistry();
    components = [registry.Component];

    verifyEqual(testCase, components, [ ...
        "title", "measurement", "analysis", "results", ...
        "figure", "warnings", "provenance", "footer"]);
    verifyEqual(testCase, numel(unique(components)), numel(components));
    verifyTrue(testCase, all(arrayfun(@(x) ...
        isa(x.Renderer, "function_handle"), registry)));
end

function testRendersSectionsInManifestOrder(testCase)

    context = makeContext();
    manifest = makeManifest(["Title", "Results", "Footer"], ...
        ["title", "results", "footer"]);
    renderContext = makeRenderContext();

    renderContext = spectralab.report.internal.renderManifest( ...
        context, manifest, renderContext);

    verifyEqual(testCase, renderContext.State.RenderedSections, ...
        ["Title"; "Results"; "Footer"]);
end

function testUsesInjectedRegistry(testCase)

    context = makeContext();
    manifest = makeManifest("Custom", "custom");
    renderContext = makeRenderContext();
    registry = struct( ...
        "Component", "custom", ...
        "Renderer", @customRenderer);

    renderContext = spectralab.report.internal.renderManifest( ...
        context, manifest, renderContext, registry);

    verifyEqual(testCase, renderContext.State.RenderedSections, "Custom");
    verifyTrue(testCase, renderContext.State.CustomRendererCalled);
end

function testRejectsUnknownComponent(testCase)

    verifyError(testCase, @() ...
        spectralab.report.internal.renderManifest( ...
            makeContext(), makeManifest("Unknown", "unknown"), ...
            makeRenderContext()), ...
        "SpectraLab:Report:UnknownRenderer");
end

function testDoesNotModifyContextOrManifest(testCase)

    context = makeContext();
    manifest = makeManifest(["Title", "Footer"], ["title", "footer"]);
    originalContext = context;
    originalManifest = manifest;

    spectralab.report.internal.renderManifest( ...
        context, manifest, makeRenderContext());

    verifyEqual(testCase, context, originalContext);
    verifyEqual(testCase, manifest, originalManifest);
end

function renderContext = customRenderer(context, section, renderContext) %#ok<INUSD>

    renderContext.State.RenderedSections(end+1,1) = string(section.Id);
    renderContext.State.CustomRendererCalled = true;
end

function context = makeContext()

    context.Report = struct( ...
        "Format", "SLAB-REPORT", ...
        "Version", "1.0", ...
        "ReportId", "");
end

function manifest = makeManifest(ids, components)

    ids = string(ids);
    components = string(components);
    sections = repmat(struct( ...
        "Id", "", ...
        "Component", "", ...
        "SourcePath", "Report", ...
        "Required", true), numel(ids), 1);

    for k = 1:numel(ids)
        sections(k).Id = ids(k);
        sections(k).Component = components(k);
    end

    manifest = struct( ...
        "Format", "SLAB-REPORT-MANIFEST", ...
        "Version", "1.0", ...
        "Sections", sections);
end

function renderContext = makeRenderContext()

    renderContext = struct( ...
        "Format", "SLAB-REPORT-RENDER-CONTEXT", ...
        "Version", "1.0", ...
        "Graphics", struct(), ...
        "TemporaryFiles", strings(0,1), ...
        "State", struct( ...
            "CurrentPage", 0, ...
            "CursorY", NaN, ...
            "RenderedSections", strings(0,1)));
end
