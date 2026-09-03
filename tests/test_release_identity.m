function tests=test_release_identity
tests=functiontests(localfunctions);
end

function testReleaseIdentityIsConsistent(testCase)
result=spectralab.release.verifyIdentity(ExpectedVersion="1.1.0");
verifyEqual(testCase,result.Status,"PASS");
verifyEqual(testCase,result.ExpectedTag,"v1.1.0");
verifyEqual(testCase,result.ExactHeadTag,"");
end

function testMismatchedProposedTagIsRejected(testCase)
verifyError(testCase,@() spectralab.release.verifyIdentity( ...
    ExpectedTag="v1.1.1"),"SpectraLab:Release:TagVersionMismatch");
end
