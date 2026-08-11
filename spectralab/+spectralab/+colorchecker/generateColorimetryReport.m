function info = generateColorimetryReport(convertedJsonFile, options)
%GENERATECOLORIMETRYREPORT Create a ColorChecker XYZ and Lab PDF report.

arguments
    convertedJsonFile (1,1) string
    options.OpenPDF (1,1) logical = false
    options.VerificationIlluminant = []
end

if ~isfile(convertedJsonFile)
    error("SpectraLab:ColorChecker:ConvertedJsonNotFound", ...
        "Converted ColorChecker JSON not found: %s", convertedJsonFile);
end
session = spectralab.colorchecker.load(convertedJsonFile);
if ~isfield(session, "ColorimetryConversions") || ...
        isempty(session.ColorimetryConversions)
    error("SpectraLab:ColorChecker:ColorimetryConversionMissing", ...
        "The selected JSON contains no ColorChecker colorimetry conversion.");
end
conversion = session.ColorimetryConversions(end);
results = conversion.Results;
verification = spectralab.colorchecker.verifyColorimetry( ...
    convertedJsonFile, Illuminant=options.VerificationIlluminant);

sessionFolder = string(fileparts(convertedJsonFile));
[qualitySummary, provenanceRows] = collectPatchProvenance( ...
    session, sessionFolder);
reportFolder = fullfile(sessionFolder, "report");
if ~isfolder(reportFolder), mkdir(reportFolder); end
[~, baseName] = fileparts(convertedJsonFile);
pdfFile = fullfile(reportFolder, string(baseName) + "_report.pdf");
if isfile(pdfFile)
    error("SpectraLab:ColorChecker:ColorimetryReportExists", ...
        "SpectraLab refuses to overwrite the ColorChecker report:\n%s", ...
        pdfFile);
end

import mlreportgen.dom.*
document = Document(char(erase(pdfFile, ".pdf")), "pdf");
layout = PDFPageLayout;
layout.PageSize.Orientation = "portrait";
layout.PageSize.Width = "210mm";
layout.PageSize.Height = "297mm";
layout.PageMargins.Top = "12mm";
layout.PageMargins.Bottom = "12mm";
layout.PageMargins.Left = "14mm";
layout.PageMargins.Right = "14mm";
layout.PageMargins.Header = "6mm";
layout.PageMargins.Footer = "6mm";
layout.PageHeaders = [pageHeader("default"), pageHeader("even")];
layout.PageFooters = [pageFooter(session, "default"), ...
    pageFooter(session, "even")];
append(document, layout);

title = Paragraph("ColorChecker colorimetry");
title.Style = {FontFamily("Helvetica"), FontSize("20pt"), ...
    Bold(true), Color("#1F4E79"), ...
    OuterMargin("0pt", "0pt", "0pt", "2pt")};
append(document, title);
targetName = targetValue(session, "Name");
if targetName == "-"
    targetName = string(session.Definition.Name);
end
subtitle = Paragraph(targetName);
subtitle.Style = {FontFamily("Helvetica"), FontSize("12pt"), ...
    Color("#555555"), OuterMargin("0pt", "0pt", "0pt", "4pt")};
append(document, subtitle);

append(document, sectionHeading("Measurement and calculation"));
details = {
    "Session UUID", string(session.Identity.UUID);
    "Session created", string(session.Identity.Created);
    "SpectraLab measurement version", string(session.Identity.Software);
    "Operator", valueOrDash(session.Context, "Operator");
    "Project", valueOrDash(session.Context, "Project");
    "Official target model", targetValue(session, "Name");
    "Target canonical ID", targetValue(session, "CanonicalID");
    "Target definition SHA-256", ...
        valueOrDash(session.Definition, "TargetDefinitionHash");
    "Measurement session name", valueOrDash(session.Definition, "Name");
    "Physical chart ID (operator supplied)", ...
        valueOrDash(session.Definition, "ChartID");
    "Chart serial number", valueOrDash(session.Definition, "ChartSerialNumber");
    "Chart manufactured", valueOrDash(session.Definition, "ChartManufacturedDate");
    "Chart geometry", sprintf("%d rows x %d columns", ...
        session.Definition.Rows, session.Definition.Columns);
    "Source session", string(conversion.SourceSessionFile);
    "Calculation version", string(conversion.CalculationVersion);
    "Method", string(conversion.Method);
    "Illuminant", string(conversion.Illuminant.Label);
    "Observer", string(conversion.Observer);
    "Converted", string(conversion.Created);
    "Patch count", string(conversion.PatchCount)};
