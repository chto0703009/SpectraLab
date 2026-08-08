function info = generateSessionReport(sessionFolder, options)
%GENERATESESSIONREPORT Document one complete ColorChecker acquisition.
%
% This report deliberately contains no plot, XYZ or Lab values. It records
% only session definition, acquisition provenance and patch archive status.

arguments
    sessionFolder (1,1) string
    options.OpenPDF (1,1) logical = false
end
sessionFolder = string(sessionFolder);
manifestFile = fullfile(sessionFolder, "data", "series_manifest.json");
if ~isfile(manifestFile)
    error("SpectraLab:ColorChecker:SessionManifestMissing", ...
        "ColorChecker session manifest not found:\n%s", manifestFile);
end
manifest = jsondecode(fileread(manifestFile));
reportFolder = fullfile(sessionFolder, "report");
if ~isfolder(reportFolder), mkdir(reportFolder); end
[~, sessionName] = fileparts(sessionFolder);
pdfFile = fullfile(reportFolder, string(sessionName) + "_session_report.pdf");
if isfile(pdfFile)
    error("SpectraLab:ColorChecker:SessionReportExists", ...
        "Session report already exists and will not be overwritten:\n%s", pdfFile);
end

import mlreportgen.dom.*
document = Document(char(erase(pdfFile, ".pdf")), "pdf");
cleanup = onCleanup(@() closeIfOpen(document));
layout = PDFPageLayout;
layout.PageSize.Orientation = "portrait";
layout.PageSize.Width = "210mm";
layout.PageSize.Height = "297mm";
layout.PageMargins.Top = "18mm";
layout.PageMargins.Bottom = "18mm";
layout.PageMargins.Left = "16mm";
layout.PageMargins.Right = "16mm";
append(document, layout);

title = Paragraph("ColorChecker measurement session");
title.Style = {FontFamily("Helvetica"), FontSize("20pt"), Bold(true), ...
    Color("#1F4E79")};
append(document, title);
subtitle = Paragraph(stringValue(manifest, "chart_name", sessionName));
subtitle.Style = {FontFamily("Helvetica"), FontSize("12pt"), ...
    Color("#555555")};
append(document, subtitle);

append(document, heading("Session definition"));
definition = {
    "ColorChecker name", stringValue(manifest, "chart_name", "-");
    "Manufactured/created", stringValue(manifest, "chart_manufactured_date", "-");
    "Session folder", sessionName;
    "Manifest schema", stringValue(manifest, "schema", "-");
    "Session state", upper(stringValue(manifest, "state", "unknown"));
    "Started", unixTime(manifest, "started_unix");
    "Last update", unixTime(manifest, "updated_unix")};
append(document, keyValueTable(definition));

append(document, heading("Acquisition"));
resolution = "Standard";
if logicalValue(manifest, "high_resolution", false), resolution = "High resolution"; end
acquisition = {
    "Instrument", stringValue(manifest, "instrument_id", "-");
    "Spectral resolution", resolution;
    "Requested patches", numericValue(manifest, "requested_patch_count", 0);
    "Completed patches", numericValue(manifest, "completed_patch_count", 0);
    "Session message", stringValue(manifest, "message", "-")};
append(document, keyValueTable(acquisition));

append(document, heading("Patch archive documentation"));
intro = Paragraph( ...
    "This table documents acquisition and archive identity only.");
intro.Style = {FontFamily("Helvetica"), FontSize("9pt"), ...
    Color("#555555")};
append(document, intro);

records = manifest.records;
rows = cell(max(1,numel(records))+1, 4);
rows(1,:) = {"Patch", "State", "Archive", "Measured"};
archiveFolder = fullfile(sessionFolder, "archive");
for index = 1:numel(records)
    coordinate = string(records(index).coordinate);
    archives = dir(fullfile(archiveFolder, coordinate + "_*.mat"));
    if isempty(archives)
        rows(index+1,:) = {coordinate, "MISSING", "-", "-"};
        continue
    end
    archiveFile = fullfile(archives(1).folder, archives(1).name);
    archive = spectralab.archive.load(archiveFile, Quiet=true, Validation="error");
    rows(index+1,:) = {coordinate, "Archived", string(archives(1).name), ...
        displayDate(archive.Identity.Created)};
end
if isempty(records)
    rows(2,:) = {"-", "No patches", "-", "-"};
end
patchTable = Table(rows);
patchTable.Style = {Border("solid","#B8C4CE","0.5pt"), ...
    RowSep("solid","#D9E0E5","0.25pt"), ...
    ColSep("solid","#D9E0E5","0.25pt"), Width("100%"), ...
    FontFamily("Helvetica"), FontSize("8pt")};
patchTable.TableEntriesHAlign = "left";
patchTable.TableEntriesVAlign = "middle";
for column = 1:4
    patchTable.Children(1).Children(column).Style = { ...
        BackgroundColor("#DCE6F1"), Bold(true), FontSize("7pt")};
end
append(document, patchTable);

identityNote = Paragraph( ...
    "Complete archive UUID and SHA-256 content identity are retained in " + ...
    "each standard SpectraLab patch archive.");
identityNote.Style = {FontFamily("Helvetica"), FontSize("8pt"), ...
    Color("#555555")};
append(document, identityNote);

append(document, heading("File locations"));
locations = {
    "Session manifest", relativePath(manifestFile, sessionFolder);
    "Raw acquisition data", "data/";
    "Patch archives", "archive/";
    "This report", "report/" + string(sessionName) + "_session_report.pdf"};
append(document, keyValueTable(locations));

close(document);
clear cleanup
info = struct("PDFFile", pdfFile, "SessionFolder", sessionFolder, ...
    "PatchCount", numel(records), "ContainsPlot", false, ...
    "ContainsXYZ", false, "ContainsLab", false);
if options.OpenPDF, open(char(pdfFile)); end
end

function p = heading(text)
import mlreportgen.dom.*
p = Paragraph(text);
p.Style = {FontFamily("Helvetica"), FontSize("12pt"), Bold(true), ...
    Color("#1F4E79")};
end

function table = keyValueTable(rows)
import mlreportgen.dom.*
table = Table(rows);
table.Style = {Border("solid","#B8C4CE","0.5pt"), ...
    RowSep("solid","#D9E0E5","0.25pt"), ...
    ColSep("solid","#D9E0E5","0.25pt"), Width("100%"), ...
    FontFamily("Helvetica"), FontSize("8.5pt")};
for index = 1:numel(table.Children)
    table.Children(index).Children(1).Style = { ...
        BackgroundColor("#EEF3F7"), Bold(true), Width("35%")};
end
end

function value = stringValue(source, field, fallback)
if isfield(source, field), value = string(source.(field)); else, value = string(fallback); end
if strlength(strtrim(value)) == 0, value = string(fallback); end
end

function value = numericValue(source, field, fallback)
if isfield(source, field), value = double(source.(field)); else, value = fallback; end
end

function value = logicalValue(source, field, fallback)
if isfield(source, field), value = logical(source.(field)); else, value = fallback; end
end

function value = unixTime(source, field)
if ~isfield(source, field), value = "-"; return, end
value = string(datetime(double(source.(field)), "ConvertFrom", "posixtime", ...
    "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss Z"));
end

function value = displayDate(input)
if isdatetime(input), value = string(input, "yyyy-MM-dd HH:mm:ss"); ...
else, value = string(input); end
end

function value = relativePath(path, root)
value = erase(string(path), string(root) + filesep);
end

function closeIfOpen(document)
try
    close(document);
catch
end
end
