function info=exportTabularPDF(pdfFile,titleText,reportId,sections)
%EXPORTTABULARPDF Export structured text and two-column tables using base MATLAB.
arguments
    pdfFile (1,1) string
    titleText (1,1) string
    reportId (1,1) string
    sections (:,1) struct
end
layout=spectralab.report.internal.createLayoutState();
records=repmat(record("","","",[]),0,1);
placements=repmat(placement("","",1,0,0),0,1);
page=1; y=0; sequence=0;
[records,placements,page,y,sequence]=addText(records,placements, ...
    page,y,sequence,"heading",titleText,layout);
for section=reshape(sections,1,[])
    [records,placements,page,y,sequence]=addText(records,placements, ...
        page,y,sequence,"heading",string(section.Title),layout);
    if isfield(section,"Text") && strlength(string(section.Text))>0
        [records,placements,page,y,sequence]=addText(records,placements, ...
            page,y,sequence,"paragraph",string(section.Text),layout);
    end
    rows=string(section.Rows);
    if isempty(rows), continue, end
    assert(size(rows,2)==2,"SpectraLab:Report:InvalidTabularRows", ...
        "Tabular PDF sections require exactly two columns.");
    first=1;
    while first<=size(rows,1)
        last=min(first+9,size(rows,1));
        model=tableModel(rows(first:last,:),string(section.Title));
        height=spectralab.report.internal.estimateResultsTableHeight(model);
        while height>layout.ContentHeight && last>first
            last=last-1;
            model=tableModel(rows(first:last,:),string(section.Title));
            height=spectralab.report.internal.estimateResultsTableHeight(model);
        end
        [page,y]=fit(page,y,height,layout);
        sequence=sequence+1; id="Element"+sequence;
        records(end+1,1)=record(id,"table","provenance",model); %#ok<AGROW>
        placements(end+1,1)=placement(id,"table",page,y,height); %#ok<AGROW>
        y=y+height; first=last+1;
    end
end
renderContext=struct("Format","SLAB-REPORT-RENDER-CONTEXT", ...
    "Version","1.0","Graphics",struct("Figure",gobjects(0), ...
    "Axes",gobjects(0)),"PageFrame",pageFrame( ...
        titleText,reportId,pdfFile), ...
    "TemporaryFiles",strings(0,1), ...
    "State",struct("RenderedElements",records));
info=spectralab.report.internal.exportPDF(pdfFile,placements,renderContext);
end

function [records,placements,page,y,sequence]=addText( ...
        records,placements,page,y,sequence,type,text,layout)
if type=="heading"
    style=struct("FontSize",16,"LineHeight",20,"SpaceAfter",8, ...
        "AverageGlyphWidthFactor",0.55);
else
    style=struct("FontSize",10,"LineHeight",14,"SpaceAfter",8, ...
        "AverageGlyphWidthFactor",0.52);
end
height=spectralab.report.internal.estimateTextHeight(text,style,layout.ContentWidth);
[page,y]=fit(page,y,height,layout);
sequence=sequence+1; id="Element"+sequence;
records(end+1,1)=record(id,type,"text",text);
placements(end+1,1)=placement(id,type,page,y,height);
y=y+height;
end

function [page,y]=fit(page,y,height,layout)
assert(height<=layout.ContentHeight,"SpectraLab:Report:ElementTooTall", ...
    "A tabular PDF element exceeds one page.");
if y>0 && y+height>layout.ContentHeight, page=page+1; y=0; end
end

function model=tableModel(values,titleText)
rows=repmat(struct("Label","","DisplayText","","LineCount",1),size(values,1),1);
for index=1:size(values,1)
    [label,labelLines]=spectralab.report.internal.wrapValue(values(index,1),28);
    % The provenance table uses 58 percent of an 82-percent-width box.
    % Thirty-eight characters keeps unbroken hashes inside that column.
    [value,valueLines]=spectralab.report.internal.wrapValue(values(index,2),38);
    rows(index)=struct("Label",label,"DisplayText",value, ...
        "LineCount",max(labelLines,valueLines));
end
model=struct("Format","SLAB-REPORT-TABLE","Version","1.0", ...
    "Role","provenance","Title",titleText,"Columns",["Label","Value"], ...
    "Rows",rows);
end

function value=record(id,type,role,content)
value=struct("Id",string(id),"Type",string(type), ...
    "Role",string(role),"Content",content);
end

function value=placement(id,type,page,y,height)
value=struct("ElementId",string(id),"ElementType",string(type), ...
    "Page",double(page),"Y",double(y),"Height",double(height), ...
    "Measured",true,"ExplicitPageBreak",false, ...
    "AutomaticPageBreak",false);
end

function model=pageFrame(titleText,reportId,pdfFile)
[~,name,extension]=fileparts(pdfFile);
model=struct("Format","SLAB-REPORT-PAGE-FRAME","Version","1.0", ...
    "HeaderLeft","SpectraLab","HeaderRight",titleText, ...
    "FooterFilename",string(name)+string(extension), ...
    "FooterLeft","Report ID "+reportId, ...
    "FooterCenter","SpectraLab "+spectralab.version());
end
