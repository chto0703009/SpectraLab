function filter = loadTestSample(index)
%LOADTESTSAMPLE Load one official CIE CRI test-colour sample.
%
%   The CIE data are spectral radiance factors. Within SpectraLab they are
%   represented by SpectralFilter because the common behaviour is a
%   wavelength-dependent multiplication of an illuminant spectrum.

    arguments
        index (1,1) double {mustBeInteger, mustBeInRange(index,1,14)}
    end

    criFolder = fileparts(fileparts(mfilename("fullpath")));
    filtersFolder = fileparts(criFolder);

    filename = fullfile( ...
        filtersFolder, ...
        "data", ...
        "CIE_srf_cri.csv");

    if ~isfile(filename)
        error( ...
            "spectralab:filters:cri:MissingData", ...
            "Required CIE CRI dataset was not found: %s", ...
            filename);
    end

    data = readmatrix(filename);

    if size(data,1) ~= 95 || size(data,2) ~= 15
        error( ...
            "spectralab:filters:cri:InvalidData", ...
            "The CIE CRI dataset must contain 95 rows and 15 columns.");
    end

    wavelengthNm = data(:,1);
    value = data(:,index + 1);

    names = [ ...
        "7.5R6/4"
        "5Y6/4"
        "5GY6/8"
        "2.5G6/6"
        "10BG6/4"
        "5PB6/8"
        "2.5P6/8"
        "10P6/8"
        "4.5R4/13"
        "5Y8/10"
        "4.5G5/8"
        "3PB3/11"
        "5YR8/4"
        "5GY4/4"
    ];

    sampleId = sprintf("TCS%02d", index);

    filter = spectralab.core.SpectralFilter.fromTable( ...
        wavelengthNm, ...
        value, ...
        Name="CIE CRI " + sampleId, ...
        Unit="spectral radiance factor", ...
        Source="CIE 1995, DOI 10.25039/CIE.DS.wuiuu9cz", ...
        Description="CIE 13.3:1995 test-colour sample " + ...
            sampleId + " (" + names(index) + ").");
end
