function tests=test_release_identity
tests=functiontests(localfunctions);
end

function testDevelopmentIdentityIsConsistent(testCase)
result=spectralab.release.verifyIdentity(ExpectedVersion="1.0.2-dev");
verifyEqual(testCase,result.Status,"PASS");
verifyEqual(testCase,result.ExpectedTag,"v1.0.2-dev");
verifyEqual(testCase,result.ExactHeadTag,"");
end

function testMismatchedProposedTagIsRejected(testCase)
verifyError(testCase,@() spectralab.release.verifyIdentity( ...
    ExpectedTag="v1.0.3"),"SpectraLab:Release:TagVersionMismatch");
end
