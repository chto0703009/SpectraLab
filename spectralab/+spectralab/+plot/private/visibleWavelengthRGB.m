function rgb = visibleWavelengthRGB(wavelengthNm)
%VISIBLEWAVELENGTHRGB Approximate visible wavelength colours.
%
%   rgb = visibleWavelengthRGB(wavelengthNm)
%
%   Returns an N-by-3 RGB matrix for wavelengths from 400 to 730 nm.
%   Values outside that interval are rejected. The mapping is intended for
%   a qualitative wavelength guide and is not a colourimetric conversion.

    arguments
        wavelengthNm (:,1) double {mustBeFinite, mustBeReal}
    end

    range = spectralab.core.visibleLightContract().WavelengthRangeNm;
    if any(wavelengthNm < range(1) | wavelengthNm > range(2))
        error("spectralab:plot:VisibleWavelengthOutOfRange", ...
            "Visible wavelength colours require values from %.0f to %.0f nm.", ...
            range(1), range(2));
    end

    rgb = zeros(numel(wavelengthNm), 3);

    for index = 1:numel(wavelengthNm)
        wavelength = wavelengthNm(index);

        if wavelength < 440
            red = -(wavelength - 440) / 60;
            green = 0;
            blue = 1;
        elseif wavelength < 490
            red = 0;
            green = (wavelength - 440) / 50;
            blue = 1;
        elseif wavelength < 510
            red = 0;
            green = 1;
            blue = -(wavelength - 510) / 20;
        elseif wavelength < 580
            red = (wavelength - 510) / 70;
            green = 1;
            blue = 0;
        elseif wavelength < 645
            red = 1;
            green = -(wavelength - 645) / 65;
            blue = 0;
        else
            red = 1;
            green = 0;
            blue = 0;
        end

        if wavelength <= 700
            attenuation = 1;
        else
            attenuation = 0.30 + 0.70 * (730 - wavelength) / 30;
        end

        gamma = 0.80;
        rgb(index,:) = ([red green blue] .* attenuation) .^ gamma;
    end
end
