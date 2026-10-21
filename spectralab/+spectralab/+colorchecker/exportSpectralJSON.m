function document=exportSpectralJSON(sessionFile,outputFile)
%EXPORTSPECTRALJSON Self-contained measured patch spectra; no archive files needed by reader.
arguments,sessionFile (1,1) string,outputFile (1,1) string,end
assert(~isfile(outputFile),'SpectraLab:ColorChecker:OutputExists','Refusing to overwrite an existing JSON export.');
session=spectralab.colorchecker.load(sessionFile);
assert(all(string({session.Patches.State})=="measured"),'SpectraLab:ColorChecker:SessionIncomplete','Measure every patch before export.');
patches=struct('PatchID',{},'WavelengthNM',{},'Value',{},'Unit',{},'ArchiveUUID',{},'ArchiveContentHash',{});
for k=1:numel(session.Patches)
 p=session.Patches(k);file=string(p.ArchiveFile);if ~isfile(file),file=fullfile(string(session.Context.SessionFolder),file);end
 a=spectralab.archive.load(file,Quiet=true,Validation="error");
 assert(string(a.Identity.UUID)==string(p.ArchiveUUID) && string(a.Identity.ContentHash)==string(p.ArchiveContentHash),'SpectraLab:ColorChecker:PatchIdentity','Patch archive identity changed.');
 w=double(a.Measurement.Wavelength(:));v=double(a.Measurement.Value(:));unit=string(a.Measurement.Unit);
 assert(numel(w)==numel(v) && numel(w)>=2 && all(isfinite(w)) && all(diff(w)>0) && all(isfinite(v)),'Invalid patch spectrum.');
 assert(any(lower(unit)==["1","percent","%"]) || (contains(lower(unit),'reflectance') && contains(unit,'%')),'Unsupported reflectance unit.');
 patches(k)=struct('PatchID',char(p.Coordinate),'WavelengthNM',w,'Value',v,'Unit',char(unit),'ArchiveUUID',char(a.Identity.UUID),'ArchiveContentHash',char(a.Identity.ContentHash));
end
assert(isfield(session.Definition,'TargetDefinition'),'Select a controlled target definition before exporting.');
document=struct('Schema','spectralab.colorchecker-spectra.v1','Quantity','spectral_reflectance','Target',session.Definition.TargetDefinition,'PhysicalChart',session.Definition,'SessionUUID',char(session.Identity.UUID),'SessionIdentity',session.Identity,'MeasurementContext',session.Context,'PatchCount',numel(patches),'Patches',patches,'Processing',struct('Resampled',false,'WavelengthsCropped',false,'ValuesAndUnits','Original measured values and units'));
if isfield(session,'AcquisitionSettings'),document.AcquisitionSettings=session.AcquisitionSettings;end
if isfield(session,'Calibrations'),document.Calibrations=session.Calibrations;end
% Make JSON types explicit before computing the portable content hash.
document=jsondecode(jsonencode(document));document.ContentSHA256=spectralab.archive.jsonContentHash(document);
folder=string(fileparts(outputFile));if folder=="",folder=string(pwd);end;if ~isfolder(folder),mkdir(folder);end
staged=string(tempname(folder));clean=onCleanup(@() remove(staged));fid=fopen(staged,'w','n','UTF-8');assert(fid>=0);closed=onCleanup(@() fclose(fid));fprintf(fid,'%s\n',jsonencode(document));clear closed
[ok,msg]=movefile(staged,outputFile);assert(ok,'%s',msg);clear clean
end
function remove(file),if isfile(file),delete(file);end;end
