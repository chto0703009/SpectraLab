function info = exportPDF(pdfFile, layoutPlan, renderContext)
%EXPORTPDF Export a minimal self-contained A4 portrait PDF.
%
%   info = spectralab.report.internal.exportPDF( ...
%       pdfFile, layoutPlan, renderContext)
%
% RP-017a renders heading, paragraph, tables, spacer, captions, and the
% actual report-owned figure. It reads the completed LayoutPlan and
% RenderContext only; it performs no analysis or layout calculations.

arguments
    pdfFile (1,1) string
    layoutPlan (:,1) struct
    renderContext (1,1) struct
end

pdfFile = validateTarget(pdfFile);
validateInputs(layoutPlan, renderContext);

folder = string(fileparts(pdfFile));
if folder == ""
    folder = string(pwd);
end

temporaryFile = string(tempname(folder)) + ".pdf";
cleanupTemporary = onCleanup(@() deleteIfExists(temporaryFile)); %#ok<NASGU>

pageCount = max([layoutPlan.Page], [], "omitmissing");
if isempty(pageCount) || pageCount < 1
    pageCount = 1;
end

layout = spectralab.report.internal.createLayoutState();
records = renderContext.State.RenderedElements;

for page = 1:pageCount
    fig = createPageFigure(layout);
    cleanupFigure = onCleanup(@() closeIfValid(fig)); %#ok<NASGU>

    pagePlacements = layoutPlan([layoutPlan.Page] == page);
    for k = 1:numel(pagePlacements)
        placement = pagePlacements(k);
        if placement.ExplicitPageBreak
            continue
        end
        if ~placement.Measured
            error("SpectraLab:Report:UnmeasuredPDFElement", ...
                "PDF export requires a measured element. Element '%s' has no layout height.", ...
                placement.ElementId);
        end

        record = findRecord(records, placement.ElementId);
        drawElement(fig, layout, placement, record, renderContext);
    end

    if page == 1
        exportgraphics(fig, temporaryFile, ...
            "ContentType", "vector", ...
            "BackgroundColor", "white");
    else
        exportgraphics(fig, temporaryFile, ...
            "ContentType", "vector", ...
            "BackgroundColor", "white", ...
            "Append", true);
    end

    closeIfValid(fig);
    clear cleanupFigure
end

[ok, message] = movefile(temporaryFile, pdfFile);
if ~ok
    error("SpectraLab:Report:PDFExportFailed", ...
        "Unable to finalize PDF report '%s': %s", pdfFile, message);
end

info = struct( ...
    "PDFFile", pdfFile, ...
    "PageCount", double(pageCount), ...
    "Format", "PDF", ...
    "PageSize", "A4", ...
    "Orientation", "portrait");
end

function pdfFile = validateTarget(pdfFile)
pdfFile = string(pdfFile);
if ~endsWith(lower(pdfFile), ".pdf")
    error("SpectraLab:Report:InvalidPDFFile", ...
        "PDF output filename must use the .pdf extension.");
end

folder = string(fileparts(pdfFile));
if folder ~= "" && ~isfolder(folder)
    error("SpectraLab:Report:OutputFolderNotFound", ...
        "PDF output folder does not exist: %s", folder);
end

if isfile(pdfFile)
    error("SpectraLab:Report:ReportFileAlreadyExists", ...
        "Report file already exists: %s", pdfFile);
end
end

function validateInputs(layoutPlan, renderContext)
requiredPlacement = ["ElementId", "ElementType", "Page", "Y", ...
    "Height", "Measured", "ExplicitPageBreak", "AutomaticPageBreak"];
for k = 1:numel(layoutPlan)
    for j = 1:numel(requiredPlacement)
        if ~isfield(layoutPlan(k), requiredPlacement(j))
            error("SpectraLab:Report:InvalidLayoutPlan", ...
                "LayoutPlan entry is missing required field '%s'.", ...
                requiredPlacement(j));
        end
    end
end

if ~isfield(renderContext, "State") || ...
        ~isfield(renderContext.State, "RenderedElements") || ...
        ~isstruct(renderContext.State.RenderedElements)
    error("SpectraLab:Report:InvalidRenderContext", ...
        "RenderContext must contain State.RenderedElements.");
end
end

