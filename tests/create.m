function report = create(options)
%CREATE Create an immutable SpectraLab analysis report description.
%
%   report = spectralab.report.create(...)
%
%   This function collects existing analysis results, provenance and
%   presentation context. It performs no scientific calculations and
%   writes no files.

    arguments
        options.Title (1,1) string
        options.Analysis (1,1) string
        options.Result
        options.Figure = []
        options.SourceArchives (:,1) string = strings(0,1)
        options.MeasurementMetadata (1,1) struct = struct()
        options.Method (1,1) string = ""
        options.Standard (1,1) string = ""
        options.Interpolation (1,1) string = ""
        options.Resampling (1,1) string = ""
        options.SpectraLabVersion (1,1) string = ""
        options.Created (1,1) datetime = datetime("now")
    end

    report = spectralab.report.Report( ...
        Title=options.Title, ...
        Analysis=options.Analysis, ...
        Result=options.Result, ...
        Figure=options.Figure, ...
        SourceArchives=options.SourceArchives, ...
        MeasurementMetadata=options.MeasurementMetadata, ...
        Method=options.Method, ...
        Standard=options.Standard, ...
        Interpolation=options.Interpolation, ...
        Resampling=options.Resampling, ...
        SpectraLabVersion=options.SpectraLabVersion, ...
        Created=options.Created);

    spectralab.report.validate(report);
end