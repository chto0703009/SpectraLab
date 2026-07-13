function tests = test_metadata_validation
%TEST_METADATA_VALIDATION Regression tests for META-005.
tests = functiontests(localfunctions);
end

function testWhitespaceIsTrimmed(testCase)
inst = spectralab.drivers.MockInstrument();

sess = spectralab.core.Session(inst, ...
    Operator="  Christer Törnkvist  ", ...
    Project="  CSW Filter Study  ", ...
    SampleID="  SAM-10B  ", ...
    Comment="  Warm-up complete  ");

status = sess.status();

verifyEqual(testCase, string(status.Details.operator), "Christer Törnkvist");
verifyEqual(testCase, string(status.Details.project), "CSW Filter Study");
verifyEqual(testCase, string(status.Details.sample_id), "SAM-10B");
verifyEqual(testCase, string(status.Details.comment), "Warm-up complete");
end

function testSingleLineFieldsRejectLineBreaks(testCase)
inst = spectralab.drivers.MockInstrument();

verifyError(testCase, ...
    @() spectralab.core.Session(inst, Operator="A" + newline + "B"), ...
    "SpectraLab:Metadata:MultilineNotAllowed");

verifyError(testCase, ...
    @() spectralab.core.Session(inst, SampleID="A" + newline + "B"), ...
    "SpectraLab:Metadata:MultilineNotAllowed");
end

function testCommentAllowsMultipleLines(testCase)
inst = spectralab.drivers.MockInstrument();

sess = spectralab.core.Session(inst, ...
    Comment="First line" + newline + "Second line");

status = sess.status();

verifyEqual(testCase, string(status.Details.comment), ...
    "First line" + newline + "Second line");
end

	function testOverlongValueIsRejected(testCase)
	inst = spectralab.drivers.MockInstrument();
	longValue = string(repmat('X', 1, 201));

	verifyError(testCase, ...
	    @() spectralab.core.Session(inst, Project=longValue), ...
	    "SpectraLab:Metadata:ValueTooLong");
	end

function testMissingValueIsRejected(testCase)
inst = spectralab.drivers.MockInstrument();

verifyError(testCase, ...
    @() spectralab.core.Session(inst, Operator=missing), ...
    "SpectraLab:Metadata:MissingValue");
end

function testValidatedValuesReachArchive(testCase)
inst = spectralab.drivers.MockInstrument();

sess = spectralab.core.Session(inst, ...
    Operator="Christer Törnkvist", ...
    Project="CSW Filter Study", ...
    SampleID="SAM-10B", ...
    Comment="Validated metadata");

sess = sess.open();
sess = sess.calibrate();
spec = sess.measure("Validated metadata");
archive = spectralab.archive.create(spec);

verifyEqual(testCase, archive.Measurement.Operator, "Christer Törnkvist");
verifyEqual(testCase, archive.Metadata.Project, "CSW Filter Study");
verifyEqual(testCase, archive.Metadata.SampleID, "SAM-10B");
verifyEqual(testCase, archive.Metadata.Comment, "Validated metadata");
end