append(document, keyValueTable(details));

append(document, sectionHeading("Measurement provenance"));
provenance = {
    "Primary measurement", string(session.MeasurementDefinition.Quantity) + ...
        " R(lambda), " + string(session.MeasurementDefinition.Unit);
    "Archive model", string(session.MeasurementDefinition.PrimaryData);
    "Instrument", qualitySummary.InstrumentName;
    "Instrument serial number", qualitySummary.InstrumentSerialNumber;
    "Driver", qualitySummary.InstrumentDriver;
    "Spectral resolution", qualitySummary.Resolution;
    "Calibration events", string(numel(session.Calibrations));
    "Calibration method", qualitySummary.CalibrationMethod;
    "Calibration interval", string(session.CalibrationPolicy.IntervalMinutes) + ...
        " minutes";
    "Session revisions", string(session.Identity.Revision)};
append(document, keyValueTable(provenance));

append(document, sectionHeading("Quality summary"));
quality = {
    "Patch archives expected", string(numel(session.Patches));
    "Patch archives loaded", string(qualitySummary.LoadedCount);
    "Identity and hash references verified", ...
        yesNo(qualitySummary.TraceabilityVerified);
    "Archives marked valid", string(qualitySummary.ValidCount) + ...
        " of " + string(qualitySummary.LoadedCount);
    "Archives marked saturated", string(qualitySummary.SaturatedCount);
    "Archives with warnings", string(qualitySummary.WarningCount);
    "Archives with quality comments", string(qualitySummary.CommentCount);
    "Overall quality", qualitySummary.OverallStatus};
quality(end+1,:) = {"Colorimetry recalculation", ...
    sprintf("verified: %s; maximum difference XYZ %.3g, Lab %.3g", ...
        yesNo(verification.Verified), verification.MaximumXYZDifference, ...
        verification.MaximumLabDifference)};
append(document, keyValueTable(quality));

append(document, PageBreak());
append(document, sectionHeading("Results"));
rows = cell(numel(results) + 1, 8);
rows(1,:) = {"Patch", "", "X", "Y", "Z", "L*", "a*", "b*"};
for index = 1:numel(results)
    result = results(index);
    rows(index+1,:) = { ...
        string(result.Coordinate), "", ...
        number(result.XYZ.X), number(result.XYZ.Y), number(result.XYZ.Z), ...
        number(result.Lab.L), number(result.Lab.a), number(result.Lab.b)};
end
resultsTable = Table(rows);
resultsTable.Style = {Border("solid", "#9EADB8", "0.5pt"), ...
    RowSep("solid", "#D9E0E5", "0.25pt"), ...
    ColSep("solid", "#D9E0E5", "0.25pt"), Width("124mm"), ...
    FontFamily("Helvetica"), FontSize("7.5pt"), ...
    OuterMargin("0pt", "0pt", "0pt", "4pt")};
resultsTable.TableEntriesHAlign = "right";
resultsTable.TableEntriesVAlign = "middle";
for column = 1:8
    resultsTable.Children(1).Children(column).Style = { ...
        BackgroundColor("#DCE6F1"), Bold(true), ...
        HAlign("center"), FontSize("7.5pt")};
end
for row = 2:numel(resultsTable.Children)
    resultsTable.Children(row).Children(1).Style = { ...
        BackgroundColor("#EEF3F7"), Bold(true), HAlign("center")};
    rgb = displayRgb(results(row-1).XYZ, verification.ReferenceWhiteXYZ);
    resultsTable.Children(row).Children(2).Style = { ...
        BackgroundColor(rgbHex(rgb)), Width("4mm"), ...
        InnerMargin("0pt"), HAlign("center")};
