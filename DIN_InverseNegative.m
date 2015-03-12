function event  = DIN_InverseNegative(event, leaveout)

% simple supplementary function that 'inverses' binary
% values of markers if the user wishes to perform such
% an operation (it may sometimes happen that your markers
% are inversely coded, although you did not plan to code
% them this way)

for a = 1:length(event)
    if ~leaveout(a)
        if ~isempty(event(a).type2)
        event(a).type2 = ~event(a).type2;
        end
    end
end