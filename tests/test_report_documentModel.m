function tests = test_report_documentModel
%TEST_REPORT_DOCUMENTMODEL Tests for the minimal generic document model.

    tests = functiontests(localfunctions);
end

function testCanonicalDocumentVocabulary(testCase)

    elementTypes = [ ...
        "heading", "paragraph", "table", "figure", ...
        "caption", "list", "spacer", "pageBreak"];

    for elementType = elementTypes
        element = spectralab.report.internal.createDocumentElement( ...
            "Example", elementType, "exampleRole", "Report", true);
        verifyEqual(testCase, element.Type, elementType);
    end
end

function testBuildsElementsInManifestOrder(testCase)

    manifest = makeManifest( ...
        ["Title", "Results", "Figure", "Provenance"], ...
        ["title", "results", "figure", "provenance"], ...
        ["Report", "Result", "Analysis", "Archive"]);

    document = spectralab.report.internal.buildDocumentModel(manifest);

    verifyEqual(testCase, [document.Elements.Id], ...
        ["Title", "Results", "Figure", "Provenance"]);
    verifyEqual(testCase, [document.Elements.Type], ...
        ["heading", "table", "figure", "table"]);
end

function testReferencesContextWithoutCopyingData(testCase)

    manifest = makeManifest( ...
        ["Measurement", "Results"], ...
        ["measurement", "results"], ...
        ["Measurement", "Result"]);

    document = spectralab.report.internal.buildDocumentModel(manifest);

    verifyEqual(testCase, [document.Elements.SourcePath], ...
        ["Measurement", "Result"]);
    elementFields = string(fieldnames(document.Elements));
    copiedDataFields = ["Value", "Data", "Content", "Result"];
    verifyFalse(testCase, any(ismember(copiedDataFields, elementFields)));
end

function testUsesInjectedComponentRegistry(testCase)

    manifest = makeManifest("Custom", "custom", "Report");
    registry = struct( ...
        "Component", "custom", ...
        "ElementType", "caption", ...
        "Role", "customCaption");

    document = spectralab.report.internal.buildDocumentModel( ...
        manifest, registry);

    verifyEqual(testCase, document.Elements.Type, "caption");
    verifyEqual(testCase, document.Elements.Role, "customCaption");
end

function testRejectsUnknownManifestComponent(testCase)

    manifest = makeManifest("Unknown", "unknown", "Report");

    verifyError(testCase, @() ...
        spectralab.report.internal.buildDocumentModel(manifest), ...
        "SpectraLab:Report:UnknownDocumentComponent");
end

function testRejectsUnknownElementType(testCase)

    verifyError(testCase, @() ...
        spectralab.report.internal.createDocumentElement( ...
            "Example", "unknown", "exampleRole", "Report", true), ...
        "SpectraLab:Report:UnknownDocumentElement");
end

function manifest = makeManifest(ids, components, sourcePaths)

    ids = string(ids);
    components = string(components);
    sourcePaths = string(sourcePaths);

    sections = repmat(struct( ...
        "Id", "", ...
        "Component", "", ...
        "SourcePath", "", ...
        "Required", true), numel(ids), 1);

    for k = 1:numel(ids)
        sections(k).Id = ids(k);
        sections(k).Component = components(k);
        sections(k).SourcePath = sourcePaths(k);
    end

    manifest = struct( ...
        "Format", "SLAB-REPORT-MANIFEST", ...
        "Version", "1.0", ...
        "Sections", sections);
end
