function args = lineArguments(options)
%LINEARGUMENTS Build common MATLAB line name-value arguments.

    args = { ...
        "LineWidth", options.LineWidth, ...
        "LineStyle", options.LineStyle, ...
        "Marker", options.Marker};

    if ~isempty(options.Color)
        args(end+1:end+2) = {"Color", options.Color};
    end

    if strlength(options.DisplayName) > 0
        args(end+1:end+2) = {"DisplayName", options.DisplayName};
    end
end
