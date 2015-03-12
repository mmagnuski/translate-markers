function [out, translation] = SupportTrans(translation)

% supportive function that analyzes the
% translation matrix extracting some
% useful information - easies up the
% rest of DIN translation

% number of DIN packs - 'features'
out.numfeat = size(translation,2);
num_feat = out.numfeat;

%% checking ommissions:
% dins that are meant to be ignored
out.omit = false(1,num_feat);

for a = 1:num_feat
    if isempty(translation{3,a})
        out.omit(a) = true;
    end
end

%% checking features without fields
% dins that are not omitted but do not
% require event fields
out.nofield = false(1,num_feat);

for a = 1:num_feat
    if ~out.omit(a) && strcmp(translation{2,a}, '')
        out.nofield(a) = true;
    end
end

%% need to find values?
% if not all values are given
out.valfind = false(1,num_feat);

for a = 1:num_feat
    if ~out.omit(a) && ~(size(translation{3,a},1) == (2^(translation{1,a})))
        out.valfind(a) = true;
    end
end

%% are there text values?
out.textval = zeros(1,num_feat);
out.len = zeros(1,num_feat);

for a = 1:num_feat
    if ~out.omit(a)
        out.len(a) = size(translation{3,a},2);
        for b = 1:out.len(a)
            if ischar(translation{3,a}{1,b})
                out.textval(a) = b;
            end
        end
    end
end

%% what are the bitvalues?
out.bitval = cell(1,num_feat);
out.nbits = 0;
for a = 1:num_feat
        bts = translation{1,a};
        out.nbits = out.nbits + bts;
        out.bitval{a} = (ones(1,bts)*2).^[bts-1:-1:0]; %#ok<NBRAK>
end

%% whether conditions are present
out.cond = false(1,num_feat);

if size(translation,1) > 3

    for a = 1:num_feat
        if ~out.omit(a)
            if ~isempty(translation{4,a})
                if size(translation{4,a},2) ~= 4 || ~iscell(translation{4,a})
                    if ~iscell(translation{4,a})
                        translation{4,a} = translation(4,a);
                    end
                translation{4,a} = DINTr_cond_recode(translation{4,a});
                end
                
                if ~isempty(translation{4,a})
                    out.cond(a) = true;
                end
            end
        end
    end
    
end

out.anycond = sum(out.cond) > 0;
out.adrcond = find(out.cond);
    