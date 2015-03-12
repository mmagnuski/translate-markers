function [output, dins, leave] = DINTr_reko(EEG)

% a helper function for the DINTr pack
% it provides a reconnaissance for the
% later functions
% Specificly it looks for DINs ocurring
% together within a specified window of
% simultaneity ('simult' variable) and
% treats them as a DIN pack to translate

% for now hardcoded:
% default window of simultaneity (in ms)
simult = 2;
event = EEG.event;

% dodatkowy ostatni event:
event(end+1).latency = event(end).latency + 1500;

%% ADD: prechecks for DIN validity?

%% checking for 'boundary' events and similar:

% regular expression to extract DIN number
t = '[0-9]*';
leaveout = false(1,length(event));

% finding DIN values:
dins = {EEG.event.type};
dins = regexp(dins, t, 'match');

if iscell(dins{1})
    leaveout = cellfun(@isempty, dins);
    dins(leaveout) = {{'0'}};
    dins = cellfun(@(x) x{1}, dins, 'UniformOutput', false);
end

leaveout(end+1) = false;
dins = cellfun(@str2double, dins);

%%

% extracting first latency:
lat = event(1).latency;

% other important initiations

adres_beg = 1; frst = 2;
b = 1; leave = [];
if leaveout(1)
    leave(1) = 1;
end

for i = frst:length(event)  

        % je¿eli marker ignorowany, to na pewno przerwij
        % ci¹g markerów jednego eventu
        if ~leaveout(i) && ~leaveout(i-1)
            warunek = abs(lat - event(i).latency) <= simult;
        else
            warunek = false;
        end
        
        switch warunek
            case false
                % zapisujemy adres pocz¹tku i adres koñca DINów o tej samej
                % latencji
                output(b,:) = [adres_beg, i-1]; %#ok<AGROW>
                
                if leaveout(i)
                    leave = [leave, b+1]; %#ok<AGROW>
                end
                b = b+1;
                
                % update 'pamiêci'
                lat = event(i).latency;
                adres_beg = i;
                    
        end
end

end

