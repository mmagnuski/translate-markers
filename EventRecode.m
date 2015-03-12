function EEGrec = EventRecode(EEG, Translate, Support, leaveout)

% CHECK CHANGE
% przepisywanie eventów - kiedy usuwa pola
% ma nie usuwaæ g³upek!

EEGrec = EEG;
fld = fields(EEG.event);
% filled = {'type', };


for a = 1:length(EEG.event)
    
    if ~leaveout(a)
        % <leaveout> informs whether to recode
        % given events or not
        
        % reads the bitvalue of the event
        bits = EEG.event(a).type2;
        origbit = bits;
        
        % CHANGE: maybe add checks for bit length?
        % throw out a question window or sth?
        % NOW: takes relevant number of bits from
        % the RIGHT (just like binary notation rises 1-2-4 ...)
        if length(bits) > Support.nbits
            bits = bits(end-(Support.nbits-1):end);
        end
        
        allfeats = cell(1, Support.numfeat);
        allfeatvals = zeros(1, Support.numfeat);
        reco_val = cell(1, Support.numfeat);
        reco_txt = cell(1, Support.numfeat);
        
        %% loops through the features:
        for b = 1:Support.numfeat
            % reads how many bits define the feature
            numbits = Translate{1,b};
            
            % reads bits defining feature
            feat = bits(1:numbits);
            allfeats{b} = feat;
            
            % these bits are deleted ('eaten')
            bits(1:numbits) = [];
            
            % the value of the feature (binary to decimal):
            val2 = Support.bitval{b};
            value = sum(feat.*val2); % could be replaced by normal matrix/vector multiplication but need to check vector orientations
            allfeatvals(b)= value;
            
            % if we do not ommit the feature:
            if ~Support.omit(b)
                %% find the adress of this value:
                if Support.valfind(b)
                    adr = find(cell2mat(Translate{3,b}(:,1)) == value);
                    
                    if ~isempty(adr)
                        adr = adr(1);
                    end
                else
                    adr = value + 1;
                end
                
                %% if we need to recode value:
                % leg - minimal length of translation matrix for given feature
                leg = (Support.valfind(b) == 1) + (Support.textval(b) > 0);
                if ~Support.nofield(b) && (leg < Support.len(b)) && ~isempty(adr)
                    col = Support.len(b) - (Support.textval(b) > 0);
                    
                    % value to recode:
                    recodeto = Translate{3,b}{adr,col};
                    
                    % we recode only if the value is not conditioned
                    % if it is we save the value for later checks
                    if ~Support.cond(b)
                        EEGrec.event(a).(Translate{2,b}) = recodeto;
                        EEGrec.urevent(a).(Translate{2,b}) = recodeto;
                    else
                        reco_val{b} = recodeto;
                    end
                end
                
                %% if there is textvalue
                if Support.textval(b) && ~isempty(adr)
                    reco_txt{b} = Translate{3,b}{adr,end};
                else
                    reco_txt{b} = '';
                end
            end
            
        end
        
        %% checks for conditions:
        if Support.anycond
            %         keyboard
            % condi are conditions for given features
            % there can be many conditions for each feature
            % therefore - another loop (by nowcond)
            for condi = Support.adrcond
                % conditions are always in the fourth row:
                conditions = Translate{4,condi};
                numconds = size(conditions,1);
                
                % rescond - the result of evaluating conditions
                %           (allocating here - default is false)
                rescond = false(numconds,1);
                
                for nowcond = 1:numconds
                    
                    % values (indexes of DINs or DINPacks)
                    values = conditions{nowcond,4};
                    if conditions{nowcond,3} == 1
                        between = '|';
                    elseif conditions{nowcond,3} == 2
                        between = '&';
                    else
                        continue
                    end
                    
                    
                    % >>checking type of evaluation<<
                    
                    % 1 - dinpresence
                    if conditions{nowcond,2} == 1
                        
                        % numbering DINs from right side (as their
                        % value grows: 001 is DIN1; 010 is DIN2;
                        % 100 is DIN4; so third DIN is DIN4 not
                        % DIN1)
                        backval = length(origbit):-1:1;
                        values = backval(values);
                        
                        % creating logical evaluation snippet
                        before = 'origbit(';
                        after = ')';
                        snippet = [];
                        
                        for snip = 1:length(values);
                            snippet = [snippet, before, num2str(values(snip)), after, between]; %#ok<AGROW>
                        end
                        % removing last unnecessary '&' or '|'
                        snippet(end) = [];
                        
                        % if the snippet must be negation:
                        if ~conditions{nowcond,1}
                            snippet = ['~(', snippet, ')']; %#ok<AGROW>
                        end
                        
                        % evaluating snippet:
                        rescond(nowcond) = eval(snippet);
                    end
                    
                    % NOW - other types of conditioning not supported at
                    % present, maybe some will be added
                    
                end
                
                % checking if all conditions are true
                if sum(rescond) == length(rescond)
                    
                    %  if field fill
                    if ~isempty(reco_val{condi})
                        EEGrec.event(a).(Translate{2,condi}) = reco_val{condi};
                        EEGrec.urevent(a).(Translate{2,condi}) = reco_val{condi};
                    end
                    
                    % if condition not fullfilled - deleting text
                elseif ~isempty(reco_txt{condi})
                    reco_txt{condi} = '';
                end
            end
        end
        
        % (??) reading the code again I don't understand
        % what I meant here (??):
        % fixing cell content must be of the same file (file??)
        % problem. This is temporary - CHANGE it later.
        isemp_rectxt = cellfun(@isempty, reco_txt);
        reco_txt(isemp_rectxt) = {''};
        clear isemp_rectxt
        
        name = cell2mat(reco_txt);
        EEGrec.event(a).type = name;
        EEGrec.urevent(a).type = name;
        EEGrec.urevent(a).duration = 0;
        EEGrec.event(a).duration = 0;
        
        
        
        %% if the event is to be ignored (copied without changes):
    else
        % CHANGE so that the event is copied with all fields
        
        for f = 1:length(fld)
            EEGrec.event(a).(fld{f}) = EEG.event(a).(fld{f});
        end
    end
    
end

%% ordering fields
all_fields = fieldnames(EEGrec.event(1));
adr_type = find(strcmp('type', all_fields));
urev_type = find(strcmp('urevent', all_fields));
lat_type = find(strcmp('latency', all_fields));
adrr = [adr_type, lat_type, urev_type];
all_fields(adrr) = [];
all_fields = sort(all_fields);

if ~isempty(adr_type)
    all_fields = [{'type'}; {'latency'}; {'urevent'}; all_fields];
else
    all_fields = [{'latency'}; {'urevent'}; all_fields];
end
EEGrec.event = orderfields(EEGrec.event(1:end), all_fields);

