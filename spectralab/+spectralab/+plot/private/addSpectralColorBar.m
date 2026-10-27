function barHandle = addSpectralColorBar(ax)
%ADDSPECTRALCOLORBAR Add a thin wavelength colour guide to an axes.
%
%   barHandle = addSpectralColorBar(ax)
%
%   The guide spans the current x-axis range. Wavelengths outside
%   400-730 nm are black. Existing graphics, axis limits, and hold
%   state are preserved.

    arguments
        ax (1,1) matlab.graphics.axis.Axes
    end

    originalXLimits = xlim(ax);
    originalYLimits = ylim(ax);
    originalHoldState = ishold(ax);

    cleanup = onCleanup(@()restoreAxesState( ...
        ax, originalXLimits, originalYLimits, originalHoldState)); %#ok<NASGU>

    hold(ax, "on");

    delete(findall(ax, "Tag", "SpectraLabSpectralColorBar"));

    wavelengthNm = linspace(originalXLimits(1), originalXLimits(2), 512);
    rgb = zeros(numel(wavelengthNm), 3);

    visibleRange = spectralab.core.visibleLightContract().WavelengthRangeNm;
    visible = wavelengthNm >= visibleRange(1) & wavelengthNm <= visibleRange(2);
    if any(visible)
        rgb(visible,:) = visibleWavelengthRGB(wavelengthNm(visible).');
    end

    barHeight = 0.025 * diff(originalYLimits);
    if ~(isfinite(barHeight) && barHeight > 0)
        barHeight = 1;
    end

    lowerY = originalYLimits(1);
    upperY = lowerY + barHeight;

    xData = repmat(wavelengthNm, 2, 1);
    yData = [
        repmat(lowerY, 1, numel(wavelengthNm))
        repmat(upperY, 1, numel(wavelengthNm))
    ];
    zData = zeros(size(xData));

    colourData = repmat( ...
        reshape(rgb, 1, numel(wavelengthNm), 3), ...
        2, 1, 1);

    barHandle = surface(ax, ...
        xData, ...
        yData, ...
        zData, ...
        colourData, ...
        "FaceColor", "texturemap", ...
        "EdgeColor", "none", ...
        "HandleVisibility", "off", ...
        "Tag", "SpectraLabSpectralColorBar");

    uistack(barHandle, "bottom");
end


function restoreAxesState(ax, xLimits, yLimits, holdState)

    if ~isgraphics(ax, "axes")
        return
    end

    xlim(ax, xLimits);
    ylim(ax, yLimits);

    if holdState
        hold(ax, "on");
    else
        hold(ax, "off");
    end
end
