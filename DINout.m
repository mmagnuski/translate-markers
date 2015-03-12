function [nowe_eventy, nowe_ureventy, leaveout] = DINout(EEG, adresy, dins, leaveout)

% a function working within DINTr function pack
% it merges together DINs that are to be translated
% into single events.
% additionally the function checks whether the
% DINa are binary or decimal 

% EEG      -- EEG structure, as used in EEGlab
% adresy   -- ??
% dins     -- ??
% leaveout -- (int or bool?) dins that should be left out

% TO DOs:
% (binary vs decimal should be probably checked earlier)
% ??pozmieniaæ opcje ignorowanych eventów - przekazywanie ich dalej

maxim = max(dins);
% maximbin = 2^floor(log2(maxim));

% !CHANGE! leveout to logical
leave = false(length(dins),1);
leave(leaveout) = true;
leaveout = leave;
clear leave

% allocating variables
numzero = floor(log2(maxim))+1;
viktorzer = false(1,numzero);
isbinary = true;

% checking for nonbinary values
for a = 1:length(dins)
    if ~(dins(a) == 0)
        if ~isbinaryrepresentation(dins(a))
            isbinary = false;
            break
        end
    end
end

%% main loop:
for i = 1:size(adresy,1)
    
    if ~leaveout(i)
        adr = adresy(i,:);
        
        % deklarujemy allozaury
        allnum = 0;
        allozer = viktorzer;
        
        % reading DINs from a DIN pack
        for j = adr(1):adr(2)
            if isbinary
                numer = dins(j);
                % decimal representation
                allnum = allnum + numer;
                
                % binary representation
                allozer(numzero - log2(numer)) = true;
            else
                nowe_eventy(j).latency = EEG.event(j).latency;
                nowe_eventy(j).type10 = dins(j);
                binr = bintransform(dins(j));
                sizedif = numzero - length(binr);
                binr = [zeros(1,sizedif), binr];
                nowe_eventy(j).type2 = logical(binr);
                nowe_eventy(j).type = num2str(dins(j));
                nowe_eventy(j).urevent = j;
                nowe_ureventy(j).latency = EEG.event(j).latency;
                nowe_ureventy(j).type = num2str(dins(j));
            end
        end
        
    end
    
    if isbinary && ~leaveout(i)
        % filling in new event structure
        nowe_eventy(i).latency = EEG.event(adr(1)).latency; %#ok<*AGROW>
        nowe_eventy(i).type10 = allnum;
        nowe_eventy(i).type2 = allozer;
        nowe_eventy(i).type = num2str(allnum);
        nowe_eventy(i).urevent = i;
        nowe_ureventy(i).latency = EEG.event(adr(1)).latency;
        nowe_ureventy(i).type = num2str(allnum);
    end
    
    if leaveout(i)
        if isbinary
            nr = i;
        else
            nr = adresy(i,1);
        end
        
        adr = adresy(i,:);
        nowe_eventy(nr).latency = EEG.event(adr(1)).latency;
        nowe_eventy(nr).type = EEG.event(adr(1)).type;
        nowe_eventy(nr).urevent = EEG.event(adr(1)).urevent;
        
        if isfield(EEG.event(adr(1)), 'duration')
            nowe_eventy(nr).duration = EEG.event(adr(1)).duration;
        end
        
        nowe_ureventy(nr).latency = nowe_eventy(nr).latency;
        nowe_ureventy(nr).type = nowe_eventy(nr).type;
        
    end
end

%% additional functions:

function isbn = isbinaryrepresentation(number)
%%
powtwo = log2(number);
isbn = powtwo - floor(powtwo) == 0;

function binr = bintransform(number)
%%
basepow = floor(log2(number));
pows = basepow:-1:0;
nums = 2.^pows;
binr = zeros(1,length(nums));

for a = 1:length(nums)
    if number > 0 && number - nums(a) >= 0
        number = number - nums(a);
        binr(a) = 1;
    end
end

