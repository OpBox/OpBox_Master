function data = BehGoNogoLoadTempFile(filename)

file_char = LoadFileText(filename);

%% Parse data
% Field name from newline to | pipe-space, data from space to end of line which is \13\10

idx_newlines = find(file_char==13);
idx_newlines = [-1; idx_newlines];
idx_delim = find(file_char == '|');
post_delim = 1;


%% Process text looking for fields
num_newlines = length(idx_newlines);
all_labels = cell(num_newlines-1, 1);
all_data = cell(num_newlines-1, 1);
for i_line = 1:num_newlines-1
    label = file_char(idx_newlines(i_line)+2:idx_delim(i_line)-1); % +2 to account for /13/10 end of line. -1 to end right before delimiter
    label = label(:)'; % comes in as col vector, convert to row

    data = file_char(idx_delim(i_line)+post_delim:idx_newlines(i_line+1)-1); % +1 if only delim, +2 if delim & space. -1 to end before new line
    if sum(isletter(data)) || sum(':' == data) || sum('-' == data)
        % text data, change to row from column vector
        data = data(:)';
    else
        % numerical data, pull it out
        data(',' == data) = 0;
        data = sscanf(data, '%ld');
    end
    
    all_labels{i_line} = label;
    all_data{i_line} = data;
end

%% Switch and process each label
clear data;
data.ts_free_rwd = [];

name_labels = unique(all_labels);
for i_label = 1:numel(name_labels)
    idx_labels = find(strcmp(all_labels, name_labels{i_label}));
    if numel(name_labels{i_label}) > 1
        data.(name_labels{i_label}) = all_data{idx_labels(1)};
    else
        switch name_labels{i_label}
            case 'A'
                data.ts_trial_on = vertcat(all_data{idx_labels});
            case 'a'
                data.ts_trial_off = vertcat(all_data{idx_labels});
            case 'N'
                data.ts_np_in = vertcat(all_data{idx_labels});
            case 'n'
                data.ts_np_out = vertcat(all_data{idx_labels});
            case 'L'
                data.ts_lick_in = vertcat(all_data{idx_labels});
            case 'l'
                data.ts_lick_out = vertcat(all_data{idx_labels});
            case 'R'
                data.ts_reward_on = vertcat(all_data{idx_labels});
            case 'r'
                data.ts_reward_off = vertcat(all_data{idx_labels});
            case 'F'
                data.ts_free_rwd = vertcat(all_data{idx_labels});
            case 'S'
                data.ts_stim_on = vertcat(all_data{idx_labels});
            case 's'
                data.ts_stim_off = vertcat(all_data{idx_labels});
            case 'P'
                data.ts_opto_on = vertcat(all_data{idx_labels});
            case 'p'
                data.ts_opto_off = vertcat(all_data{idx_labels});
            case 'D'
                data.ts_distract_on = vertcat(all_data{idx_labels});
            case 'd'
                data.ts_distract_off = vertcat(all_data{idx_labels});
            case 'G'
                stim_data = vertcat(all_data{idx_labels});
                data.stim_class = int16(stim_data(:, 1));
                data.stim_id = int16(stim_data(:, 2));
            case 'O'
                stim_data = vertcat(all_data{idx_labels});
                data.response = int16(stim_data(:, 1));
                data.outcome = int16(stim_data(:, 2));
            case 'm'
                data.ts_mt_end = vertcat(all_data{idx_labels});
            case 'I'
                data.ts_iti_end = vertcat(all_data{idx_labels});
            case 'T'
                data.ts_start = vertcat(all_data{idx_labels});
            case 't'
                data.ts_end = vertcat(all_data{idx_labels});
            case 'U'
                data.stim_upcoming = vertcat(all_data{idx_labels});
            otherwise
                fprintf('Label %s not recognized\n', name_labels{i_label});
        end
    end
end
fprintf('\n');

%% Add additional fields
data.dur = all_data{end};
if ~isfield(data, 'ts_np_in')
    data.ts_np_in = [];
end
if ~isfield(data, 'ts_np_out')
    data.ts_np_out = [];
end

%% Recast data fields: Char
char_fields = {'stim_class', 'stim_id', 'response', 'outcome'};
for i_field = 1:numel(char_fields)
    if isfield(data, char_fields{i_field})
        data.(char_fields{i_field}) = char(data.(char_fields{i_field}));
    end
end

%% Recast data fields: Timestamps
field_names = fieldnames(data);
for i_field = 1:numel(field_names)
    if strncmp(field_names{i_field}, 'ts_', 3) || strncmp(field_names{i_field}, 'Ms', 2)
        data.(field_names{i_field}) = double(data.(field_names{i_field}));
    end
end

