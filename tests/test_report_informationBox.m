function tests = test_report_informationBox
%TEST_REPORT_INFORMATIONBOX Verify RP-013 reusable InformationBox.
tests = functiontests(localfunctions);
end

function testBuildsFixedMetadataAndDynamicResults(testCase)
context = makeContext();
model = spectralab.report.internal.buildInformationBox(context);
verifyEqual(testCase, model.Format, "SLAB-REPORT-INFORMATION-BOX");
verifyEqual(testCase, model.Title, "Information");
verifyEqual(testCase, [model.MetadataRows.Label], ["Measurement","Project","Sample","Operator","Date","Instrument","Analysis","Method","Archive"]);
verifyEqual(testCase, [model.ResultRows.Field], ["CCT","Duv","Ra"]);
verifyEqual(testCase, model.ResultRows(2).DisplayText, "+0.00482");
end

function testMissingMetadataUsesEmDash(testCase)
context = makeContext();
context.Measurement = struct("Name","Lamp");
context.Metadata = struct();
context.Instrument = struct();
model = spectralab.report.internal.buildInformationBox(context);
verifyEqual(testCase, model.MetadataRows(2).DisplayText, "—");
verifyEqual(testCase, model.MetadataRows(6).DisplayText, "—");
end

function testResultOrderFollowsAnalysisDefinition(testCase)
context = makeContext();
context.Analysis.ResultFields = context.Analysis.ResultFields([3 1]);
model = spectralab.report.internal.buildInformationBox(context);
verifyEqual(testCase, [model.ResultRows.Field], ["Ra","CCT"]);
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
context=rmfield(makeContext(),"Metadata");
verifyError(testCase,@() spectralab.report.internal.buildInformationBox(context),"SpectraLab:Report:InvalidInformationBoxContext");
end

function testInformationBoxCanBePlaced(testCase)
context=makeContext(); document=makeDocument();
[rc,rr]=spectralab.report.internal.renderDocumentModel(document,context,makeRenderContext());
[~,plan]=spectralab.report.internal.layoutRenderResults(rc,rr);
verifyTrue(testCase,plan.Measured); verifyGreaterThan(testCase,plan.Height,0);
end

function context=makeContext()
context.Archive=struct("Filename","lamp.mat","UUID","u","ContentHash","h");
context.Measurement=struct("Name","Lamp","Project","LED tables","Sample","Light Pad 940","Operator","Christer","Date",datetime(2026,7,28,10,0,0));
context.Metadata=struct();
context.Instrument=struct("Name","X-Rite i1Pro 2");
context.Result=struct("CCT",5045.123,"Duv",0.004821987,"Ra",95.4321);
context.Analysis=struct("AnalysisId","ANL-CRI","Name","Color Rendering Index","Method","CIE 13.3","Standard","CIE 13.3","DefinitionVersion","1","HasFigure",false,"ResultFields",[field("CCT","CCT","K","%.0f");field("Duv","Duv","","%+.5f");field("Ra","Ra","","%.1f")]);
context.Report=struct("ReportId","RPT-001","Warnings",strings(0,1));
end
function f=field(n,l,u,fmt), f=struct("Field",string(n),"Label",string(l),"Unit",string(u),"Format",string(fmt)); end
function d=makeDocument(), d=struct("Format","SLAB-REPORT-DOCUMENT","Version","1.0","Elements",struct("Id","InformationBox","Type","table","Role","informationBox","SourcePath","Report","Required",true)); end
function rc=makeRenderContext(), rc=struct("Format","SLAB-REPORT-RENDER-CONTEXT","Version","1.0","Graphics",struct("Figure",gobjects(0),"Axes",gobjects(0)),"TemporaryFiles",strings(0,1),"State",struct("CurrentPage",0,"CursorY",NaN)); end
