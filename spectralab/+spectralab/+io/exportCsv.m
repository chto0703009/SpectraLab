function exportCsv(spec, filename)
%EXPORTCSV  Export wavelength and power to CSV.

if ~isa(spec, "spectralab.core.Spectrum")
    error("SpectraLab:IO:InvalidSpectrum", ...
        "Input must be a spectralab.core.Spectrum.");
end

T = table(spec.WavelengthNm, spec.Power, ...
    'VariableNames', {'wavelength_nm', 'power'});
writetable(T, filename);

end
