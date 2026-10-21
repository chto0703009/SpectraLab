function write(document,file)
%WRITE Atomic, checked standalone exchange JSON without overwriting prior exports.
assert(~isfile(file),'SpectraLab:Exchange:OutputExists','Export already exists.');
document=jsondecode(jsonencode(document));document.ContentSHA256=spectralab.archive.jsonContentHash(document);
folder=string(fileparts(file));if folder=="",folder=string(pwd);end;if ~isfolder(folder),mkdir(folder);end
staged=string(tempname(folder));clean=onCleanup(@() remove(staged));fid=fopen(staged,'w','n','UTF-8');assert(fid>=0);closed=onCleanup(@() fclose(fid));fprintf(fid,'%s\n',jsonencode(document));clear closed
[ok,msg]=movefile(staged,file);assert(ok,'%s',msg);clear clean
end
function remove(file),if isfile(file),delete(file);end;end
