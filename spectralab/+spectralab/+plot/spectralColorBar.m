function barHandle = spectralColorBar(ax)
%SPECTRALCOLORBAR Add the canonical SpectraLab wavelength colour guide.
%
%   barHandle = spectralab.plot.spectralColorBar(ax)
%
% This public plotting helper lets registered multi-spectrum and signed
% analyses use the same colour guide as spectralab.plot.spectrum.

arguments
    ax (1,1) matlab.graphics.axis.Axes
end

barHandle = addSpectralColorBar(ax);
end
