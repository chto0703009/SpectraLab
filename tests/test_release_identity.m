function tests=test_release_identity
tests=functiontests(localfunctions);
end

function testReleaseIdentityIsConsistent(testCase)
result=spectralab.release.verifyIdentity(ExpectedVersion="1.2.0");
verifyEqual(testCase,result.Status,"PASS");
verifyEqual(testCase,result.ExpectedTag,"v1.2.0");
verifyTrue(testCase,ismember(result.ExactHeadTag,["","v1.2.0"]));
end

function testMismatchedProposedTagIsRejected(testCase)
verifyError(testCase,@() spectralab.release.verifyIdentity( ...
    ExpectedTag="v1.2.1"),"SpectraLab:Release:TagVersionMismatch");
end
