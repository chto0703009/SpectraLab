function s = spectralab_status(varargin)
%SPECTRALAB_STATUS  Print SpectraLab status.
%
%   spectralab_status() is kept as a compatibility helper. New code should
%   call spectralab.status().

s = spectralab.status(varargin{:});

end
