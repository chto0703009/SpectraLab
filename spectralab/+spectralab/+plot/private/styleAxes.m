function styleAxes(ax, xLabelText, yLabelText, titleText, showGrid)
%STYLEAXES Apply common labels, title, grid, and box styling.

    xlabel(ax, xLabelText);

    yLabel = ylabel(ax, yLabelText);
    yLabel.Units = "normalized";
    yLabelPosition = yLabel.Position;
    yLabelPosition(1) = yLabelPosition(1) - 0.055;
    yLabel.Position = yLabelPosition;

    if strlength(titleText) > 0
        titleHandle = title(ax, titleText, "Interpreter", "none");
        titleHandle.Units = "normalized";
        titlePosition = titleHandle.Position;
        if contains(titleText, newline)
            titlePosition(2) = 1.015;
        else
            titlePosition(2) = 1.045;
        end
        titleHandle.Position = titlePosition;
    end

    grid(ax, matlab.lang.OnOffSwitchState(showGrid));
    box(ax, "on");
end
