function varargout = DIN_Translate(Transl, varargin)

% DIN_Translate allows to translate DINs into
% meaningful events (provided a translation matrix)
% for more info check the documentation
% distributed with this function pack
%
% to translate one file:
% EEG = DIN_Translate(Transl, EEG)

% checking if rules of translation given
notemp = ~isempty(Transl);
varargout{1} = [];

% checking for mass
mass_do = false;
mass = strcmp('mass', varargin);
if sum(mass) > 0
    mass_do = true;
end

if notemp
    % checking if support given
    supp = strcmp('support', varargin);
    issupp = sum(supp) > 0;
    if issupp
        Support = varargin{find(supp) + 1};
    else
        [Support, Transl] = SupportTrans(Transl);
    end
else
    % Support = [];
    error('Translation matrix not given! Check the help pdf for details on how to create a translation matrix.');
end
clear mass supp issupp

isneg = false;
if nargin > 1
    isneg = sum(strcmp('negative', varargin))>0;
end

% if you want to translate zeros and ones (test translation matrix):
if isnumeric(varargin{1}) && notemp && size(varargin{1},2) == sum(cell2mat(Transl(1,:)))
    for a = 1:size(varargin{1},1)
        EEG.event(a).type = 'whoknows';
        EEG.event(a).urevent = a;
        EEG.urevent(a).type = 'whoknows';
        EEG.urevent(a).latency = a*120;
        EEG.event(a).latency = a*120;
        EEG.event(a).type2 = logical(varargin{1}(a,:));
    end
    leaveout = false(length(EEG.event),1);
    varargout{1} = EventRecode(EEG, Transl, Support, leaveout);
else
    % if we do NOT need to massivly translate:
    if ~mass_do
        EEG = varargin{1};
        if isfield(EEG, 'event') && isfield(varargin{1}, 'urevent')
            
            % checking number of dins in the original file
            
            % then we check first event:
            firstev = EEG.event(1);
             if ~isfield(firstev, 'type2')
                % je¿eli nie istniej pole type2
                % znajdujemy sklejone DINy
                [sametime, dins, leaveout] = DINTr_reko(EEG);
                
                % tworzymy na tej podstawie nowe eventy
                [EEG.event, EEG.urevent, leaveout] = DINout(EEG, sametime, dins, leaveout);
                
                % if negative...
                if isneg
                    EEG.event = DIN_InverseNegative(EEG.event, leaveout);
                end
             end
            if notemp
                varargout{1} = EventRecode(EEG, Transl, Support, leaveout);
            end
        end
    else
        % if we need to massively translate:
        folderin = strcmp('folder', varargin);
        if sum(folderin)>0
            PathName = varargin{find(folderin) + 1};
            if PathName(end) ~= '\'
                PathName = [PathName, '\'];
            end
            FileName = dir([PathName '*.set']);
            FileName = {FileName.name};
        else
            [FileName,PathName] = uigetfile('*.set','MultiSelect', 'on');
        end
        MassTranslate(Transl, Support, PathName, FileName);
    end
end

