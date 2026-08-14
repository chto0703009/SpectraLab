function tests = test_ui_confirmInstrumentPlacement
%TEST_UI_CONFIRMINSTRUMENTPLACEMENT Verify the modal placement contract.

tests = functiontests(localfunctions);
end


function testUsesBlockingModalDialog(testCase)
sourceFile = which("spectralab.ui.confirmInstrumentPlacement");
source = string(fileread(sourceFile));

verifyTrue(testCase,contains(source,"uiwait(msgbox("));
verifyTrue(testCase,contains(source,'"modal"'));
verifyLessThan(testCase, ...
    strfind(source,"uiwait(msgbox("), ...
    strfind(source,'input("Press ENTER'));
end
