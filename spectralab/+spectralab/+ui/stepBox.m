function stepBox(titleText, lines)
%STEPBOX  Print a concise user-facing instruction block.

if nargin < 1
    titleText = "";
end
if nargin < 2
    lines = strings(0,1);
end

titleText = upper(string(titleText));
lines = string(lines(:));

width = 52;
rule = repmat("-", 1, width);

fprintf("\n+-%s-+\n", rule);
fprintf("| %-*s |\n", width, titleText);
fprintf("+-%s-+\n", rule);

for k = 1:numel(lines)
    text = lines(k);
    fprintf("| %-*s |\n", width, text);
end

fprintf("+-%s-+\n", rule);

end
