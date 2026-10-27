function value = reflectanceFraction(value, unit)
%REFLECTANCEFRACTION Convert explicit supported reflectance units to fractions.
unit=lower(strip(string(unit)));
if any(unit==["1","fraction","spectral reflectance factor"])
 value=double(value);
elseif any(unit==["%","percent","relative reflectance (%)","reflectance (%)","spectral reflectance (%)"])
 value=double(value)./100;
else
 error("SpectraLab:Colorimetry:UnsupportedQuantity", ...
  "Unsupported or ambiguous reflectance unit: %s. Use 1 or relative reflectance (%%).",unit);
end
if any(~isfinite(value),'all') || any(value<0,'all')
 error("SpectraLab:Colorimetry:InvalidReflectance","Reflectance must be finite and non-negative; original measurements are not clipped.");
end
end
