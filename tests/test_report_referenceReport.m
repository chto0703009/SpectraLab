function tests = test_report_referenceReport
%TEST_REPORT_REFERENCEREPORT Verify RP-017 end-to-end demonstrator.
tests = functiontests(localfunctions);
end

function testCreatesReferencePDFAndPNG(testCase)
folder = string(tempname); mkdir(folder);
cleanup = onCleanup(@() removeFolder(folder)); %#ok<NASGU>
info = generate_reference_cri_report(folder);
verifyTrue(testCase,isfile(info.PDFFile));
verifyTrue(testCase,isfile(info.PNGFile));
verifyGreaterThan(testCase,dir(info.PDFFile).bytes,1000);
verifyGreaterThan(testCase,dir(info.PNGFile).bytes,1000);
verifyGreaterThanOrEqual(testCase,info.PDF.PageCount,1);
verifyTrue(testCase,any([info.Manifest.Sections.Id] == "Figure"));
verifyTrue(testCase,any([info.LayoutPlan.ElementId] == "FigureCaption"));
end

function testRefusesOverwrite(testCase)
folder = string(tempname); mkdir(folder);
cleanup = onCleanup(@() removeFolder(folder)); %#ok<NASGU>
generate_reference_cri_report(folder);
verifyError(testCase,@() generate_reference_cri_report(folder), ...
    "SpectraLab:Report:ReportFileAlreadyExists");
end

function removeFolder(folder)
if isfolder(folder), rmdir(folder,"s"); end
end
