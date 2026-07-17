function filter = isoVisual()
%ISOVISUAL Return the ISO visual density spectral product.
%
%   filter = spectralab.filters.isoVisual()
%
%   The ISO visual spectral product is formed from:
%
%       CIE standard illuminant A .* CIE V(lambda)
%
%   If the two source datasets use identical wavelength grids, their
%   values are multiplied directly. Otherwise, illuminant A is aligned
%   to the photopic wavelength grid using shape-preserving cubic
%   interpolation (PCHIP).
%
%   The resulting spectral product is normalized to a maximum value of 1.
%   This normalization does not affect weighted density because the same
%   weighting function is used for both reference and sample integration.

    packageFolder = fileparts(mfilename("fullpath"));

    photopicFilename = fullfile( ...
        packageFolder, ...
        "data", ...
        "CIE_sle_photopic.csv");

    illuminantFilename = fullfile( ...
        packageFolder, ...
        "data", ...
        "CIE_std_illum_A_1nm.csv");


    %% Check required data files

    if ~isfile(photopicFilename)
        error( ...
            "spectralab:filters:isoVisual:MissingPhotopicData", ...
            "Required CIE photopic dataset was not found: %s", ...
            photopicFilename);
    end

    if ~isfile(illuminantFilename)
        error( ...
            "spectralab:filters:isoVisual:MissingIlluminantAData", ...
            "Required CIE illuminant A dataset was not found: %s", ...
            illuminantFilename);
    end


    %% Read datasets

    photopicData = readmatrix(photopicFilename);
    illuminantData = readmatrix(illuminantFilename);

    validateDataset( ...
        photopicData, ...
        "spectralab:filters:isoVisual:InvalidPhotopicData", ...
        "The photopic dataset must contain wavelength and V(lambda).");

    validateDataset( ...
        illuminantData, ...
        "spectralab:filters:isoVisual:InvalidIlluminantAData", ...
        "The illuminant A dataset must contain wavelength and spectral power.");


    %% Extract columns

    photopicWavelengthNm = photopicData(:,1);
    photopicValue = photopicData(:,2);

    illuminantWavelengthNm = illuminantData(:,1);
    illuminantValue = illuminantData(:,2);


    %% Form common spectral product

    if isequal(photopicWavelengthNm, illuminantWavelengthNm)

        % The datasets already use the same wavelength grid.
        wavelengthNm = photopicWavelengthNm;
        value = photopicValue .* illuminantValue;

    else

        % Determine the common wavelength interval.
        minimumWavelengthNm = max( ...
            photopicWavelengthNm(1), ...
            illuminantWavelengthNm(1));

        maximumWavelengthNm = min( ...
            photopicWavelengthNm(end), ...
            illuminantWavelengthNm(end));

        if minimumWavelengthNm >= maximumWavelengthNm
            error( ...
                "spectralab:filters:isoVisual:NoCommonRange", ...
                "The photopic and illuminant A datasets have no common wavelength range.");
        end

        % Use the photopic grid over the common interval.
        usePhotopic = ...
            photopicWavelengthNm >= minimumWavelengthNm & ...
            photopicWavelengthNm <= maximumWavelengthNm;

        wavelengthNm = photopicWavelengthNm(usePhotopic);
        photopicValue = photopicValue(usePhotopic);

        % Align illuminant A to the photopic grid using PCHIP.
        illuminantValue = interp1( ...
            illuminantWavelengthNm, ...
            illuminantValue, ...
            wavelengthNm, ...
            "pchip");

        if any(~isfinite(illuminantValue))
            error( ...
                "spectralab:filters:isoVisual:InterpolationFailure", ...
                "CIE illuminant A could not be evaluated over the common wavelength range.");
        end

        value = photopicValue .* illuminantValue;

    end


    %% Validate and normalize product

    if any(~isfinite(value)) || any(value < 0)
        error( ...
            "spectralab:filters:isoVisual:InvalidProduct", ...
            "The ISO visual spectral product must contain finite non-negative values.");
    end

    maximumValue = max(value);

    if maximumValue <= 0
        error( ...
            "spectralab:filters:isoVisual:InvalidProduct", ...
            "The ISO visual spectral product must have a positive maximum.");
    end

    value = value ./ maximumValue;


    %% Construct SpectralFilter

    filter = spectralab.core.SpectralFilter.fromTable( ...
        wavelengthNm, ...
        value, ...
        Name="ISO visual density spectral product", ...
        Unit="relative spectral product", ...
        Source="ISO 5-3:2009 spectral condition; " + ...
            "CIE illuminant A DOI 10.25039/CIE.DS.8jsxjrsn; " + ...
            "CIE V(lambda) DOI 10.25039/CIE.DS.dktna2s3", ...
        Description="Normalized product of CIE standard illuminant A " + ...
            "and CIE photopic luminous efficiency V(lambda).");

end


function validateDataset(data, identifier, description)
%VALIDATEDATASET Validate a two-column spectral dataset.

    if ~isnumeric(data) || size(data,2) ~= 2 || size(data,1) < 2
        error(identifier, "%s", description);
    end

    wavelengthNm = data(:,1);
    value = data(:,2);

    if any(~isfinite(wavelengthNm)) || any(~isfinite(value))
        error( ...
            identifier, ...
            "%s All values must be finite.", ...
            description);
    end

    if any(diff(wavelengthNm) <= 0)
        error( ...
            identifier, ...
            "%s Wavelength values must be strictly increasing.", ...
            description);
    end

    if any(value < 0)
        error( ...
            identifier, ...
            "%s Spectral values must be non-negative.", ...
            description);
    end

end