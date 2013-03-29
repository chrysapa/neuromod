% Helper to parse and check the triggers from the eye tracker file
%
% NOTE: Already confirmed that the log accurately reflects what was
%   displayed during the experiment. 
%
% This will then add the triggers to the trial structures

function NM_CheckETTriggers()

% Load / create the data
NM_LoadSubjectData({{'log_parsed',1}});

% Make sure this is useful
global GLA_subject_data;
if ~GLA_subject_data.parameters.eye_tracker
    return;
end
    
global GLA_subject;
disp(['Checking eyetracker triggers for ' GLA_subject '...']);

% Check the runs
checkRuns();

% The clocalizer
checkLocalizer();

% Check the baseline
checkBaseline();

% Resave...
NM_SaveSubjectData({{'et_triggers_checked',1}});
disp(['Checked eye tracking triggers for ' GLA_subject '.']);


function checkBaseline()

triggers = parseRun('baseline');

% Beware, this order could change later...
global GLA_subject_data;
t_ind = 1;
b_types = fieldnames(GLA_subject_data.baseline);
for b = 1:length(b_types)
    for t = 1:length(GLA_subject_data.baseline.(b_types{b}))
        [GLA_subject_data.baseline.(b_types{b})(t).et_triggers t_ind] = ...
            checkTrial(GLA_subject_data.baseline.(b_types{b})(t),t_ind,triggers);            
    end
end

function checkLocalizer()

disp('WARNING: Not checking localizer triggers yet...');
return;

% Might not have it
global GLA_subject_data;
if GLA_subject_data.parameters.num_localizer_blocks == 0
    return;
end
error('Unimplemented');

% Check that we got all the triggers
function checkRuns()

global GLA_subject_data;
for r = 1:GLA_subject_data.parameters.num_runs
    checkRun(r); 
end


function checkRun(run_id)

% First, parse the triggers
triggers = parseRun(['run_' num2str(run_id)]);

% Now, check and add them
t_ind = 1;
global GLA_subject_data;
for t = 1:length(GLA_subject_data.runs(run_id).trials)
    [GLA_subject_data.runs(run_id).trials(t).et_triggers t_ind] = ...
        checkTrial(GLA_subject_data.runs(run_id).trials(t),t_ind,triggers);
end

% If it's good, it'll add it to it as well as checking
function [trial_triggers t_ind] = checkTrial(trial,t_ind,triggers)

trial_triggers = {};
for t = 1:length(trial.log_triggers)
    if strcmp(trial.log_triggers(t).type,'EyeLink')
        
        % See if the eye tracker trigger is the same as the log trigger
        if trial.log_triggers(t).value ~= triggers(t_ind).value
            error('Bad trigger.');
        end
        
        trial_triggers = NM_AddStructToArray(triggers(t_ind),trial_triggers);
        t_ind = t_ind+1;
    end
end


function triggers = parseRun(run_id)

% Load it up
global GLA_subject;
disp(['Parsing ' run_id '...']);
fid = fopen([NM_GetCurrentDataDirectory() '/eye_tracking_data/' ...
    GLA_subject '/' GLA_subject '_' run_id '.asc']);

% Only looking for the MEG trigger lines...
C = textscan(fid,'%s%s%s%s%s');
fclose(fid);

% And make sure they're right
triggers = {};
t_ind = find(strcmp('MEG',C{3}));
for t = 1:length(t_ind)
    triggers = NM_AddStructToArray(parseTrigger(t_ind(t),C), triggers);
end
disp(['Found ' num2str(length(triggers)) ' triggers.']);


% Make sure it's well formed
function trigger = parseTrigger(ind,C)

if ~strcmp(C{1}{ind},'MSG') || ~strcmp(C{3}{ind},'MEG') ||...
        ~strcmp(C{4}{ind},'Trigger:') 
    error('Bad trigger.');
end
trigger.et_time = str2double(C{2}{ind});
trigger.value = str2double(C{5}{ind});
    
