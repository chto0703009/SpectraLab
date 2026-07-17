function [wavelengthNm, value] = statusMData(channel)
%STATUSMDATA Return normalized linear ISO Status M spectral products.
%
%   Documentary values are based on Table 4 of ANSI/ISO 5-3:1995,
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

    wavelengthNm = (400:10:780).';

    switch lower(channel)
        case "blue"
            logValue = blueLogValues(wavelengthNm);

        case "green"
            logValue = greenLogValues(wavelengthNm);

        case "red"
            logValue = redLogValues(wavelengthNm);

        otherwise
            error( ...
                "spectralab:filters:statusM:InvalidChannel", ...
                "Channel must be blue, green, or red.");
    end

    value = 10.^(logValue - 5);
end


function logValue = blueLogValues(wavelengthNm)

    knownWavelength = (410:10:510).';

    knownValue = [ ...
        2.103
        4.111
        4.632
        4.871
        5.000
        4.955
        4.743
        4.343
        3.743
        2.990
        1.852];

    logValue = zeros(size(wavelengthNm));

    before = wavelengthNm < 410;
    within = wavelengthNm >= 410 & wavelengthNm <= 510;
    after = wavelengthNm > 510;

    logValue(before) = ...
        2.103 + 0.250 .* (wavelengthNm(before) - 410);

    logValue(within) = interp1( ...
        knownWavelength, ...
        knownValue, ...
        wavelengthNm(within), ...
        "linear");

    logValue(after) = ...
        1.852 - 0.220 .* (wavelengthNm(after) - 510);
end


function logValue = greenLogValues(wavelengthNm)

    knownWavelength = (470:10:610).';

    knownValue = [ ...
        1.152
        2.207
        3.156
        3.804
        4.272
        4.626
        4.872
        5.000
        4.995
        4.818
        4.458
        3.915
        3.172
        2.239
        1.070];

    logValue = zeros(size(wavelengthNm));

    before = wavelengthNm < 470;
    within = wavelengthNm >= 470 & wavelengthNm <= 610;
    after = wavelengthNm > 610;

    logValue(before) = ...
        1.152 + 0.106 .* (wavelengthNm(before) - 470);

    logValue(within) = interp1( ...
        knownWavelength, ...
        knownValue, ...
        wavelengthNm(within), ...
        "linear");

    logValue(after) = ...
        1.070 - 0.120 .* (wavelengthNm(after) - 610);
end


function logValue = redLogValues(wavelengthNm)

    knownWavelength = (620:10:770).';

    knownValue = [ ...
        2.109
        4.479
        5.000
        4.899
        4.578
        4.252
        3.875
        3.491
        3.099
        2.687
        2.269
        1.859
        1.449
        1.054
        0.654
        0.254];

    logValue = zeros(size(wavelengthNm));

    before = wavelengthNm < 620;
    within = wavelengthNm >= 620 & wavelengthNm <= 770;
    after = wavelengthNm > 770;

    logValue(before) = ...
        2.109 + 0.260 .* (wavelengthNm(before) - 620);

    logValue(within) = interp1( ...
        knownWavelength, ...
        knownValue, ...
        wavelengthNm(within), ...
        "linear");

    logValue(after) = ...
        0.254 - 0.040 .* (wavelengthNm(after) - 770);
end
