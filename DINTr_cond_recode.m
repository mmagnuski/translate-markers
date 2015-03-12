function rec_cond = DINTr_cond_recode(conditions)
% a helper function for DINTr function pack
% that is used for decoding additional conditions:
%
% NOW - for now we assume only simple conditions
% simple conditions are evaluated to check whether
% detected din value applies. So if normal din de-
% coding gives value A but the given condition is
% not fulfilled - the value is not used.
%
% input:
%   conditions  -  cell array of conditions
%         for condition rules see the DIN_Tranl documentation!
%         condition examples:
%                'NOT-VAL-OR(1, 2, 3)'
%                'OR(3, 5)'
% output:
%   rec_cond  -  cell matrix of size: conditions * 4
%                for any row:
%                1st column determines positive/negative condition
%                2nd column - type of condition ('VAL','ALLVAL','PACKVAL')
%                3rd column - OR / AND operator
%                4th column - within bracket content (for example DIN
%                             numbers
%
% condition types:
%                 1 --> DIN presence
%                 2 --> dinvalue (5 --> 0101 --> DIN presence 1 & 3)
%                 3 --> PackValue ({packnum, values})

% TO-DOs:
% final checks, the function seems to be working nicely

if iscell(conditions)
    rec_cond = cell(length(conditions),4);
    kill = false(length(conditions),1);
    
    for a = 1:length(conditions)
        curr_cond = conditions{a};
        % skl is everything before a '('
        skl = regexp(curr_cond, '[A-Z-]+\(', 'match');
        
        if ~isempty(skl)
            
            if iscell(skl)
                skl = skl{1};
            end
            % last 'skl' char is '(', we don't need it:
            skl = skl(1:end-1);
            
            % default prefix values
            rec_cond{a,1} = true;
            rec_cond{a,2} = 1;
            
            %% looking for NOT prefix (for example: NOT-OR):
            hyps = regexp(skl, '-');
            
            % if prefixes present:
            if ~isempty(hyps)
                lasthyp = hyps(end);
                
                % checking for 'NOT'
                if length(hyps) >= 1
                    
                    pref = skl(1:hyps(1)-1);
                    if strcmp(pref, 'NOT')
                        rec_cond{a,1} = false;
                    end
                end
                
                % checking for 'DINVAL'
                % 1 --> DIN presence
                % 2 --> dinvalue (5 --> 0101 --> DIN presence 1 & 3)
                % 3 --> PackValue ({packnum, values})
                if length(hyps) >= 1
                    hypb = 1; hype = hyps(1)-1;
                    if length(hyps) == 2
                        hypb = hyps(1)+1;
                        hype = hyps(2)-1;
                    end
                    pref = skl(hypb:hype);
                    if strcmp(pref, 'ALLVAL')
                        rec_cond{a,2} = 2;
                        clear hyps
                    elseif strcmp(pref, 'VAL')
                        rec_cond{a,2} = 3;
                        clear hyps
                    end
                end
                skl = skl(lasthyp+1:end);
            end
            
            
            %% saving the operator (OR or AND):
            % OR --> 1; AND --> 2;
            if strcmp(skl,'OR')
                rec_cond{a,3} = 1;
            elseif strcmp(skl,'AND')
                rec_cond{a,3} = 2;
            else
                kill(a) = true;
                continue
            end
            
            %% taking the bracketed content:
            b1 = regexp(curr_cond, '\(');
            b2 = regexp(curr_cond, '\)');
            
            if ~isempty(b2)
                b1 = b1(1);
                b2 = b2(1);
                content = curr_cond(b1+1:b2-1);
                vals = regexp(content, '[0-9]+', 'match');
                vals = cellfun(@str2num, vals);
                % vals = cell2mat(vals);
                rec_cond{a,4} = vals;
            else
                kill(a) = true;
                continue
            end
            
        else
            kill(a) = true;
            continue
        end
    end
    rec_cond(kill,:) = [];
else
    rec_cond = [];
end
