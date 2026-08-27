function tests=test_colorchecker_basePdfReports
tests=functiontests(localfunctions);
end

function testSessionReportUsesBasePdfBackend(testCase)
root=string(tempname); mkdir(root); cleanup=onCleanup(@() removeTree(root)); %#ok<NASGU>
mkdir(fullfile(root,"data")); mkdir(fullfile(root,"archive"));
manifest=struct("schema","spectralab.colorchecker-series.v1", ...
    "chart_name","Test chart","chart_manufactured_date","2026-08", ...
    "state","complete","started_unix",1,"updated_unix",2, ...
    "high_resolution",false,"instrument_id","test", ...
    "operator","Test operator","project","Test project", ...
    "comment","Visible measurement comment", ...
    "requested_patch_count",0,"completed_patch_count",0, ...
    "message","base MATLAB PDF test","records",struct.empty);
writeJson(fullfile(root,"data","series_manifest.json"),manifest);
info=spectralab.colorchecker.generateSessionReport(root);
verifyTrue(testCase,isfile(info.PDFFile));
verifyGreaterThan(testCase,dir(info.PDFFile).bytes,500);
verifyGreaterThanOrEqual(testCase,info.PDF.PageCount,1);
verifyFalse(testCase,info.ContainsPlot);
verifyEqual(testCase,info.MeasurementComment,"Visible measurement comment");
end

function writeJson(filename,value)
fid=fopen(filename,"w","n","UTF-8");
cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,"%s\n",jsonencode(value,PrettyPrint=true));
end

function removeTree(root)
if isfolder(root), rmdir(root,"s"); end
end