function fig = createPageFigure(layout)
fig = figure( ...
    "Visible", "off", ...
    "Color", "white", ...
    "Units", "points", ...
    "Position", [100 100 layout.PageWidth layout.PageHeight], ...
    "PaperUnits", "points", ...
    "PaperSize", [layout.PageWidth layout.PageHeight], ...
    "PaperPosition", [0 0 layout.PageWidth layout.PageHeight], ...
    "InvertHardcopy", "off", ...
    "MenuBar", "none", ...
    "ToolBar", "none");

% A full-page background axes prevents exportgraphics from tightly cropping
% the document to its annotations. This preserves the physical A4 canvas and
% therefore the declared 20 mm page margins.
bg = axes(fig, ...
    "Units", "normalized", ...
    "Position", [0 0 1 1], ...
    "XLim", [0 1], ...
    "YLim", [0 1], ...
    "Color", "white", ...
    "Visible", "off", ...
    "HitTest", "off", ...
    "HandleVisibility", "off");
rectangle(bg, "Position", [0 0 1 1], ...
    "FaceColor", "white", ...
    "EdgeColor", "none", ...
    "HitTest", "off", ...
    "HandleVisibility", "off");
end

function record = findRecord(records, elementId)
matches = string({records.Id}) == string(elementId);
if nnz(matches) ~= 1
    error("SpectraLab:Report:MissingRenderedElement", ...
        "Expected exactly one rendered element for '%s'.", elementId);
end
record = records(matches);
end

function drawElement(fig, layout, placement, record, renderContext)
type = string(record.Type);
switch type
    case "heading"
        drawTextBox(fig, layout, placement, string(record.Content), ...
            16, "bold", "left");
    case "paragraph"
        drawTextBox(fig, layout, placement, string(record.Content), ...
            10, "normal", "left");
    case "table"
        if string(record.Role) == "informationBox"
            drawInformationBox(fig, layout, placement, record.Content);
        else
            drawResultsTable(fig, layout, placement, record.Content);
        end
    case "figure"
        drawReportFigure(fig, layout, placement, record.Content, renderContext);
    case "caption"
        drawFigureCaption(fig, layout, placement, record.Content);
    case "spacer"
        % A spacer consumes layout height but draws no marks.
    otherwise
        error("SpectraLab:Report:UnsupportedPDFElement", ...
            "RP-012 PDF backend does not support element type '%s'.", type);
end
end

function drawTextBox(fig, layout, placement, content, fontSize, fontWeight, alignment)
pos = normalizedBox(layout, placement, layout.ContentWidth);
annotation(fig, "textbox", pos, ...
    "String", char(content), ...
    "Interpreter", "none", ...
    "FontName", "Helvetica", ...
    "FontSize", fontSize, ...
    "FontWeight", fontWeight, ...
    "HorizontalAlignment", alignment, ...
    "VerticalAlignment", "top", ...
    "EdgeColor", "none", ...
    "Margin", 0, ...
    "FitBoxToText", "off");
end

function drawResultsTable(fig, layout, placement, model)
if ~isstruct(model) || ~isfield(model, "Rows")
    error("SpectraLab:Report:InvalidPDFTable", ...
        "PDF table element does not contain a valid table model.");
end

rowCount = numel(model.Rows);
if rowCount == 0
    return
end
rowHeight = placement.Height / rowCount;
labelWidth = layout.ContentWidth * 0.58;
valueWidth = layout.ContentWidth - labelWidth;

for k = 1:rowCount
    rowPlacement = placement;
    rowPlacement.Y = placement.Y + (k-1) * rowHeight;
    rowPlacement.Height = rowHeight;

    labelBox = normalizedBox(layout, rowPlacement, labelWidth);
    valueBox = normalizedBox(layout, rowPlacement, valueWidth);
    valueBox(1) = valueBox(1) + labelWidth / layout.PageWidth;

    annotation(fig, "textbox", labelBox, ...
        "String", char(string(model.Rows(k).Label)), ...
        "Interpreter", "none", "FontName", "Helvetica", ...
        "FontSize", 10, "EdgeColor", "none", "Margin", 0, ...
        "VerticalAlignment", "middle", "FitBoxToText", "off");
    annotation(fig, "textbox", valueBox, ...
        "String", char(string(model.Rows(k).DisplayText)), ...
        "Interpreter", "none", "FontName", "Helvetica", ...
        "FontSize", 10, "EdgeColor", "none", "Margin", 0, ...
        "HorizontalAlignment", "right", ...
        "VerticalAlignment", "middle", "FitBoxToText", "off");
end
end

