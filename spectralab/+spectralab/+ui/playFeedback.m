function [waveform, sampleRate] = playFeedback(eventName, options)
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
    options.PlayAudio (1,1) logical = true
end

waveform = zeros(0, 1);
sampleRate = 16000;
if ~options.Enabled
    return
end

eventName = lower(strtrim(eventName));
toneFrequencyHz = 1200;
tone = createTone(toneFrequencyHz, 0.120, sampleRate);
tonePause = zeros(round(0.100 * sampleRate), 1);

switch eventName
    case "start"
        waveform = tone;

    case "success"
        waveform = [
            tone
            tonePause
            tone
        ];

    case "error"
        waveform = [
            tone
            tonePause
            tone
            tonePause
            tone
            tonePause
            tone
            tonePause
            tone
        ];
    otherwise
        error( ...
            "SpectraLab:UI:UnknownFeedback", ...
            "Unknown audible feedback event: %s", ...
            eventName);
end

if ~options.PlayAudio
    return
end

try
    % Wait for this deliberately short signal to finish. Asynchronous
    % sound() can be replaced by the following Spotread operation before
    % it becomes audible on some MATLAB/macOS audio configurations.
    player = audioplayer(0.45 * waveform, sampleRate);
    playblocking(player);
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
