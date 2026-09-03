function tests = test_report_keyValueTable
%TEST_REPORT_KEYVALUETABLE Verify canonical metadata table sources.

tests = functiontests(localfunctions);
end

function testLongArchiveFilenameWrapsToTwoLines(testCase)
context = makeProvenanceContext();
context.Archive.Filename = ...
    "C41_very_long_descriptive_measurement_name_20260801_reference.mat";

model = spectralab.report.internal.buildKeyValueTable("provenance", context);

verifyEqual(testCase, model.Rows(1).LineCount, 2);
verifyEqual(testCase, count(model.Rows(1).DisplayText, newline), 1);
end

function testProvenanceIncludesInstrumentSerialNumber(testCase)
context = makeProvenanceContext();

model = spectralab.report.internal.buildKeyValueTable("provenance", context);
serialRow = model.Rows([model.Rows.Label] == ...
    "Instrument serial number");

verifyEqual(testCase, numel(serialRow), 1);
verifyEqual(testCase, serialRow.DisplayText, "1234567");
end

function testProvenancePlacesInstrumentBeforeSerialNumber(testCase)
context = makeProvenanceContext();

model = spectralab.report.internal.buildKeyValueTable("provenance", context);
labels = [model.Rows.Label];
instrumentIndex = find(labels == "Instrument", 1);
serialIndex = find(labels == "Instrument serial number", 1);

verifyEqual(testCase, model.Rows(instrumentIndex).DisplayText, "i1Pro2");
verifyEqual(testCase, serialIndex, instrumentIndex + 1);
end

function context = makeProvenanceContext()
context.Archive = struct("Filename", "short.mat", "UUID", ...
    "12345678-1234-1234-1234-123456789012", ...
    "ContentHash", repmat('a', 1, 64), "Format", "SLAB-MAT", ...
    "Version", "0.6");
context.Instrument = struct("Name", "i1Pro2", "SerialNumber", "1234567");
context.Report = struct("Format", "SLAB-REPORT", "Version", "1.0", ...
    "SpectraLabVersion", "0.8.1", "ReportId", "RPT-test", ...
    "GenerationTime", datetime(2026,8,1,12,0,0));
end

function testMeasurementUsesResolvedInformation(testCase)
context = struct();
context.Measurement = struct("Name", "Raw name");
context.MeasurementInformation = struct( ...
    "Name", "Resolved name", ...
    "Project", "Project 081", ...
    "Sample", "Sample A", ...
    "Operator", "Operator A", ...
    "Date", datetime(2026, 8, 1, 10, 17, 7), ...
    "Comment", "Stability run after warm-up");

model = spectralab.report.internal.buildKeyValueTable( ...
    "measurementInformation", context);

verifyEqual(testCase, [model.Rows.Label], ...
    ["Measurement", "Project", "Sample", "Operator", "Date", "Comment"]);
verifyEqual(testCase, [model.Rows.DisplayText], ...
    ["Resolved name", "Project 081", "Sample A", "Operator A", ...
     "2026-08-01 10:17:07", "Stability run after warm-up"]);
end

function testTenSourceMeasurementTableFitsOnePage(testCase)
source = struct("Role", "", "Filename", "", "Measurement", struct(), ...
    "Metadata", struct());
sources = repmat(source, 1, 10);
for index = 1:numel(sources)
    sources(index).Role = "Source " + index;
    sources(index).Filename = sprintf( ...
        "emission_series_20260817_205516_%02d.mat", index);
    sources(index).Measurement = struct( ...
        "Name", "emission_series_20260817_205516_" + sprintf("%02d", index));
end
context = struct("SourceArchives", sources);

model = spectralab.report.internal.buildKeyValueTable( ...
    "measurementInformation", context);
height = spectralab.report.internal.estimateResultsTableHeight(model);
layout = spectralab.report.internal.createLayoutState();

verifyEqual(testCase, numel(model.Rows), 10);
verifyEqual(testCase, [model.Rows.Label], "Source " + (1:10) + " archive");
verifyLessThanOrEqual(testCase, height, layout.ContentHeight);
end
