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

height = style.Box.TitleHeight + ...
    style.ResultsTable.VerticalGap + ...
    numel(tableModel.Rows) * style.ResultsTable.RowHeight + ...
    style.ResultsTable.SpaceAfter;
end
