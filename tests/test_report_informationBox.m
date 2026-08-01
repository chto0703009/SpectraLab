function tests = test_report_informationBox
%TEST_REPORT_INFORMATIONBOX Verify RP-013 reusable InformationBox.
tests = functiontests(localfunctions);
end

function testBuildsFixedMetadataAndDynamicResults(testCase)
context = makeContext();
model = spectralab.report.internal.buildInformationBox(context);
verifyEqual(testCase, model.Format, "SLAB-REPORT-INFORMATION-BOX");
verifyEqual(testCase, model.Title, "Information");
verifyEqual(testCase, [model.MeasurementInformationRows.Label], ["Measurement","Project","Sample","Operator","Date","Comment","Instrument","Analysis","Method","Archive"]);
verifyEqual(testCase, model.MeasurementInformationRows(6).DisplayText, ...
    "Stability run after warm-up");
verifyEmpty(testCase, model.ResultRows);
end

function testMissingMetadataUsesEmDash(testCase)
context = makeContext();
context.Measurement = struct("Name","Lamp");
context.MeasurementInformation = struct("Name","Lamp");
context.Instrument = struct();
model = spectralab.report.internal.buildInformationBox(context);
verifyEqual(testCase, model.MeasurementInformationRows(2).DisplayText, "—");
verifyEqual(testCase, model.MeasurementInformationRows(7).DisplayText, "—");
end

function testInformationBoxNeverDuplicatesAnalysisResults(testCase)
context = makeContext();
model = spectralab.report.internal.buildInformationBox(context);
verifyEmpty(testCase, model.ResultRows);
verifyFalse(testCase, any(contains( ...
    [model.MeasurementInformationRows.Label], "density", ...
    IgnoreCase=true)));
end

function testPairAnalysisOmitsMisleadingSingleArchiveRow(testCase)
context = makeContext();
context.Analysis.AnalysisId = "ANL-009";
model = spectralab.report.internal.buildInformationBox(context);
verifyFalse(testCase, any( ...
    [model.MeasurementInformationRows.Label] == "Archive"));
end

function testAnyTwoSourceAnalysisIdentifiesBothArchives(testCase)
context = makeContext();
context.Analysis.AnalysisId = "ANL-005";
source = struct("Role", "", "Filename", "", "Measurement", struct(), ...
    "Metadata", struct());
source(1) = struct("Role", "Reference", "Filename", "reference.mat", ...
    "Measurement", struct("Name", "Reference measurement"), ...
    "Metadata", struct("SampleID", "Reference sample", ...
        "Comment", "Reference comment"));
source(2) = struct("Role", "Sample", "Filename", "sample.mat", ...
    "Measurement", struct("Name", "Sample measurement"), ...
    "Metadata", struct("SampleID", "Sample sample", ...
        "Comment", "Sample comment"));
context.SourceArchives = source;

model = spectralab.report.internal.buildInformationBox(context);
labels = [model.MeasurementInformationRows.Label];
values = [model.MeasurementInformationRows.DisplayText];
verifyTrue(testCase, any(labels == "Reference archive"));
verifyTrue(testCase, any(labels == "Sample archive"));
verifyTrue(testCase, any(labels == "Reference sample ID"));
verifyTrue(testCase, any(labels == "Sample ID"));
verifyTrue(testCase, any(values == "reference.mat"));
verifyTrue(testCase, any(values == "sample.mat"));
end

function testRendererReturnsFiniteHeightAndStoresModel(testCase)
context = makeContext();
document = makeDocument();
[rc,result] = spectralab.report.internal.renderDocumentModel(document,context,makeRenderContext());
verifyTrue(testCase,isfinite(result.HeightUsed));
verifyEqual(testCase,rc.State.RenderedElements.Content.Format,"SLAB-REPORT-INFORMATION-BOX");
end

function testManifestIncludesInformationBoxAfterTitle(testCase)
context = makeContext(); context.Analysis.HasFigure=false; context.Report.Warnings=strings(0,1);
manifest = spectralab.report.internal.buildManifest(context);
sectionIds = [manifest.Sections.Id];
verifyEqual(testCase,sectionIds(1:2),["Title","InformationBox"]);
verifyEqual(testCase,manifest.Sections(2).Component,"informationBox");
end

function testDoesNotModifyContext(testCase)
context=makeContext(); before=context;
spectralab.report.internal.buildInformationBox(context);
verifyEqual(testCase,context,before);
end

function testRejectsIncompleteContext(testCase)
context=rmfield(makeContext(),"MeasurementInformation");
verifyError(testCase,@() spectralab.report.internal.buildInformationBox(context),"SpectraLab:Report:InvalidInformationBoxContext");
end

function testInformationBoxCanBePlaced(testCase)
context=makeContext(); document=makeDocument();
[rc,rr]=spectralab.report.internal.renderDocumentModel(document,context,makeRenderContext());
[~,plan]=spectralab.report.internal.layoutRenderResults(rc,rr);
verifyTrue(testCase,plan.Measured); verifyGreaterThan(testCase,plan.Height,0);
end

function testLongArchiveFilenameIncreasesInformationBoxHeight(testCase)
context = makeContext();
shortModel = spectralab.report.internal.buildInformationBox(context);
shortHeight = spectralab.report.internal.estimateInformationBoxHeight(shortModel);
context.Archive.Filename = ...
    "C41_very_long_descriptive_measurement_name_20260801_reference.mat";
longModel = spectralab.report.internal.buildInformationBox(context);
longHeight = spectralab.report.internal.estimateInformationBoxHeight(longModel);

archiveRow = longModel.MeasurementInformationRows(end);
verifyEqual(testCase, archiveRow.LineCount, 2);
verifyEqual(testCase, count(archiveRow.DisplayText, newline), 1);
verifyGreaterThan(testCase, longHeight, shortHeight);
end

function context=makeContext()
context.Archive=struct("Filename","lamp.mat","UUID","u","ContentHash","h");
context.Measurement=struct("Name","Lamp");
context.MeasurementInformation=struct( ...
    "Name","Lamp", ...
    "Project","LED tables", ...
    "Sample","Light Pad 940", ...
    "Operator","Christer", ...
    "Date",datetime(2026,7,28,10,0,0), ...
    "Comment","Stability run after warm-up");
context.Instrument=struct("Name","X-Rite i1Pro 2");
context.Result=struct("CCT",5045.123,"Duv",0.004821987,"Ra",95.4321);
context.Analysis=struct("AnalysisId","ANL-CRI","Name","Color Rendering Index","Method","CIE 13.3","Standard","CIE 13.3","DefinitionVersion","1","HasFigure",false,"ResultFields",[field("CCT","CCT","K","%.0f");field("Duv","Duv","","%+.5f");field("Ra","Ra","","%.1f")]);
context.Report=struct("ReportId","RPT-001","Warnings",strings(0,1));
end
function f=field(n,l,u,fmt), f=struct("Field",string(n),"Label",string(l),"Unit",string(u),"Format",string(fmt)); end
function d=makeDocument(), d=struct("Format","SLAB-REPORT-DOCUMENT","Version","1.0","Elements",struct("Id","InformationBox","Type","table","Role","informationBox","SourcePath","Report","Required",true)); end
function rc=makeRenderContext(), rc=struct("Format","SLAB-REPORT-RENDER-CONTEXT","Version","1.0","Graphics",struct("Figure",gobjects(0),"Axes",gobjects(0)),"TemporaryFiles",strings(0,1),"State",struct("CurrentPage",0,"CursorY",NaN)); end
