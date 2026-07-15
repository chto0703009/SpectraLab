function [wavelengthNm, value] = statusAData(channel)
%STATUSADATA Return normalized linear ISO Status A spectral products.
%
%   Documentary values are based on Table 3 of ANSI/ISO 5-3:1995,
%   ANSI/NAPM IT2.18-1996. The table gives base-10 logarithmic spectral
%   products normalized to log10 peak 5.000. Values are converted to
%   normalized linear weighting using:
%
%       value = 10.^(logProduct - 5)
%
%   Sloped regions specified by the standard are evaluated in log space.

    arguments
        channel (1,1) string
    end

    wavelengthNm = (400:10:750).';

    switch lower(channel)
        case "blue"
            logValue = blueLogValues(wavelengthNm);

        case "green"
            logValue = greenLogValues(wavelengthNm);

        case "red"
            logValue = redLogValues(wavelengthNm);

        otherwise
            error( ...
                "spectralab:filters:statusA:InvalidChannel", ...
                "Channel must be blue, green, or red.");
    end

    value = 10.^(logValue - 5);
end


function logValue = blueLogValues(wavelengthNm)

    logValue = zeros(size(wavelengthNm));

    knownWavelength = (420:10:500).';
    knownValue = [ ...
        3.602
        4.819
        5.000
        4.912
        4.620
        4.040
        2.989
        1.566
        0.165];

    before = wavelengthNm < 420;
    within = wavelengthNm >= 420 & wavelengthNm <= 500;
    after = wavelengthNm > 500;

    logValue(before) = 3.602 + 0.380 .* (wavelengthNm(before) - 420);
    logValue(within) = interp1(knownWavelength, knownValue, ...
        wavelengthNm(within), "linear");
    logValue(after) = 0.165 - 0.140 .* (wavelengthNm(after) - 500);
end


function logValue = greenLogValues(wavelengthNm)

    logValue = zeros(size(wavelengthNm));

    knownWavelength = (500:10:590).';
    knownValue = [ ...
        1.650
        3.822
        4.782
        5.000
        4.906
        4.644
        4.221
        3.609
        2.766
        1.579];

    before = wavelengthNm < 500;
    within = wavelengthNm >= 500 & wavelengthNm <= 590;
    after = wavelengthNm > 590;

    logValue(before) = 1.650 + 0.220 .* (wavelengthNm(before) - 500);
    logValue(within) = interp1(knownWavelength, knownValue, ...
        wavelengthNm(within), "linear");
    logValue(after) = 1.579 - 0.170 .* (wavelengthNm(after) - 590);
end


function logValue = redLogValues(wavelengthNm)

    logValue = zeros(size(wavelengthNm));

    knownWavelength = (600:10:750).';
    knownValue = [ ...
        2.568
        4.638
        5.000
        4.871
        4.604
        4.286
        3.900
        3.551
        3.165
        2.776
        2.383
        1.970
        1.551
        1.141
        0.741
        0.341];

    before = wavelengthNm < 600;
    within = wavelengthNm >= 600 & wavelengthNm <= 750;

    logValue(before) = 2.568 + 0.270 .* (wavelengthNm(before) - 600);
    logValue(within) = interp1(knownWavelength, knownValue, ...
        wavelengthNm(within), "linear");
end
