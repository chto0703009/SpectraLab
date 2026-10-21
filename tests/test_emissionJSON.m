function tests=test_emissionJSON
tests=functiontests(localfunctions);
end
function testLosslessDataAndAcquisition(testCase)
folder=string(tempname);mkdir(folder);clean=onCleanup(@() rmdir(folder,'s'));
metadata=struct('measurement_kind','emissive','signal_quantity','spectral power','Operator','ÅÄÖ','raw_transcript',"Raw instrument data"+newline+"λ",'Integer',uint64(18446744073709551615),'Auxiliary',[NaN Inf -Inf]);
cal=struct('Timestamp',datetime('now','TimeZone','Europe/Stockholm'),'CalibrationID','CAL');
s=spectralab.core.Spectrum((380:10:780)',ones(41,1),'Lamp',struct('Driver','spotread','SerialNumber','TEST'),cal,metadata,'arbitrary');a=spectralab.archive.create(s);
file=fullfile(folder,'lamp.json');spectralab.exchange.exportEmission({a},file,Spectra={s});[b,d]=spectralab.exchange.readEmission(file);
verifyEqual(testCase,rmfield(b{1},'Exchange'),a);verifyEqual(testCase,b{1}.Exchange.Acquisition.Metadata,metadata);verifyEqual(testCase,b{1}.Exchange.Acquisition.Calibration,cal);
verifyEqual(testCase,d.Spectra.Spectrum.Value,ones(41,1));verifyError(testCase,@() spectralab.exchange.exportEmission({a},file),'SpectraLab:Exchange:OutputExists');
end
function testTamperingRejected(testCase)
folder=string(tempname);mkdir(folder);clean=onCleanup(@() rmdir(folder,'s'));s=fixture();a=spectralab.archive.create(s);file=fullfile(folder,'a.json');spectralab.exchange.exportEmission({a},file);d=jsondecode(fileread(file));d.Spectra.Spectrum.Value(1)=12;fid=fopen(file,'w');fprintf(fid,'%s',jsonencode(d));fclose(fid);
verifyError(testCase,@() spectralab.exchange.readEmission(file),'SpectraLab:Exchange:Hash');
end
function testSeriesRequiresNamedSelection(testCase)
folder=string(tempname);mkdir(folder);clean=onCleanup(@() rmdir(folder,'s'));a=spectralab.archive.create(fixture());b=spectralab.archive.create(fixture());file=fullfile(folder,'series.json');spectralab.exchange.exportEmission({a,b},file);
verifyError(testCase,@() spectralab.archive.load(file,Quiet=true,Validation="error"),'SpectraLab:Exchange:SelectMeasurement');
end
function testTypedDataRoundtrip(testCase)
v=struct('EmptyStruct',struct('Field',{}),'EmptyStrings',strings(0),'Missing',["a",missing],'Logical',[true false],'Integer',int64(-9223372036854775808),'Numeric',single([NaN Inf 0]),'Char','ÅÄÖ','Cells',{{NaT(0,1),{1,'x'}}});
verifyEqual(testCase,spectralab.exchange.unpack(spectralab.exchange.pack(v)),v);
end
function s=fixture()
s=spectralab.core.Spectrum((400:10:730)',ones(34,1),'Test',struct('Driver','spotread'),struct(),struct('measurement_kind','emissive','signal_quantity','spectral power'),'arbitrary');
end
