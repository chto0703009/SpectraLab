function tests=test_colorchecker_spectraJSON
tests=functiontests(localfunctions);
end
function testSelfContainedSpectraAndUnits(testCase)
root=string(tempname);mkdir(root);clean=onCleanup(@() rmdir(root,'s'));
s=spectralab.colorchecker.create(root,TargetDefinitionID="xrite-colorchecker-digital-sg-140",ChartSerialNumber="SYNTHETIC ÅÄÖ");
s=spectralab.colorchecker.recordCalibration(s,struct('name','synthetic'));
w=(380:10:780)';
for k=1:140
 id=string(s.Patches(k).Coordinate);spec=spectralab.core.Spectrum(w,repmat(k/2,size(w)),id,struct(),struct(),struct('measurement_kind','reflectance','signal_quantity','spectral reflectance factor'),'percent');
 a=spectralab.archive.create(spec);file=fullfile(root,'archive',id+'.mat');spectralab.archive.save(a,file);s=spectralab.colorchecker.recordMeasurement(s,id,file);
end
s=spectralab.colorchecker.save(s);file=fullfile(root,'spectra.json');d=spectralab.colorchecker.exportSpectralJSON(fullfile(root,'colorchecker_session.json'),file);
verifyEqual(testCase,d.PatchCount,140);verifyEqual(testCase,d.Patches(1).WavelengthNM,w);verifyEqual(testCase,d.Patches(140).Value,repmat(70,size(w)));verifyEqual(testCase,string(d.Patches(1).Unit),"percent");
verifyEqual(testCase,string(d.PhysicalChart.ChartSerialNumber),"SYNTHETIC ÅÄÖ");
r=jsondecode(fileread(file));verifyEqual(testCase,string(r.ContentSHA256),spectralab.archive.jsonContentHash(rmfield(r,'ContentSHA256')));
verifyError(testCase,@() spectralab.colorchecker.exportSpectralJSON(fullfile(root,'colorchecker_session.json'),file),'SpectraLab:ColorChecker:OutputExists');
end
function testIncompleteSessionRejected(testCase)
root=string(tempname);clean=onCleanup(@() rmdir(root,'s'));spectralab.colorchecker.create(root,TargetDefinitionID="xrite-colorchecker-digital-sg-140");
verifyError(testCase,@() spectralab.colorchecker.exportSpectralJSON(fullfile(root,'colorchecker_session.json'),fullfile(root,'out.json')),'SpectraLab:ColorChecker:SessionIncomplete');
verifyFalse(testCase,isfile(fullfile(root,'out.json')));
end
