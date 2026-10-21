% Export existing emitted-light archives as one self-contained JSON.
[names,folder]=uigetfile('*.mat','Select one or more emission archives','MultiSelect','on');if isequal(names,0),return;end
if ischar(names),names={names};end
archives=cell(numel(names),1);for k=1:numel(names),archives{k}=spectralab.archive.load(fullfile(folder,names{k}),Quiet=true,Validation="error");end
[name,destination]=uiputfile('*.json','Export standalone emission JSON');if isequal(name,0),return;end
spectralab.exchange.exportEmission(archives,fullfile(destination,name));