end
for row = 1:numel(resultsTable.Children)
    resultsTable.Children(row).Children(1).Style{end+1} = Width("12mm");
    resultsTable.Children(row).Children(2).Style{end+1} = Width("4mm");
    for column = 3:8
        resultsTable.Children(row).Children(column).Style{end+1} = ...
            Width("18mm");
    end
end
append(document, resultsTable);

note = Paragraph( ...
    "XYZ and CIELAB are derived from the archived spectral reflectance " + ...
    "factors R(lambda). The original session JSON and MAT archives are unchanged.");
note.Style = {FontFamily("Helvetica"), FontSize("8pt"), ...
    Color("#555555"), OuterMargin("0pt", "0pt", "0pt", "4pt")};
append(document, note);

append(document, sectionHeading("Patch provenance and quality"));
summaryRows = provenanceRows(:, [1, 2, 5, 6]);
append(document, provenanceTable(summaryRows, [12, 100, 25, 40], "7pt"));

append(document, sectionHeading("Archive integrity references"));
integrityRows = provenanceRows(:, [1, 3, 4]);
append(document, provenanceTable(integrityRows, [12, 55, 110], "6pt"));

close(document);
info = struct( ...
    "PDFFile", pdfFile, ...
    "ConvertedJsonFile", convertedJsonFile, ...
    "PatchCount", numel(results), ...
    "ContainsPlot", false, ...
    "ContainsXYZ", true, ...
    "ContainsLab", true, ...
    "ContainsProvenance", true, ...
    "ContainsQuality", true);
if options.OpenPDF, open(char(pdfFile)); end
end

function paragraph = sectionHeading(value)
import mlreportgen.dom.*
paragraph = Paragraph(value);
paragraph.Style = {FontFamily("Helvetica"), FontSize("12pt"), ...
    Bold(true), Color("#1F4E79"), ...
    OuterMargin("0pt", "0pt", "4pt", "2pt")};
end

function header = pageHeader(pageType)
import mlreportgen.dom.*
header = PDFPageHeader(pageType);
left = Paragraph("SpectraLab");
left.Style = {FontFamily("Helvetica"), FontSize("10pt"), ...
    Bold(true), Color("#1F4E79"), HAlign("left"), ...
    OuterMargin("0pt")};
right = Paragraph("ColorChecker colorimetry");
right.Style = {FontFamily("Helvetica"), FontSize("8pt"), ...
    Color("#555555"), HAlign("right"), OuterMargin("0pt")};
table = Table({left, right});
table.Style = {Width("177mm"), Border("none"), RowSep("none"), ...
    ColSep("none"), FontFamily("Helvetica"), ...
    OuterMargin("0pt", "0pt", "0pt", "2pt")};
table.Children(1).Children(1).Style = {Width("50%")};
table.Children(1).Children(2).Style = {Width("50%")};
append(header, table);
end

function footer = pageFooter(session, pageType)
import mlreportgen.dom.*
footer = PDFPageFooter(pageType);
left = Paragraph("Session " + string(session.Identity.UUID));
left.Style = footerTextStyle("left");
center = Paragraph("SpectraLab " + spectralab.version());
center.Style = footerTextStyle("center");
right = Paragraph();
right.Style = footerTextStyle("right");
append(right, Text("Page "));
append(right, Page());
append(right, Text(" of "));
append(right, NumPages());
table = Table({left, center, right});
table.Style = {Width("177mm"), Border("none"), RowSep("none"), ...
    ColSep("none"), FontFamily("Helvetica"), ...
    OuterMargin("0pt")};
for column = 1:3
    table.Children(1).Children(column).Style = {Width("33.33%")};
end
append(footer, table);
end

function style = footerTextStyle(alignment)
import mlreportgen.dom.*
style = {FontFamily("Helvetica"), FontSize("6.5pt"), ...
    Color("#555555"), HAlign(alignment), OuterMargin("0pt")};
end

