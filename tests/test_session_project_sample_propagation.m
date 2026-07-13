function tests = test_session_project_sample_propagation
%TEST_SESSION_PROJECT_SAMPLE_PROPAGATION Regression tests for META-004.
tests = functiontests(localfunctions);
end

function testConstructorAndStatus(testCase)
inst = spectralab.drivers.MockInstrument();

sess = spectralab.core.Session(inst, ...
    Project="Kodak Portra Study", ...
    SampleID="Frame 12");

status = sess.status();

verifyEqual(testCase, string(status.Details.project), ...
    "Kodak Portra Study");
verifyEqual(testCase, string(status.Details.sample_id), ...
    "Frame 12");
end

function testWithProjectAndWithSample(testCase)
inst = spectralab.drivers.MockInstrument();

sess = spectralab.core.Session(inst);
sess = sess.withProject("CSW Filter Study");
sess = sess.withSample("SAM-10B");

status = sess.status();

verifyEqual(testCase, string(status.Details.project), ...
    "CSW Filter Study");
verifyEqual(testCase, string(status.Details.sample_id), ...
    "SAM-10B");
end

function testProjectAndSampleReachArchive(testCase)
inst = spectralab.drivers.MockInstrument();

sess = spectralab.core.Session(inst, ...
    Operator="Christer Törnkvist", ...
    Comment="META-004 propagation test", ...
    Project="CSW Filter Study", ...
    SampleID="SAM-10B");

sess = sess.open();
sess = sess.calibrate();
spec = sess.measure("Project and sample propagation");
archive = spectralab.archive.create(spec);

verifyEqual(testCase, string(spec.Metadata.Project), ...
    "CSW Filter Study");
verifyEqual(testCase, string(spec.Metadata.SampleID), ...
    "SAM-10B");
verifyEqual(testCase, archive.Metadata.Project, ...
    "CSW Filter Study");
verifyEqual(testCase, archive.Metadata.SampleID, ...
    "SAM-10B");
end
