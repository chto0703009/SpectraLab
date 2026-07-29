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