function table = provenanceTable(rows, widths, fontSize)
import mlreportgen.dom.*
table = Table(rows);
table.Style = {Border("solid", "#9EADB8", "0.5pt"), ...
    RowSep("solid", "#D9E0E5", "0.25pt"), ...
    ColSep("solid", "#D9E0E5", "0.25pt"), Width("177mm"), ...
    FontFamily("Helvetica"), FontSize(fontSize), ...
    OuterMargin("0pt", "0pt", "0pt", "4pt")};
table.TableEntriesVAlign = "middle";
for column = 1:size(rows, 2)
    table.Children(1).Children(column).Style = { ...
        BackgroundColor("#DCE6F1"), Bold(true), HAlign("center")};
end
for row = 1:numel(table.Children)
    for column = 1:numel(widths)
        table.Children(row).Children(column).Style{end+1} = ...
            Width(sprintf("%dmm", widths(column)));
    end
end
end

function table = keyValueTable(rows)
import mlreportgen.dom.*
table = Table(rows);
table.Style = {Border("solid", "#B8C4CE", "0.5pt"), ...
    RowSep("solid", "#D9E0E5", "0.25pt"), ...
    ColSep("solid", "#D9E0E5", "0.25pt"), Width("100%"), ...
    FontFamily("Helvetica"), FontSize("8pt"), ...
    OuterMargin("0pt", "0pt", "0pt", "4pt")};
for index = 1:numel(table.Children)
    table.Children(index).Children(1).Style = { ...
        BackgroundColor("#EEF3F7"), Bold(true), Width("28%")};
end
end

function value = number(input)
value = sprintf("%.2f", double(input));
end

function rgb = displayRgb(xyzValue, whiteValue)
xyz = [xyzValue.X; xyzValue.Y; xyzValue.Z];
sourceWhite = [whiteValue.X; whiteValue.Y; whiteValue.Z];
d65 = [95.0470; 100.0000; 108.8830];
bradford = [0.8951 0.2664 -0.1614; -0.7502 1.7135 0.0367; ...
    0.0389 -0.0685 1.0296];
adaptation = bradford \ ...
    (diag((bradford * d65) ./ (bradford * sourceWhite)) * bradford);
xyzD65 = adaptation * xyz ./ 100;
linear = [3.2404542 -1.5371385 -0.4985314; ...
    -0.9692660 1.8760108 0.0415560; ...
    0.0556434 -0.2040259 1.0572252] * xyzD65;
rgb = zeros(3,1);
low = linear <= 0.0031308;
rgb(low) = 12.92 .* linear(low);
rgb(~low) = 1.055 .* linear(~low).^(1/2.4) - 0.055;
rgb = min(1, max(0, rgb));
end

function value = rgbHex(rgb)
bytes = round(255 .* rgb(:));
value = sprintf("#%02X%02X%02X", bytes(1), bytes(2), bytes(3));
end

function [summary, rows] = collectPatchProvenance(session, sessionFolder)
patches = session.Patches;
rows = cell(numel(patches) + 1, 6);
rows(1,:) = {"Patch", "Archive file", "Archive UUID", ...
    "SHA-256 content hash", "Calibration", "Quality"};
