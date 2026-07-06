function exportTxt(spec, filename)
%EXPORTTXT  Export human-readable spectrum summary and data.

if ~isa(spec, "spectralab.core.Spectrum")
    error("SpectraLab:IO:InvalidSpectrum", ...
        "Input must be a spectralab.core.Spectrum.");
end

fid = fopen(filename, "w");
if fid < 0
    error("SpectraLab:IO:OpenFailed", "Could not open file for writing.");
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, "SpectraLab spectrum\n");
fprintf(fid, "Label: %s\n", spec.Label);
fprintf(fid, "Timestamp: %s\n\n", char(spec.Timestamp));
fprintf(fid, "%s\n\n", spec.summary());
fprintf(fid, "wavelength_nm,power\n");

for k = 1:numel(spec.WavelengthNm)
    fprintf(fid, "%.10g,%.10g\n", spec.WavelengthNm(k), spec.Power(k));
end

end
