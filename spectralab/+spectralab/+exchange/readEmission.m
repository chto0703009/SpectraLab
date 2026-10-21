function [archives,document]=readEmission(file)
%READEMISSION Verify JSON and original scientific archive identities losslessly.
document=jsondecode(fileread(file));assert(string(document.Schema)=="spectralab.emission-spectra.v1",'Unsupported emission JSON.');
payload=rmfield(document,'ContentSHA256');assert(strcmpi(document.ContentSHA256,spectralab.archive.jsonContentHash(payload)),'SpectraLab:Exchange:Hash','Emission JSON hash mismatch.');
assert(document.MeasurementCount==numel(document.Spectra) && document.MeasurementCount>0,'Invalid emission series count.');
assert(numel(unique(string({document.Spectra.MeasurementID})))==document.MeasurementCount,'Duplicate measurement identities.');
archives=cell(numel(document.Spectra),1);
for k=1:numel(archives)
 r=document.Spectra(k);a=spectralab.exchange.unpack(r.Archive);v=spectralab.archive.validate(a);assert(v.IsValid,'%s',strjoin(v.Errors,newline));
 assert(string(a.Identity.UUID)==string(r.MeasurementID) && isequal(double(a.Measurement.Wavelength(:)),double(r.Spectrum.WavelengthNM(:))) && isequal(double(a.Measurement.Value(:)),double(r.Spectrum.Value(:))) && string(a.Measurement.Unit)==string(r.Spectrum.Unit),'Archive and exposed spectrum disagree.');
 assert(any(strcmpi(string(a.Measurement.Context.Kind),["emission","emissive"])),'Expected an emission measurement.');
 dependencies=cell(numel(r.Dependencies),1);for j=1:numel(dependencies),if iscell(r.Dependencies),n=r.Dependencies{j};else,n=r.Dependencies(j);end;dependencies{j}=spectralab.exchange.unpack(n);check=spectralab.archive.validate(dependencies{j});assert(check.IsValid,'Invalid embedded source archive.');end
 a.Exchange=struct('Binding',r.Binding,'Acquisition',spectralab.exchange.unpack(r.Acquisition),'SourceJSONContentSHA256',document.ContentSHA256,'Dependencies',{dependencies});archives{k}=a;
end
end
