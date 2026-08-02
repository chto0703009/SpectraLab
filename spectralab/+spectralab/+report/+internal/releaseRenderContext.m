function releaseRenderContext(renderContext)
%RELEASERENDERCONTEXT Release temporary report-rendering resources.
%
%   spectralab.report.internal.releaseRenderContext(renderContext)
%
% Graphics objects and temporary files owned by RenderContext are removed.
% The function is safe to call when resources have already been released.

arguments
    renderContext (1,1) struct
end

if isfield(renderContext, "Graphics")
    releaseGraphics(renderContext.Graphics);
end

if isfield(renderContext, "TemporaryFiles")
    releaseTemporaryFiles(renderContext.TemporaryFiles);
end
end

function releaseGraphics(graphics)
%RELEASEGRAPHICS Delete owned axes and figure objects.

if isfield(graphics, "Axes")
    deleteValidGraphics(graphics.Axes);
end

if isfield(graphics, "Figure")
    deleteValidGraphics(graphics.Figure);
end
end

function deleteValidGraphics(handles)
%DELETEVALIDGRAPHICS Delete graphics handles that are still valid.

for handle = reshape(handles, 1, [])
    if isgraphics(handle)
        delete(handle);
    end
end
end

function releaseTemporaryFiles(files)
%RELEASETEMPORARYFILES Delete temporary files that still exist.

files = string(files);
for file = reshape(files, 1, [])
    if strlength(file) > 0 && isfile(file)
        delete(file);
    end
end
end
