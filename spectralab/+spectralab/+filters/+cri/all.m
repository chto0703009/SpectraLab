function filters = all()
%ALL Return all fourteen CIE CRI test-colour samples.
%
%   filters = spectralab.filters.cri.all()
%
%   The result is a 1-by-14 cell array of SpectralFilter objects.

    filters = cell(1,14);

    for index = 1:14
        filters{index} = loadTestSample(index);
    end
end
