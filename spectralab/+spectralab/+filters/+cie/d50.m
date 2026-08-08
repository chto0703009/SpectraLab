function spec = d50()
%D50 Return the bundled official CIE standard illuminant D50 SPD.
%
% Source: CIE 2022, CIE_std_illum_D50.csv, DOI 10.25039/CIE.DS.etgmuqt5.
% The bundled 300--830 nm, 1 nm data file has SHA-256
% b23049c6f7b266c1c1fbe147aa271e8930ca02d6e569c5ae1804c036faea4193.

persistent cached
if isempty(cached)
    filename = fullfile(fileparts(mfilename("fullpath")), ...
        "CIE_std_illum_D50.csv");
    values = readmatrix(filename);
    if size(values, 2) ~= 2 || size(values, 1) ~= 531 || ...
            any(~isfinite(values), "all") || values(1,1) ~= 300 || ...
            values(end,1) ~= 830
        error("SpectraLab:CIE:D50DataInvalid", ...
            "Bundled CIE D50 data is invalid.");
    end
    cached = spectralab.core.Spectrum( ...
        values(:,1), values(:,2), "CIE standard illuminant D50", ...
        struct("Name", "CIE 2022", "DOI", "10.25039/CIE.DS.etgmuqt5"), ...
        struct(), struct(), "relative spectral power");
end
spec = cached;
end
