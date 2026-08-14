function [measurement, archive, outputs] = oneShot(instrumentId, measurementName, archiveFolder, options)
%ONESHOT Calibrate, measure and preserve one Spotread spectrum.
%
% Standard output is one immutable SpectraLab archive. CSV and registered
% report/figure outputs are explicit options for calling workflows.

arguments
    instrumentId (1,1) string
    measurementName (1,1) string
    archiveFolder (1,1) string
    options.MeasurementKind (1,1) string = "emissive"
    options.HighResolution (1,1) logical = false
    options.Operator (1,1) string = ""
    options.Project (1,1) string = ""
    options.Comment (1,1) string = ""
    options.ExportCSV (1,1) logical = false
    options.GenerateReport (1,1) logical = false
    options.ExportPNG (1,1) logical = false
    options.ShowFigure (1,1) logical = true
    options.PNGInformation (1,1) logical = false
end
if ~isfolder(archiveFolder), mkdir(archiveFolder); end
archiveFile = fullfile(archiveFolder, measurementName + ".mat");
if isfile(archiveFile)
    error("SpectraLab:Measurement:OutputFileAlreadyExists", ...
        "SpectraLab refuses to overwrite the existing file:\n%s", archiveFile);
end
pngFile = "";
exportStandalonePNG = options.ExportPNG || options.PNGInformation;
if exportStandalonePNG
    pngFile = fullfile(string(fileparts(archiveFolder)), ...
        "plot", measurementName + ".png");
    if isfile(pngFile)
        error("SpectraLab:Measurement:OutputFileAlreadyExists", ...
            "SpectraLab refuses to overwrite the existing file:\n%s", pngFile);
    end
end

inst = spectralab.drivers.createInstrument(instrumentId, ...
    MeasurementKind=options.MeasurementKind, ...
    HighResolution=options.HighResolution);
cleanup = onCleanup(@() inst.close());
session = spectralab.core.Session(inst, AudibleFeedback=true);
session = session.withOperator(options.Operator);
session = session.withProject(options.Project);
session = session.withSample(measurementName);
session = session.withComment(options.Comment);
session = session.open();
session = session.calibrate("Mode", "automatic");
pause(1.0)
measurement = session.measure(measurementName, "Mode", "automatic");
archive = spectralab.archive.create(measurement);
spectralab.archive.save(archive, archiveFile);
session.close();
clear cleanup

csvFile = "";
if options.ExportCSV
    csvFile = fullfile(archiveFolder, measurementName + ".csv");
    spectralab.io.exportCsv(measurement, csvFile);
end
reportInfo = struct();
if exportStandalonePNG
    spectralab.plot.exportArchivePNG(archive, pngFile, ...
        Information=options.PNGInformation, ShowFigure=options.ShowFigure);
end
if options.GenerateReport
    analysisRoot = string(fileparts(archiveFolder));
    reportFolder = fullfile(analysisRoot, "report");
    plotFolder = fullfile(analysisRoot, "plot");
    if ~isfolder(reportFolder), mkdir(reportFolder); end
    if ~isfolder(plotFolder), mkdir(plotFolder); end
    reportInfo = spectralab.report.generate(archiveFile, ...
        "ANL-SPECTRUM", reportFolder, ...
        ShowFigure=options.ShowFigure, OpenPDF=false, ...
        FigureOutputFolder=plotFolder, ...
        PNGInformation=options.PNGInformation);
elseif options.ShowFigure && ~exportStandalonePNG
    spectralab.report.showFigure(archive, "ANL-SPECTRUM");
end
outputs = struct("ArchiveFile", string(archiveFile), ...
    "CSVFile", string(csvFile), "PNGFile", string(pngFile), ...
    "Report", reportInfo);
end
