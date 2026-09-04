function tests = test_visibleLightContract
tests = functiontests(localfunctions);
end

function testArchitectureDefinesVisibleLightAs400Through730(testCase)
contract = spectralab.core.visibleLightContract();
verifyEqual(testCase,contract.Schema,"spectralab.visible-light-contract");
verifyEqual(testCase,contract.SchemaVersion,"1.0");
verifyEqual(testCase,contract.WavelengthRangeNm,[400 730]);
verifyEqual(testCase,contract.Bounds,"inclusive");
end

function testCamera41ReferencesVisibleLightContract(testCase)
visible = spectralab.core.visibleLightContract();
camera41 = spectralab.io.camera41ExportContract();
verifyEqual(testCase,camera41.WavelengthRangeNm,visible.WavelengthRangeNm);
verifyEqual(testCase,camera41.DomainContract,visible);
end
