function tests = test_createInstrument
%TEST_CREATEINSTRUMENT Verify physical instrument identity and backend mapping.

tests = functiontests(localfunctions);

end


function testCreatesI1Pro2UsingInternalSpotreadBackend(testCase)

instrument = spectralab.drivers.createInstrument("i1Pro2");
info = instrument.getInfo();

verifyClass( ...
    testCase, ...
    instrument, ...
    "spectralab.drivers.SpotreadInstrument");

verifyEqual(testCase, instrument.InstrumentId, "i1Pro2");
verifyEqual(testCase, info.name, "i1Pro2");
verifyEqual(testCase, info.instrument_id, "i1Pro2");
verifyEqual(testCase, info.driver, ...
    "spectralab.drivers.SpotreadInstrument");
verifyEqual(testCase, info.backend, "ArgyllCMS spotread");
verifyEqual(testCase, info.backend_mode, ...
    "manual-safe-one-spotread-session");

end


function testInstrumentIdentifierIsCaseInsensitive(testCase)

instrument = spectralab.drivers.createInstrument("I1PRO2");

verifyEqual(testCase, instrument.InstrumentId, "i1Pro2");

end


function testCreatesI1ProPhysicalIdentity(testCase)

instrument = spectralab.drivers.createInstrument("i1Pro");
info = instrument.getInfo();

verifyEqual(testCase, instrument.InstrumentId, "i1Pro");
verifyEqual(testCase, info.name, "i1Pro");
verifyEqual(testCase, info.instrument_id, "i1Pro");

end


function testLegacySpotreadNameRemainsCompatible(testCase)

instrument = verifyWarning( ...
    testCase, ...
    @() spectralab.drivers.createInstrument("spotread"), ...
    "SpectraLab:Drivers:LegacyBackendName");

verifyClass( ...
    testCase, ...
    instrument, ...
    "spectralab.drivers.SpotreadInstrument");

verifyEqual(testCase, instrument.InstrumentId, "i1Pro2");

end


function testLegacyArgyllNameRemainsCompatible(testCase)

instrument = verifyWarning( ...
    testCase, ...
    @() spectralab.drivers.createInstrument("argyll"), ...
    "SpectraLab:Drivers:LegacyBackendName");

verifyEqual(testCase, instrument.InstrumentId, "i1Pro2");

end


function testRejectsUnknownInstrument(testCase)

verifyError( ...
    testCase, ...
    @() spectralab.drivers.createInstrument("does-not-exist"), ...
    "SpectraLab:Drivers:UnknownInstrument");

end


function testRejectsMissingInstrumentIdentifier(testCase)

verifyError( ...
    testCase, ...
    @() spectralab.drivers.createInstrument(""), ...
    "SpectraLab:Drivers:MissingKind");

end
