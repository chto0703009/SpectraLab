function node=pack(value)
%PACK Lossless JSON-safe archive values; no executable objects or binary blobs.
node=struct('Type',class(value),'Shape',size(value),'Data',[]);
if isstruct(value)
 node.Fields=fieldnames(value);items=cell(numel(value),numel(node.Fields));
 for k=1:numel(value),for j=1:numel(node.Fields),items{k,j}=spectralab.exchange.pack(value(k).(node.Fields{j}));end;end
 node.Data=items(:);
elseif iscell(value)
 node.Data=cellfun(@spectralab.exchange.pack,value(:),'UniformOutput',false);
elseif isdatetime(value)
 node.TimeZone=value.TimeZone;node.Format=value.Format;
 v=value;if ~isempty(value.TimeZone),v.TimeZone='UTC';end
 [y,m,d]=ymd(v);[h,mi,se]=hms(v);node.Components=spectralab.exchange.pack([y(:),m(:),d(:),h(:),mi(:),se(:)]);
 v=value;v.Format="yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSS";node.Data=cellstr(string(v(:)));
elseif isstring(value)
 node.Missing=ismissing(value(:));v=value(:);v(ismissing(v))="";node.Data=cellstr(v);
elseif ischar(value)
 node.Data=double(value(:));
elseif isnumeric(value) && isreal(value)
 % Hex stores exact IEEE/integer bits, including NaN/Inf in auxiliary metadata.
 bytes=typecast(value(:),'uint8');node.Data=lower(reshape(dec2hex(bytes,2).',1,[]));
elseif islogical(value)
 node.Data=value(:);
else
 error('SpectraLab:Exchange:UnsupportedType','Cannot preserve archive value of type %s.',class(value));
end
end
