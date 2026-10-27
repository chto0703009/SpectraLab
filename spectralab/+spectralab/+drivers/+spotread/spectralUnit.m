function unit=spectralUnit(kind,options)
%SPECTRALUNIT Units reported by Argyll spotread for explicit measurement modes.
% See https://www.argyllcms.com/doc/spotread.html (spectral Y-unit table).
tokens=split(strip(string(options)));kind=lower(string(kind));
if kind=="reflectance"
 unit="relative reflectance (%)";
elseif any(tokens=="-e" | tokens=="-p")
 unit="mW/(m^2 sr nm)";
elseif any(tokens=="-a")
 unit="mW/(m^2 nm)";
else
 unit="arbitrary"; % No absolute-unit claim for unknown/relative/custom modes.
end
end
