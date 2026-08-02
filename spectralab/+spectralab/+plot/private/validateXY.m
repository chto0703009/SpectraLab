function [x, y] = validateXY(x, y, errorPrefix, xName, yName, allowInfiniteY)
%VALIDATEXY Validate and columnize numeric plotting vectors.

    arguments
        x
        y
        errorPrefix (1,1) string
        xName (1,1) string
        yName (1,1) string
        allowInfiniteY (1,1) logical = false
    end

    if ~isnumeric(x) || ~isreal(x) || ~isvector(x) || isempty(x)
        error(errorPrefix + ":InvalidX", "%s must be a nonempty real numeric vector.", xName);
    end

    if ~isnumeric(y) || ~isreal(y) || ~isvector(y) || isempty(y)
        error(errorPrefix + ":InvalidY", "%s must be a nonempty real numeric vector.", yName);
    end

    if numel(x) ~= numel(y)
        error(errorPrefix + ":SizeMismatch", "%s and %s must contain the same number of elements.", xName, yName);
    end

    if any(~isfinite(x), "all")
        error(errorPrefix + ":NonFiniteX", "%s must contain finite values.", xName);
    end

    if allowInfiniteY
        if any(isnan(y), "all")
            error(errorPrefix + ":NaNY", "%s must not contain NaN values.", yName);
        end
    elseif any(~isfinite(y), "all")
        error(errorPrefix + ":NonFiniteY", "%s must contain finite values.", yName);
    end

    x = x(:);
    y = y(:);
end