loadedCount = 0;
validCount = 0;
saturatedCount = 0;
warningCount = 0;
commentCount = 0;
traceabilityVerified = true;
instrumentName = "-";
instrumentSerialNumber = "-";
instrumentDriver = "-";
resolution = "-";
for index = 1:numel(patches)
    patch = patches(index);
    archiveFile = string(patch.ArchiveFile);
    if ~isfile(archiveFile)
        archiveFile = fullfile(sessionFolder, archiveFile);
    end
    archive = spectralab.archive.load(archiveFile, ...
        Quiet=true, Validation="error");
    loadedCount = loadedCount + 1;
    uuidMatches = string(archive.Identity.UUID) == string(patch.ArchiveUUID);
    hashMatches = string(archive.Identity.ContentHash) == ...
        string(patch.ArchiveContentHash);
    traceabilityVerified = traceabilityVerified && uuidMatches && hashMatches;
    isValid = logical(archive.Quality.Valid);
    isSaturated = logical(archive.Quality.Saturated);
    warning = string(archive.Quality.Warning);
    comment = string(archive.Quality.Comment);
    validCount = validCount + double(isValid);
    saturatedCount = saturatedCount + double(isSaturated);
    warningCount = warningCount + double(strlength(strtrim(warning)) > 0);
    commentCount = commentCount + double(strlength(strtrim(comment)) > 0);
    status = qualityStatus(isValid, isSaturated, warning, comment, ...
        uuidMatches && hashMatches);
    rows(index+1,:) = {string(patch.Coordinate), ...
        wrapArchiveReference(string(patch.ArchiveFile)), ...
        wrapFixed(string(patch.ArchiveUUID), 18), ...
        wrapFixed(string(patch.ArchiveContentHash), 32), ...
        string(patch.CalibrationSequence), status};
    if index == 1
        instrumentName = valueOrDash(archive.Instrument, "Name");
        instrumentSerialNumber = valueOrDash(archive.Instrument, "SerialNumber");
        instrumentDriver = valueOrDash(archive.Instrument, "Driver");
        if isfield(archive.Instrument, "HighResolution") && ...
                logical(archive.Instrument.HighResolution)
            resolution = "high resolution";
        else
            resolution = "standard resolution";
        end
    end
end
calibrationMethod = "-";
if ~isempty(session.Calibrations)
    methods = unique(string({session.Calibrations.Method}), "stable");
    calibrationMethod = join(methods, "; ");
end
overallOkay = loadedCount == numel(patches) && traceabilityVerified && ...
    validCount == loadedCount && saturatedCount == 0 && warningCount == 0;
summary = struct( ...
    "LoadedCount", loadedCount, "ValidCount", validCount, ...
    "SaturatedCount", saturatedCount, "WarningCount", warningCount, ...
    "CommentCount", commentCount, ...
    "TraceabilityVerified", traceabilityVerified, ...
    "OverallStatus", string(ternary(overallOkay, ...
        "PASS - all patch archives valid and traceable", ...
        "REVIEW REQUIRED - see patch provenance table")), ...
    "InstrumentName", instrumentName, ...
    "InstrumentSerialNumber", instrumentSerialNumber, ...
    "InstrumentDriver", instrumentDriver, ...
    "Resolution", resolution, ...
    "CalibrationMethod", calibrationMethod);
end

function value = qualityStatus(valid, saturated, warning, comment, traceable)
parts = strings(0,1);
if valid, parts(end+1) = "valid"; else, parts(end+1) = "invalid"; end
if saturated, parts(end+1) = "saturated"; end
if ~traceable, parts(end+1) = "identity/hash mismatch"; end
if strlength(strtrim(warning)) > 0, parts(end+1) = "warning: " + warning; end
if strlength(strtrim(comment)) > 0, parts(end+1) = "comment: " + comment; end
value = join(parts, "; ");
end

function value = valueOrDash(container, field)
value = "-";
if isstruct(container) && isfield(container, field)
    candidate = strtrim(string(container.(field)));
    if isscalar(candidate) && strlength(candidate) > 0
        value = candidate;
    end
end
end

function value = targetValue(session, field)
value = "-";
if isfield(session, "Definition") && ...
        isfield(session.Definition, "TargetDefinition")
    value = valueOrDash(session.Definition.TargetDefinition, field);
end
end

function value = yesNo(condition)
value = string(ternary(condition, "yes", "no"));
end

function value = ternary(condition, trueValue, falseValue)
if condition, value = trueValue; else, value = falseValue; end
end

function value = wrapArchiveReference(value)
value = replace(value, "/", "/" + newline);
value = replace(value, "_", "_" + newline);
end

function value = wrapFixed(value, width)
parts = strings(0,1);
while strlength(value) > width
    parts(end+1,1) = extractBefore(value, width + 1); %#ok<AGROW>
    value = extractAfter(value, width);
end
parts(end+1,1) = value;
value = join(parts, newline);
end
