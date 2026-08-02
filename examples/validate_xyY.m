%% Convert CIE 1931 XYZ to xyY

startup

referenceName = "redfilter_csw_ref";

archive = spectralab.archive.load(referenceName + ".mat");
spec = spectralab.archive.restore(archive);

assert( ...
    isa(spec, "spectralab.core.Spectrum"), ...
    "The archive did not restore to a Spectrum.");

xyzResult = spectralab.analysis.xyz( ...
    spec, ...
    Normalization="Y100");

xyYResult = spectralab.analysis.xyY(xyzResult);

fprintf("\nCIE 1931 XYZ\n");
fprintf("X = %.6f\n", xyzResult.Result.X);
fprintf("Y = %.6f\n", xyzResult.Result.Y);
fprintf("Z = %.6f\n", xyzResult.Result.Z);

fprintf("\nCIE xyY\n");
fprintf("x = %.6f\n", xyYResult.Result.x);
fprintf("y = %.6f\n", xyYResult.Result.y);
fprintf("Y = %.6f\n", xyYResult.Result.Y);
