function [text, lineCount] = wrapFilename(value)
%WRAPFILENAME Wrap a long report filename at a readable separator.

[text, lineCount] = ...
    spectralab.report.internal.wrapValue(value, 42);
end
