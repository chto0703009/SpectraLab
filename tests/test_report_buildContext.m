function tests = test_report_buildContext
%TEST_REPORT_BUILDCONTEXT Tests for the initial ReportContext model.

    tests = functiontests(localfunctions);
end

function testBuildsDataOnlyContext(testCase)

    archive = makeArchive();
    definition = makeAnalysisDefinition();
    result = struct("Density", 0.30103);
    generationTime = datetime(2026,7,28,11,30,0);

    context = spectralab.report.internal.buildContext( ...
        "/data/reference.mat", ...
        archive, ...
        definition, ...
        result, ...
        "/reports", ...
        ShowFigure=false, ...
        OpenPDF=false, ...
        GenerationTime=generationTime);

    verifyEqual(testCase, context.Request.AnalysisId, "ANL-004");
    verifyEqual(testCase, context.Archive.Filename, "reference.mat");
    verifyEqual(testCase, context.Archive.UUID, archive.Identity.UUID);
    verifyEqual(testCase, context.Measurement, archive.Measurement);
    verifyEqual(testCase, context.Metadata, archive.Metadata);
    verifyEqual(testCase, context.Instrument, archive.Instrument);
    verifyEqual(testCase, context.Quality, archive.Quality);
    verifyEqual(testCase, context.Analysis, definition);
    verifyEqual(testCase, context.Result, result);
    verifyEqual(testCase, context.Report.Format, "SLAB-REPORT");
    verifyEqual(testCase, context.Report.Version, "1.0");
    verifyEqual(testCase, context.Report.GenerationTime, generationTime);
end

function testContainsNoGraphicsOrOutputState(testCase)

    context = spectralab.report.internal.buildContext( ...
        "reference.mat", ...
        makeArchive(), ...
        makeAnalysisDefinition(), ...
        struct("Density", 0.30103), ...
        "reports");

    verifyFalse(testCase, isfield(context, "Figure"));
    verifyFalse(testCase, isfield(context, "RenderContext"));
    verifyFalse(testCase, isfield(context, "Output"));
end

function testPreservesFullPrecisionResult(testCase)

    value = pi / 10;
    result = struct("Density", value);

    context = spectralab.report.internal.buildContext( ...
        "reference.mat", ...
        makeArchive(), ...
        makeAnalysisDefinition(), ...
        result, ...
        "reports");

    verifyEqual(testCase, context.Result.Density, value, AbsTol=0);
end

function testRejectsIncompleteArchive(testCase)

    archive = rmfield(makeArchive(), "Instrument");

    verifyError(testCase, @() ...
        spectralab.report.internal.buildContext( ...
            "reference.mat", archive, makeAnalysisDefinition(), ...
            struct(), "reports"), ...
        "SpectraLab:Report:InvalidArchive");
end

function testRejectsIncompleteAnalysisDefinition(testCase)

    definition = rmfield(makeAnalysisDefinition(), "Method");

    verifyError(testCase, @() ...
        spectralab.report.internal.buildContext( ...
            "reference.mat", makeArchive(), definition, ...
            struct(), "reports"), ...
        "SpectraLab:Report:InvalidAnalysisDefinition");
end

function archive = makeArchive()

    archive.Identity.UUID = ...
        "12345678-1234-1234-1234-123456789abc";
    archive.Identity.ContentHash = "abcdef0123456789";

    archive.Version.Format = "SLAB-MAT";
    archive.Version.Version = "0.6";

    archive.Measurement.Name = "White density reference";
    archive.Measurement.Wavelength = (380:10:730).';
    archive.Measurement.Value = ones(36,1);
    archive.Measurement.Unit = "arbitrary";
    archive.Measurement.Operator = "Christer Törnkvist";
    archive.Measurement.Timestamp = datetime(2026,7,28,10,0,0);

    archive.Metadata.Project = "Report development";
    archive.Metadata.SampleID = "REPORT-001";
    archive.Metadata.Description = "";
    archive.Metadata.Laboratory = "";
    archive.Metadata.Tags = strings(0);
    archive.Metadata.Comment = "";

    archive.Instrument.Name = "X-Rite i1Pro 2";
    archive.Instrument.Driver = "spotread";
    archive.Instrument.SerialNumber = "1001799";
    archive.Instrument.CalibrationID = "CAL-001";

    archive.Quality.Valid = true;
    archive.Quality.Warning = "";
    archive.Quality.Saturated = false;
    archive.Quality.SignalLevel = [];
    archive.Quality.Comment = "";
end

function definition = makeAnalysisDefinition()

    definition = struct( ...
        "AnalysisId", "ANL-004", ...
        "Name", "White Density", ...
        "Method", "Weighted optical density", ...
        "Standard", "CIE photopic V(lambda)", ...
        "DefinitionVersion", "1", ...
        "HasFigure", true);
end
