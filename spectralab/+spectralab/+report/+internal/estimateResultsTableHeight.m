function height = estimateResultsTableHeight(tableModel)
%ESTIMATERESULTSTABLEHEIGHT Return deterministic results-table height.

arguments
    tableModel (1,1) struct
end

if ~isfield(tableModel, "Rows") || ~isstruct(tableModel.Rows)
    error("SpectraLab:Report:InvalidResultsTable", ...
        "Results table must contain a Rows structure array.");
end

rowHeight = 18;
spaceAfter = 8;
height = numel(tableModel.Rows) * rowHeight + spaceAfter;
end
