function document=exportEmission(archives,file,options)
%EXPORTEMISSION All recorded archive data plus original acquisition metadata.
arguments
 archives
 file (1,1) string
 options.Spectra={}
 options.Bindings=struct([])
end
if isstruct(archives),archives=num2cell(archives);end
assert(iscell(archives) && ~isempty(archives),'Supply one or more emission archives.');
records=struct('MeasurementID',{},'Name',{},'Binding',{},'Spectrum',{},'Archive',{},'Acquisition',{},'Dependencies',{});
for k=1:numel(archives)
 a=archives{k};v=spectralab.archive.validate(a);assert(v.IsValid,'%s',strjoin(v.Errors,newline));
 assert(any(strcmpi(string(a.Measurement.Context.Kind),["emission","emissive"])),'Only emitted-light spectra are supported.');
 binding=struct('Role','unassigned','FilmID','','RollID','','FrameID','','SeriesID','','ReferenceMeasurementID','');
 if ~isempty(options.Bindings),assert(numel(options.Bindings)==numel(archives),'One binding per archive required.');provided=options.Bindings(k);for field=string(fieldnames(provided))',binding.(field)=provided.(field);end;end
 acquisition=struct('Available',false,'Reason','Exported from an existing archive; no original Spectrum object supplied.');
 if ~isempty(options.Spectra)
  assert(numel(options.Spectra)==numel(archives),'One source Spectrum per archive required.');spec=options.Spectra{k};
  assert(isequal(spec.WavelengthNm,a.Measurement.Wavelength) && isequal(spec.Power,a.Measurement.Value),'Acquisition spectrum differs from archive.');
  acquisition=struct('Available',true,'Instrument',spec.Instrument,'Calibration',spec.Calibration,'Metadata',spec.Metadata,'Timestamp',spec.Timestamp,'Label',spec.Label,'PowerUnit',spec.PowerUnit);
 end
 dependencies=collectDependencies(a,strings(0,1));
 spectrum=struct('WavelengthNM',a.Measurement.Wavelength,'Value',a.Measurement.Value,'Unit',char(a.Measurement.Unit));
 records(k)=struct('MeasurementID',char(a.Identity.UUID),'Name',char(a.Measurement.Name),'Binding',binding,'Spectrum',spectrum,'Archive',spectralab.exchange.pack(a),'Acquisition',spectralab.exchange.pack(acquisition),'Dependencies',{dependencies});
end
assert(numel(unique(string({records.MeasurementID})))==numel(records),'Duplicate measurement identities.');
document=struct('Schema','spectralab.emission-spectra.v1','MeasurementCount',numel(records),'Spectra',records,'Processing',struct('Resampled',false,'Normalized',false,'Values','Original recorded signal and unit'));
spectralab.exchange.write(document,file);
end
function nodes=collectDependencies(a,seen)
nodes={};if ~isfield(a,'Derivation') || ~isfield(a.Derivation,'Sources'),return;end
for s=a.Derivation.Sources(:)'
 assert(~any(seen==string(s.UUID)),'Cyclic source provenance.');source=spectralab.archive.load(s.Filename,Quiet=true,Validation="error");
 assert(string(source.Identity.UUID)==string(s.UUID) && string(source.Identity.ContentHash)==string(s.ContentHash),'Derived spectrum source differs from its provenance.');
 nested=collectDependencies(source,[seen;string(a.Identity.UUID)]);nodes=[nodes,{spectralab.exchange.pack(source)},nested];
end
end
