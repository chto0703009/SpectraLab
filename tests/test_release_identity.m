function tests=test_release_identity
tests=functiontests(localfunctions);
end

function testReleaseIdentityIsConsistent(testCase)
result=spectralab.release.verifyIdentity(ExpectedVersion="1.3.0");
verifyEqual(testCase,result.Status,"PASS");
verifyEqual(testCase,result.ExpectedTag,"v1.3.0");
if result.ExactHeadTag~="",verifyEqual(testCase,result.ExactHeadTag,"v1.3.0");end
end

function testMismatchedProposedTagIsRejected(testCase)
verifyError(testCase,@() spectralab.release.verifyIdentity( ...
    ExpectedTag="v1.2.2"),"SpectraLab:Release:TagVersionMismatch");
end
