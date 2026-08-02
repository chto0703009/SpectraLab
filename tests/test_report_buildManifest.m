function tests = test_report_buildManifest
%TEST_REPORT_BUILDMANIFEST Tests for the declarative ReportManifest model.

    tests = functiontests(localfunctions);
end

function testBuildsCanonicalSectionOrder(testCase)

    manifest = spectralab.report.internal.buildManifest(makeContext(true));

    verifyEqual(testCase, manifest.Format, "SLAB-REPORT-MANIFEST");
    verifyEqual(testCase, manifest.Version, "1.0");
    verifyEqual(testCase, [manifest.Sections.Id].', [ ...
        "Title"
        "InformationBox"
        "Measurement"
        "Analysis"
        "Results"
        "Figure"
        "Provenance"]);
end

function testReferencesContextWithoutCopyingData(testCase)

    context = makeContext(true);
    manifest = spectralab.report.internal.buildManifest(context);

    verifyEqual(testCase, [manifest.Sections.SourcePath].', [ ...
        "Measurement"
        "Report"
        "Measurement"
        "Analysis"
        "Result"
        "Analysis"
        "Archive"]);

    verifyFalse(testCase, isfield(manifest, "Result"));
    verifyFalse(testCase, isfield(manifest, "Archive"));
    verifyFalse(testCase, isfield(manifest, "Measurement"));
    verifyFalse(testCase, isfield(manifest.Sections, "Data"));
end

function testOmitsFigureForAnalysisWithoutFigure(testCase)

    manifest = spectralab.report.internal.buildManifest(makeContext(false));

    verifyFalse(testCase, any([manifest.Sections.Id] == "Figure"));
end

function testAddsWarningsOnlyWhenPresent(testCase)

    context = makeContext(true);
    context.Report.Warnings = ["Archive name differs"; "Limited range"];

    manifest = spectralab.report.internal.buildManifest(context);

    warningSection = manifest.Sections([manifest.Sections.Id] == "Warnings");
    verifyNumElements(testCase, warningSection, 1);
    verifyEqual(testCase, warningSection.SourcePath, "Report.Warnings");
    verifyFalse(testCase, warningSection.Required);
end

function testRejectsIncompleteContext(testCase)

    context = rmfield(makeContext(true), "Result");

    verifyError(testCase, @() ...
        spectralab.report.internal.buildManifest(context), ...
        "SpectraLab:Report:InvalidContext");
end

function context = makeContext(hasFigure)

    context.Archive = struct( ...
        "UUID", "12345678-1234-1234-1234-123456789abc", ...
        "ContentHash", "abcdef0123456789");
    context.Measurement = struct("Name", "Reference");
    context.Analysis = struct( ...
        "AnalysisId", "ANL-004", ...
        "Name", "White Density", ...
        "HasFigure", logical(hasFigure));
    context.Result = struct("Density", pi / 10);
    context.Report = struct( ...
        "ReportId", "", ...
        "Warnings", strings(0,1));
end
