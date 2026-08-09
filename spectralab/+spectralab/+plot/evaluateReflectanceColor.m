function color = evaluateReflectanceColor(archive)
%EVALUATEREFLECTANCECOLOR Calculate D50 colorimetry and display sRGB.

dataset = spectralab.analysis.colorimetry(archive, ...
    Illuminant=spectralab.filters.cie.d50(), Observer="CIE1931_2");
result = dataset.Samples.Colorimetry;
xyz = [result.XYZ.X; result.XYZ.Y; result.XYZ.Z];
lab = [result.Lab.L; result.Lab.a; result.Lab.b];
color = struct( ...
    "XYZ", xyz, ...
    "Lab", lab, ...
    "DisplayRGB", d50XyzToSrgb(xyz), ...
    "Illuminant", "D50", ...
    "Observer", "CIE1931_2", ...
    "DisplayEncoding", "sRGB after Bradford D50-to-D65 adaptation");
end

function rgb = d50XyzToSrgb(xyz)
% Bradford chromatic adaptation from the D50 reference white to D65.
bradford = [ ...
     0.8951  0.2664 -0.1614
    -0.7502  1.7135  0.0367
     0.0389 -0.0685  1.0296];
d50 = [96.4212; 100.0000; 82.5188];
d65 = [95.0470; 100.0000; 108.8830];
adaptation = bradford \ ...
    (diag((bradford * d65) ./ (bradford * d50)) * bradford);
xyzD65 = adaptation * xyz ./ 100;
linearRgb = [ ...
     3.2404542 -1.5371385 -0.4985314
    -0.9692660  1.8760108  0.0415560
     0.0556434 -0.2040259  1.0572252] * xyzD65;
rgb = zeros(3,1);
low = linearRgb <= 0.0031308;
rgb(low) = 12.92 .* linearRgb(low);
rgb(~low) = 1.055 .* linearRgb(~low).^(1/2.4) - 0.055;
rgb = min(1, max(0, rgb)).';
end
