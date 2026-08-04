function tests = test_session_audibleFeedback
%TEST_SESSION_AUDIBLEFEEDBACK Verify session-level audible UX behavior.

tests = functiontests(localfunctions);

end


function testMockInstrumentIsQuietByDefault(testCase)

instrument = spectralab.drivers.createInstrument( ...
    "mock", ...
    "NoiseLevel", ...
    0);

session = spectralab.core.Session(instrument);
status = session.status();

verifyFalse(testCase, session.AudibleFeedback);
verifyFalse(testCase, status.Details.audible_feedback);

end


function testMockInstrumentCanEnableFeedback(testCase)

instrument = spectralab.drivers.createInstrument("mock");

session = spectralab.core.Session( ...
    instrument, ...
    AudibleFeedback=true);

verifyTrue(testCase, session.AudibleFeedback);

end


function testPhysicalInstrumentUsesFeedbackByDefault(testCase)

instrument = spectralab.drivers.createInstrument("i1Pro2");
session = spectralab.core.Session(instrument);

verifyTrue(testCase, session.AudibleFeedback);

end


function testPhysicalInstrumentCanDisableFeedback(testCase)

instrument = spectralab.drivers.createInstrument("i1Pro2");

session = spectralab.core.Session( ...
    instrument, ...
    AudibleFeedback=false);

verifyFalse(testCase, session.AudibleFeedback);

end


function testRejectsInvalidFeedbackSetting(testCase)

instrument = spectralab.drivers.createInstrument("mock");

verifyError( ...
    testCase, ...
    @() spectralab.core.Session( ...
        instrument, ...
        AudibleFeedback="yes"), ...
    "SpectraLab:Session:InvalidAudibleFeedback");

end


function testDisabledFeedbackEventsAreValid(testCase)

verifyWarningFree( ...
    testCase, ...
    @() spectralab.ui.playFeedback("start", Enabled=false));

verifyWarningFree( ...
    testCase, ...
    @() spectralab.ui.playFeedback("success", Enabled=false));

verifyWarningFree( ...
    testCase, ...
    @() spectralab.ui.playFeedback("error", Enabled=false));

end


function testRejectsUnknownFeedbackEvent(testCase)

verifyError( ...
    testCase, ...
    @() spectralab.ui.playFeedback("does-not-exist"), ...
    "SpectraLab:UI:UnknownFeedback");

end


function testFeedbackUsesOneFrequencyAndEventSpecificBeepCounts(testCase)

[startWaveform, sampleRate] = spectralab.ui.playFeedback( ...
    "start", PlayAudio=false);
successWaveform = spectralab.ui.playFeedback( ...
    "success", PlayAudio=false);
errorWaveform = spectralab.ui.playFeedback( ...
    "error", PlayAudio=false);

toneSamples = round(0.120 * sampleRate);
pauseSamples = round(0.100 * sampleRate);

spectrum = abs(fft(startWaveform));
positiveBinCount = floor(numel(spectrum) / 2) + 1;
[~, dominantBin] = max(spectrum(1:positiveBinCount));
dominantFrequencyHz = (dominantBin - 1) * ...
    sampleRate / numel(startWaveform);
verifyEqual(testCase, dominantFrequencyHz, 1200, AbsTol=10);

verifyEqual(testCase, numel(startWaveform), toneSamples);
verifyEqual(testCase, numel(successWaveform), ...
    2 * toneSamples + pauseSamples);
verifyEqual(testCase, numel(errorWaveform), ...
    5 * toneSamples + 4 * pauseSamples);

verifyEqual(testCase, successWaveform(1:toneSamples), startWaveform);
verifyEqual(testCase, ...
    successWaveform(toneSamples + pauseSamples + (1:toneSamples)), ...
    startWaveform);
verifyEqual(testCase, errorWaveform(1:toneSamples), startWaveform);
verifyEqual(testCase, ...
    errorWaveform(toneSamples + pauseSamples + (1:toneSamples)), ...
    startWaveform);
verifyEqual(testCase, ...
    errorWaveform(2 * (toneSamples + pauseSamples) + (1:toneSamples)), ...
    startWaveform);
verifyEqual(testCase, ...
    errorWaveform(3 * (toneSamples + pauseSamples) + (1:toneSamples)), ...
    startWaveform);
verifyEqual(testCase, ...
    errorWaveform(4 * (toneSamples + pauseSamples) + (1:toneSamples)), ...
    startWaveform);

end
