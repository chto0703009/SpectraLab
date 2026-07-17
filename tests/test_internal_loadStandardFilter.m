function tests = test_internal_loadStandardFilter
%TEST_INTERNAL_LOADSTANDARDFILTER Tests for standard-filter loading.

    tests = functiontests(localfunctions);
end


function testLoadsLinearValues(testCase)

    filename = localWriteDataset([ ...
        400 0.2
        500 0.5
        600 1.0]);

    cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>

    filter = spectralab.filters.internal.loadStandardFilter( ...
        filename, ...
        Normalize=false, ...
        Name="Test filter");

    verifyEqual(testCase, filter.WavelengthNm, [400; 500; 600]);
    verifyEqual(testCase, filter.Value, [0.2; 0.5; 1.0]);
    verifyEqual(testCase, filter.Name, "Test filter");
end


function testNormalizesValues(testCase)

    filename = localWriteDataset([ ...
        400 2
        500 4
        600 1]);

    cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>

    filter = spectralab.filters.internal.loadStandardFilter(filename);

    verifyEqual( ...
        testCase, ...
        filter.Value, ...
        [0.5; 1.0; 0.25], ...
        AbsTol=1e-12);
end


function testCanPreserveOriginalScale(testCase)

    filename = localWriteDataset([ ...
        400 2
        500 4
        600 1]);

    cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>

    filter = spectralab.filters.internal.loadStandardFilter( ...
        filename, ...
        Normalize=false);

    verifyEqual(testCase, filter.Value, [2; 4; 1]);
end


function testConvertsLog10Values(testCase)

    filename = localWriteDataset([ ...
        400 -1
        500  0
        600 -Inf]);

    cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>

    filter = spectralab.filters.internal.loadStandardFilter( ...
        filename, ...
        Log10Values=true, ...
        Normalize=false);

    verifyEqual( ...
        testCase, ...
        filter.Value, ...
        [0.1; 1.0; 0], ...
        AbsTol=1e-12);
end


function testAcceptsAbsoluteFilename(testCase)

    filename = localWriteDataset([ ...
        400 0
        500 1
        600 0]);

    cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>

    filter = spectralab.filters.internal.loadStandardFilter(filename);

    verifyClass( ...
        testCase, ...
        filter, ...
        "spectralab.core.SpectralFilter");
end


function testRejectsMissingFile(testCase)

    filename = string(fullfile( ...
        tempdir, ...
        "spectralab_missing_standard_filter.csv"));

    verifyError( ...
        testCase, ...
        @() spectralab.filters.internal.loadStandardFilter(filename), ...
        "spectralab:filters:loadStandardFilter:MissingData");
end


function testRejectsInvalidColumnCount(testCase)

    filename = localWriteDataset([ ...
        400 0.1 1
        500 0.2 2]);

    cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>

    verifyError( ...
        testCase, ...
        @() spectralab.filters.internal.loadStandardFilter(filename), ...
        "spectralab:filters:loadStandardFilter:InvalidData");
end


function testRejectsNonIncreasingWavelengths(testCase)

    filename = localWriteDataset([ ...
        400 0.1
        500 0.2
        500 0.3]);

    cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>

    verifyError( ...
        testCase, ...
        @() spectralab.filters.internal.loadStandardFilter(filename), ...
        "spectralab:filters:loadStandardFilter:InvalidWavelength");
end


function testRejectsNegativeLinearValues(testCase)

    filename = localWriteDataset([ ...
        400  0.1
        500 -0.2
        600  0.3]);

    cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>

    verifyError( ...
        testCase, ...
        @() spectralab.filters.internal.loadStandardFilter(filename), ...
        "spectralab:filters:loadStandardFilter:InvalidValue");
end


function testRejectsNonFiniteWavelengths(testCase)

    filename = localWriteDataset([ ...
        400 0.1
        NaN 0.2
        600 0.3]);

    cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>

    verifyError( ...
        testCase, ...
        @() spectralab.filters.internal.loadStandardFilter(filename), ...
        "spectralab:filters:loadStandardFilter:InvalidWavelength");
end


	function filename = localWriteDataset(data)

	    filename = string(tempname) + ".csv";
	    writematrix(data, filename);

	end


function localDelete(filename)

    if isfile(filename)
        delete(filename);
    end

end
