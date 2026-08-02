function ax = resolveAxes(parent, errorPrefix, figureName)
%RESOLVEAXES Return supplied axes or create a new figure and axes.

    arguments
        parent
        errorPrefix (1,1) string
        figureName (1,1) string = ""
    end

    if isempty(parent)
        if strlength(figureName) > 0
            fig = figure("Name", figureName, "NumberTitle", "off");
        else
            fig = figure;
        end
        ax = axes(fig);
        return
    end

    if ~isa(parent, "matlab.graphics.axis.Axes") || ~isvalid(parent)
        error( ...
            errorPrefix + ":InvalidParent", ...
            "Parent must be a valid MATLAB axes object.");
    end

    ax = parent;
end