function drawInformationBox(fig, layout, placement, model)
if ~isstruct(model) || ~isfield(model,"MetadataRows") || ~isfield(model,"ResultRows")
    error("SpectraLab:Report:InvalidInformationBox", ...
        "PDF InformationBox element has an invalid model.");
end
pos = normalizedBox(layout, placement, layout.ContentWidth);
annotation(fig, "rectangle", pos, "LineWidth", 0.75);
rows = [model.MetadataRows; metadataFromResults(model.ResultRows)];
if isempty(rows), return, end
padding = 6;
inner = placement;
inner.Y = placement.Y + padding;
inner.Height = placement.Height - 2*padding;
rowHeight = inner.Height / numel(rows);
labelWidth = layout.ContentWidth * 0.42;
valueWidth = layout.ContentWidth - labelWidth;
for k = 1:numel(rows)
    rp = inner; rp.Y = inner.Y + (k-1)*rowHeight; rp.Height = rowHeight;
    lb = normalizedBox(layout,rp,labelWidth);
    vb = normalizedBox(layout,rp,valueWidth);
    vb(1) = vb(1) + labelWidth/layout.PageWidth;
    annotation(fig,"textbox",lb,"String",char(rows(k).Label), ...
        "Interpreter","none","FontName","Helvetica","FontSize",8, ...
        "FontWeight","bold","EdgeColor","none","Margin",2, ...
        "VerticalAlignment","middle","FitBoxToText","off");
    annotation(fig,"textbox",vb,"String",char(rows(k).DisplayText), ...
        "Interpreter","none","FontName","Helvetica","FontSize",8, ...
        "EdgeColor","none","Margin",2,"VerticalAlignment","middle", ...
        "FitBoxToText","off");
end
end

function rows = metadataFromResults(resultRows)
rows = repmat(struct("Label","","DisplayText",""),numel(resultRows),1);
for k=1:numel(resultRows)
    rows(k).Label = string(resultRows(k).Label);
    rows(k).DisplayText = string(resultRows(k).DisplayText);
end
end

function drawFigureCaption(fig, layout, placement, model)
if ~isstruct(model) || ~isfield(model, "Text") || ...
        string(model.Role) ~= "primaryFigureCaption"
    error("SpectraLab:Report:InvalidFigureCaption", ...
        "PDF caption element does not contain a valid figure-caption model.");
end
pos = normalizedBox(layout, placement, layout.ContentWidth);
annotation(fig, "textbox", pos, ...
    "String", char(string(model.Text)), ...
    "Interpreter", "none", ...
    "FontName", "Helvetica", ...
    "FontSize", 9, ...
    "FontAngle", "italic", ...
    "HorizontalAlignment", "center", ...
    "VerticalAlignment", "top", ...
    "EdgeColor", "none", ...
    "Margin", 0, ...
    "FitBoxToText", "off");
end

function drawReportFigure(fig, layout, placement, model, renderContext)
if ~isstruct(model) || ~isfield(model, "Width") || ~isfield(model, "Height")
    error("SpectraLab:Report:InvalidPDFFigure", ...
        "PDF figure element does not contain a valid figure model.");
end
if ~isfield(renderContext, "Graphics") || ...
        ~isfield(renderContext.Graphics, "Axes") || ...
        ~isscalar(renderContext.Graphics.Axes) || ...
        ~isgraphics(renderContext.Graphics.Axes, "axes")
    error("SpectraLab:Report:MissingFigureGraphics", ...
        "PDF export requires one valid report-owned source axes for the figure element.");
end

width = min(double(model.Width), layout.ContentWidth);
height = double(placement.Height);
pos = normalizedBox(layout, placement, width);
pos(1) = pos(1) + (layout.ContentWidth - width) / (2 * layout.PageWidth);

sourceAxes = renderContext.Graphics.Axes;
reportAxes = copyobj(sourceAxes, fig);
set(reportAxes, ...
    "Units", "normalized", ...
    "Position", pos, ...
    "ActivePositionProperty", "position", ...
    "HandleVisibility", "off");
end

function pos = normalizedBox(layout, placement, width)
x = layout.MarginLeft / layout.PageWidth;
yBottomPoints = layout.PageHeight - layout.MarginTop - ...
    placement.Y - placement.Height;
y = yBottomPoints / layout.PageHeight;
w = width / layout.PageWidth;
h = placement.Height / layout.PageHeight;
pos = [x y w h];
end

function deleteIfExists(file)
if isfile(file)
    delete(file);
end
end

function closeIfValid(fig)
if ~isempty(fig) && isgraphics(fig)
    close(fig);
end
end
