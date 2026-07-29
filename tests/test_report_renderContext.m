function tests = test_report_renderContext
%TEST_REPORT_RENDERCONTEXT Tests for temporary report rendering resources.

    tests = functiontests(localfunctions);
end

function testCreatesHiddenFigureForFigureSection(testCase)

    renderContext = spectralab.report.internal.createRenderContext( ...
        makeContext(), makeManifest(true));
    cleanup = onCleanup(@() ...
        spectralab.report.internal.releaseRenderContext(renderContext)); %#ok<NASGU>

    verifyEqual(testCase, renderContext.Format, ...
        "SLAB-REPORT-RENDER-CONTEXT");
    verifyEqual(testCase, renderContext.Version, "1.0");
    verifyTrue(testCase, isgraphics(renderContext.Graphics.Figure, "figure"));
    verifyTrue(testCase, isgraphics(renderContext.Graphics.Axes, "axes"));
    verifyEqual(testCase, ...
        string(renderContext.Graphics.Figure.Visible), "off");
end

function testContainsPageFrameModel(testCase)

    renderContext = spectralab.report.internal.createRenderContext( ...
        makeContext(), makeManifest(false));

    verifyEqual(testCase, renderContext.PageFrame.Format, ...
        "SLAB-REPORT-PAGE-FRAME");
    verifyEqual(testCase, renderContext.PageFrame.HeaderLeft, ...
        "SpectraLab");
    verifyEqual(testCase, renderContext.PageFrame.HeaderRight, ...
        "White Density");
    verifyEqual(testCase, renderContext.PageFrame.FooterLeft, ...
        "Report ID RPT-001");
    verifyEqual(testCase, renderContext.PageFrame.FooterCenter, ...
        "SpectraLab 0.8.0-test");
end


function testCanShowFigureExplicitly(testCase)

    renderContext = spectralab.report.internal.createRenderContext( ...
        makeContext(), makeManifest(true), ShowFigure=true);
    cleanup = onCleanup(@() ...
        spectralab.report.internal.releaseRenderContext(renderContext)); %#ok<NASGU>

    verifyEqual(testCase, ...
        string(renderContext.Graphics.Figure.Visible), "on");
end

function testCreatesNoGraphicsWithoutFigureSection(testCase)

    renderContext = spectralab.report.internal.createRenderContext( ...
        makeContext(), makeManifest(false));

    verifyEmpty(testCase, renderContext.Graphics.Figure);
    verifyEmpty(testCase, renderContext.Graphics.Axes);
end

function testContainsOnlyTemporaryState(testCase)

    renderContext = spectralab.report.internal.createRenderContext( ...
        makeContext(), makeManifest(false));

    verifyFalse(testCase, isfield(renderContext, "ReportContext"));
    verifyFalse(testCase, isfield(renderContext, "ReportManifest"));
    verifyFalse(testCase, isfield(renderContext, "Result"));
    verifyEqual(testCase, renderContext.TemporaryFiles, strings(0,1));
    verifyEqual(testCase, renderContext.State.CurrentPage, 1);
    verifyEqual(testCase, renderContext.State.CursorY, 0);
end

function testReleaseRemovesOwnedResources(testCase)

    temporaryFile = string(tempname) + ".tmp";
    fileId = fopen(temporaryFile, "w");
    assert(fileId >= 0, "Unable to create temporary test file.");
    fclose(fileId);

    renderContext = spectralab.report.internal.createRenderContext( ...
        makeContext(), makeManifest(true));
    figureHandle = renderContext.Graphics.Figure;
    renderContext.TemporaryFiles = temporaryFile;

    spectralab.report.internal.releaseRenderContext(renderContext);

    verifyFalse(testCase, isgraphics(figureHandle));
    verifyFalse(testCase, isfile(temporaryFile));
end

function context = makeContext()

    context.Analysis = struct( ...
        "Name", "White Density");

    context.Report = struct( ...
        "Format", "SLAB-REPORT", ...
        "Version", "1.0", ...
        "ReportId", "RPT-001", ...
        "SpectraLabVersion", "0.8.0-test");
end

function manifest = makeManifest(hasFigure)

    sections = struct( ...
        "Id", "Title", ...
        "Component", "title", ...
        "SourcePath", "Measurement", ...
        "Required", true);

    if hasFigure
        sections(end+1,1) = struct( ...
            "Id", "Figure", ...
            "Component", "figure", ...
            "SourcePath", "Analysis", ...
            "Required", true); %#ok<AGROW>
    end

    manifest = struct( ...
        "Format", "SLAB-REPORT-MANIFEST", ...
        "Version", "1.0", ...
        "Sections", sections);
end
