function value=unpack(node)
%UNPACK Restore only whitelisted data types; never instantiate executable classes.
shape=double(node.Shape(:)');assert(numel(shape)>=2 && all(isfinite(shape)) && all(shape>=0) && all(shape==fix(shape)),'Invalid data shape.');
switch string(node.Type)
 case 'struct'
  fields=string(node.Fields);value=repmat(cell2struct(cell(numel(fields),1),cellstr(fields),1),shape);
  for j=1:numel(fields),for k=1:numel(value),value(k).(fields(j))=spectralab.exchange.unpack(item(node.Data,k+(j-1)*numel(value)));end;end
 case 'cell'
  value=cell(shape);for k=1:numel(value),value{k}=spectralab.exchange.unpack(item(node.Data,k));end
 case 'datetime'
  c=spectralab.exchange.unpack(node.Components);zone=char(node.TimeZone);workingZone=zone;if ~isempty(zone),workingZone='UTC';end
  value=datetime(c(:,1),c(:,2),c(:,3),c(:,4),c(:,5),c(:,6),'TimeZone',workingZone);
  if isfield(node,'CorrectionSeconds')
   correction=spectralab.exchange.unpack(node.CorrectionSeconds);
   value=value+seconds(correction(:));
  end
  if ~isempty(zone),value.TimeZone=zone;end
  value=reshape(value,shape);value.Format=char(node.Format);
 case 'string'
  value=reshape(string(node.Data),shape);value(logical(node.Missing))=missing;
 case 'char'
  value=reshape(char(node.Data),shape);
 case 'logical'
  value=reshape(logical(node.Data),shape);
 case {'double','single','uint8','uint16','uint32','uint64','int8','int16','int32','int64'}
  hex=char(node.Data);assert(mod(numel(hex),2)==0 && all(ismember(lower(hex),'0123456789abcdef')),'Invalid numeric encoding.');
  if isempty(hex),value=zeros(shape,char(node.Type));else,bytes=uint8(hex2dec(reshape(hex,2,[])'));value=reshape(typecast(bytes,char(node.Type)),shape);end
 otherwise,error('SpectraLab:Exchange:UnsupportedType','Unsupported archive type.');
end
end
function value=item(items,index),if iscell(items),value=items{index};else,value=items(index);end;end
