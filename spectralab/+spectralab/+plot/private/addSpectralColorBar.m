function barHandle = addSpectralColorBar(ax, xData, yData, colourData)
%ADDSPECTRALCOLORBAR Example implementation that preserves existing graphics.
%
% This template demonstrates the important pattern needed to avoid deleting
% previously plotted graphics when the spectral colour bar is added.

    arguments
        ax (1,1) matlab.graphics.axis.Axes
        xData
        yData
        colourData
    end

    wasHeld = ishold(ax);
    cleanup = onCleanup(@()restoreHold(ax, wasHeld));

    hold(ax,"on");

    barHandle = image(ax, ...
        "XData", xData, ...
        "YData", yData, ...
        "CData", colourData, ...
        "Tag", "SpectraLabSpectralColorBar");

    uistack(barHandle,"bottom");
end

function restoreHold(ax, wasHeld)

    if ~isgraphics(ax,"axes")
        return
    end

    if wasHeld
        hold(ax,"on");
    else
        hold(ax,"off");
    end
end
