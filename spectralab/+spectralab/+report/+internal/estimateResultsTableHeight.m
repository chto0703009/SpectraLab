function height = estimateResultsTableHeight(tableModel)
%ESTIMATERESULTSTABLEHEIGHT Return deterministic results-table height.

arguments
    tableModel (1,1) struct
end

if ~isfield(tableModel, "Rows") || ~isstruct(tableModel.Rows)
    error("SpectraLab:Report:InvalidResultsTable", ...
        "Results table must contain a Rows structure array.");
end

titleHeight = 22;
verticalGap = 28;
rowHeight = 18;
spaceAfter = 8;

height = titleHeight + verticalGap + ...
    numel(tableModel.Rows) * rowHeight + spaceAfter;
end