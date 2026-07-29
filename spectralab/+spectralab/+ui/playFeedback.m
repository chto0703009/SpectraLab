function playFeedback(eventName, options)
%PLAYFEEDBACK Play a short SpectraLab user-feedback sound.
%
%   spectralab.ui.playFeedback("start")
%   spectralab.ui.playFeedback("success")
%   spectralab.ui.playFeedback("error")
%
% Audible feedback is a user-interface feature. Failure to access an audio
% device must never interrupt calibration, measurement or analysis.

arguments
    eventName (1,1) string
    options.Enabled (1,1) logical = true
end

if ~options.Enabled
    return
end

eventName = lower(strtrim(eventName));
sampleRate = 8000;

switch eventName
    case "start"
        waveform = createTone(880, 0.070, sampleRate);

    case "success"
        waveform = [
            createTone(1100, 0.060, sampleRate)
            zeros(round(0.030 * sampleRate), 1)
            createTone(1500, 0.090, sampleRate)
        ];

    case "error"
        errorTone = createTone(2000, 0.050, sampleRate);
        errorPause = zeros(round(0.100 * sampleRate), 1);

        waveform = [
            errorTone
            errorPause
            errorTone
            errorPause
            errorTone
        ];
    otherwise
        error( ...
            "SpectraLab:UI:UnknownFeedback", ...
            "Unknown audible feedback event: %s", ...
            eventName);
end

try
    sound(0.18 * waveform, sampleRate);
catch
    % Audible feedback is non-critical and must never affect the workflow.
end

end


function waveform = createTone(frequency, duration, sampleRate)
%CREATETONE Create a short sinusoidal tone with gentle fades.

sampleCount = max(round(duration * sampleRate), 1);
time = (0:sampleCount-1).' / sampleRate;

waveform = sin(2 * pi * frequency * time);

fadeCount = min( ...
    round(0.010 * sampleRate), ...
    floor(sampleCount / 2));

if fadeCount == 0
    return
end

fade = linspace(0, 1, fadeCount).';

waveform(1:fadeCount) = ...
    waveform(1:fadeCount) .* fade;

waveform(end-fadeCount+1:end) = ...
    waveform(end-fadeCount+1:end) .* flipud(fade);

end
