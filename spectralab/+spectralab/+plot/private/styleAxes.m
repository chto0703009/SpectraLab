function styleAxes(ax, xLabelText, yLabelText, titleText, showGrid)
%STYLEAXES Apply common labels, title, grid, and box styling.

    xlabel(ax, xLabelText);
    ylabel(ax, yLabelText);

    if strlength(titleText) > 0
        title(ax, titleText, "Interpreter", "none");
    end

    grid(ax, matlab.lang.OnOffSwitchState(showGrid));
    box(ax, "on");
end
