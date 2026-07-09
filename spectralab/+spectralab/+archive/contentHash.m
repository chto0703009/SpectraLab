function hash = contentHash(payload)
%CONTENTHASH Deterministic SHA-256 hash for SpectraLab archive content.
%
%   hash = spectralab.archive.contentHash(payload)
%
% The hash is based on canonicalized scientific content. It should be used
% for deterministic scientific identity, not for random archive instance IDs.
%
% Non-scientific archive fields such as UUIDs, creation timestamps, software
% version fields, filenames and comments should be excluded by the caller.

txt = localCanonicalText(payload);

md = java.security.MessageDigest.getInstance("SHA-256");
bytes = uint8(char(txt));
digest = typecast(md.digest(bytes), "uint8");

hash = lower(string(reshape(dec2hex(digest, 2).', 1, [])));

end

function txt = localCanonicalText(x)

if isstruct(x)
    if numel(x) == 0
        txt = "struct[]";
        return
    end

    if numel(x) > 1
        parts = strings(1, numel(x));
        for i = 1:numel(x)
            parts(i) = localCanonicalText(x(i));
        end
        txt = "structarray[" + strjoin(string(size(x)), "x") + "]:" + ...
              strjoin(parts, "|");
        return
    end

    names = sort(string(fieldnames(x)));
    parts = strings(1, numel(names));

    for i = 1:numel(names)
        name = names(i);
        value = x.(char(name));
        parts(i) = name + ":" + localCanonicalText(value);
    end

    txt = "struct{" + strjoin(parts, ",") + "}";

elseif isnumeric(x)
    if isempty(x)
        txt = "numeric[" + strjoin(string(size(x)), "x") + "]:[]";
    else
        values = compose("%.17g", x(:).');
        txt = "numeric[" + strjoin(string(size(x)), "x") + "]:" + ...
              strjoin(string(values), ",");
    end

elseif islogical(x)
    txt = "logical[" + strjoin(string(size(x)), "x") + "]:" + ...
          strjoin(string(double(x(:).')), ",");

elseif isstring(x)
    txt = "string[" + strjoin(string(size(x)), "x") + "]:" + ...
          strjoin(x(:).', ",");

elseif ischar(x)
    txt = "char:" + string(x);

elseif iscell(x)
    parts = strings(1, numel(x));
    for i = 1:numel(x)
        parts(i) = localCanonicalText(x{i});
    end
    txt = "cell[" + strjoin(string(size(x)), "x") + "]:" + ...
          strjoin(parts, ",");

elseif isdatetime(x)
    if isempty(x)
        txt = "datetime[" + strjoin(string(size(x)), "x") + "]:[]";
    else
        t = x(:).';
        t.Format = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSS";
        txt = "datetime[" + strjoin(string(size(x)), "x") + "]:" + ...
              strjoin(string(t), ",");
    end

else
    error("SpectraLab:Archive:UnsupportedHashContent", ...
          "Unsupported archive content type for hashing: %s", class(x));
end

end
