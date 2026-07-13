function tests = test_session_comment_propagation
%TEST_SESSION_COMMENT_PROPAGATION Regression tests for META-003.
tests = functiontests(localfunctions);
end

function testWithCommentAndStatus(testCase)
inst = spectralab.drivers.MockInstrument();
sess = spectralab.core.Session(inst);
sess = sess.withComment("Updated comment");

status = sess.status();

verifyEqual(testCase, string(status.Details.comment), "Updated comment");
end

function testCommentPropagatesIntoArchive(testCase)
inst = spectralab.drivers.MockInstrument();
sess = spectralab.core.Session(inst, ...
    Operator="Christer Törnkvist", ...
    Comment="Archive comment test");

sess = sess.open();
sess = sess.calibrate();
spec = sess.measure("Archive comment");
archive = spectralab.archive.create(spec);

verifyEqual(testCase, string(spec.Metadata.Comment), ...
    "Archive comment test");
verifyEqual(testCase, archive.Metadata.Comment, ...
    "Archive comment test");
verifyEqual(testCase, archive.Measurement.Operator, ...
    "Christer Törnkvist");
end
