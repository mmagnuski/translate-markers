function MassTranslate(Transl, Support, PathName, FileName)

if ~iscell(FileName)
    FileName = {FileName};
end

if ~isempty(FileName{1})
    % starting eeglab
    ALLEEG = eeglab;
    
    % transforming path to eeglab format:
    eeglab_path = regexprep(PathName, '\\', '\\\\');
    
    for a = 1:length(FileName);
        EEG = pop_loadset('filename', FileName{a},'filepath',eeglab_path);
        [~, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
        
        
        % doing what needs to be done:
        EEG = DIN_Translate(Transl, EEG, 'support', Support);
        
        % updating EEGlab
        ALLEEG = EEG;
        [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        % EEG = eeg_checkset( EEG );
        % ALLEEG = eeg_checkset( ALLEEG );
        eeglab redraw; % maybe not necessary
        
        % saving (overwriting!)
        EEG = pop_saveset( EEG, 'filename', FileName{a},'filepath', eeglab_path);
        [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); %#ok<NASGU>
        
        % deleting set
        ALLEEG = pop_delset( ALLEEG, 1 );
    end
end
