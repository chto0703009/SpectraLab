function done(message)
%DONE  Print a concise completion message.

if nargin < 1 || strlength(string(message)) == 0
    message = "Done.";
end

fprintf("%s\n", string(message));

end
