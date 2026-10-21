function hash=jsonContentHash(value)
%JSONCONTENTHASH SHA-256 of sorted-key JSON-safe values (vectors shape-independent).
value=jsondecode(jsonencode(value));
text=spectralab.archive.jsonCanonicalText(value);
md=java.security.MessageDigest.getInstance('SHA-256');
digest=typecast(md.digest(unicode2native(char(text),'UTF-8')),'uint8');
hash=lower(string(reshape(dec2hex(digest,2).',1,[])));
end
