function height = estimateResultsTableHeight(tableModel)
%ESTIMATERESULTSTABLEHEIGHT Return deterministic results-table height.

arguments
    tableModel (1,1) struct
end

if ~isfield(tableModel, "Rows") || ~isstruct(tableModel.Rows)
    error("SpectraLab:Report:InvalidResultsTable", ...
        "Results table must contain a Rows structure array.");
end

style = spectralab.report.internal.createReportStyle();

lineCount = sum(arrayfun(@rowLineCount, tableModel.Rows));

height = style.Box.TitleHeight + ...
    style.ResultsTable.VerticalGap + ...
    lineCount * style.ResultsTable.RowHeight + ...
    style.ResultsTable.SpaceAfter;
end


function count = rowLineCount(row)

count = 1;

if isfield(row, "LineCount")
    candidate = double(row.LineCount);

    if isscalar(candidate) && isfinite(candidate) && candidate >= 1
        count = candidate;
    end
end
end
