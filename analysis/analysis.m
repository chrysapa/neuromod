%% Run this first to set the current analysis

% Home
% global GLA_meeg_dir; GLA_meeg_dir = '/Users/Doug/Documents/neurospin/meeg';
% global GLA_fmri_dir; GLA_fmri_dir = '/Users/Doug/Documents/neurospin/fmri';
% 
% Work
global GLA_meeg_dir; GLA_meeg_dir = '/neurospin/meg/meg_tmp/SimpComp_Doug_2013';
global GLA_fmri_dir; GLA_fmri_dir = '/neurospin/unicog/protocols/IRMf/SimpComp_Bemis_2013';

% The current analysis parameters
global GLA_subject; GLA_subject = 'ap100009';
global GLA_rec_type; GLA_rec_type = 'meeg';
global GLA_meeg_type; GLA_meeg_type = 'meg'; 
global GLA_meeg_trial_type; GLA_meeg_trial_type = 'blinks'; 
global GLA_fmri_type; GLA_fmri_type = 'localizer';


%% Note

% These can be run from any directory, but might be best to run from the
%   analysis directory. Then, to force redoing, can load the subject data,
%   reset the appropriate parameter and then save.


%% Import the data...

% The first step is to get the data in the right folders and named
% correctly

% This must be done manually for the EEG data and log files:
%   * Logs: Expected to be in the /logs/ subject folder and cleaned of
%       extraneous runs. Should keep the originals as _raw.txt
%           - Both _log.txt and _data.txt files.
%   * EEG: Need to convert these into .raw files using the NetStation
%       software. Then, add to the /eeg_data/ folder named appropriately
%       (e.g. subject_run_# / _baseline). 
%           - NOTE: Rename after conversion to avoid confusing NetStation.
%   * Eyetracking: In theory, this can be converted automatically, however,
%       best to do in the lab a) to check that the transfer was correct and
%       b) because conversion script doesn't work on linux.
%           - .asc files should be in the /eye_tracking_data/ folder and
%           named as usual (subject_run_# / _baseline).
%
% The MEG / fMRI data can be imported by running this funciton. In theory,
%   it will get the raw data from the appropriate acquisition folders and
%   convert it (either through maxfiltering or conversion to nifti).
%       - Only requirement is that the subject_notes.txt file is filled out
%           appropriately.
NM_ImportData()


%% Check the output to make sure everything looks good

% This function will check that all of the data is as expected (e.g. the 
%   stimuli, matching, triggers, timing, etc., etc.
NM_CheckFiles();


%% Some preprocessing

NM_PreprocessData();


%% Make sure our data is ok(ish)

% This will preprocess the data that needs it and then perform simple
%   sanity checks (e.g. visual responses, fmri localizer...)
NM_PerformSanityChecks();


%% Now, should run the analysis functions

NM_AnalyzeAllTimeCourses();


%% Test


%% MEEG Looping...
GLA_meeg_type = 'meg'; 
GLA_rec_type = 'meeg';
subjects = {'ap100009','cg120234','rg110386','mr080072','sa130042'};
subjects = {'ap100009'};
trial_types = {'word_1','word_2','word_3','word_4','word_5','delay','target','all'};
trial_types = {'word_1','word_2','word_3','word_4','word_5','delay','target'};
for s = 1:length(subjects)
    GLA_subject = subjects{s}; 

    NM_InitializeSubjectAnalysis();
%     NM_ImportData();

    % This makes sure the analysis will run (probably)
%     NM_CheckFiles();
%         NM_PreprocessResponses();
    for t = 1:length(trial_types)
        GLA_meeg_trial_type = trial_types{t};
        NM_PreprocessMEEGData();
%         NM_SummarizeMEEGData();
    end
%     NM_PerformSanityChecks();
end

%% fmri Looping...
% Work
GLA_meg_dir = '/neurospin/meg/meg_tmp/SimpComp_Doug_2013';
GLA_fmri_dir = '/neurospin/unicog/protocols/IRMf/SimpComp_Bemis_2013';
GLA_rec_type = 'fmri';
subjects = {'ap100009','cg120234','rg110386','sg120518','sa130042'};
for s = 1:length(subjects)
    GLA_subject = subjects{s}; 

%     NM_InitializeSubjectAnalysis();

%     NM_ImportData();


    % This makes sure the analysis will run (probably)
%     NM_CheckFiles();

%     GLA_fmri_type = 'localizer';
%     NM_PreprocessfMRIData();
%     NM_PerformSanityChecks();

%     NM_CheckDataFile();
    
%     GLA_fmri_type = 'experiment'; NM_CreateDesignFiles();
%     GLA_fmri_type = 'localizer'; NM_CreateDesignFiles();
% 
%     NM_PreprocessData();
%     NM_PerformSanityChecks();
%     GLA_fmri_type = 'experiment';
%     NM_CheckfMRIMovement();
%     NM_AnalyzefMRIData();
end

%% Initial filtering
cfg = [];
cfg.datafile = [NM_GetCurrentDataDirectory() '/meg_data/' ...
    GLA_subject '/' GLA_subject '_baseline_sss.fif'];

% Don't need higher than this for now
cfg.lpfilter = 'yes';
cfg.lpfreq = 120;

% Remove slow drifts
cfg.hpfilter = 'yes';
cfg.hpfreq = .3;
cfg.hpfilttype = 'fir'; % Necessary to not crash

% Get rid of line noise..
cfg.bsfilter = 'yes';
cfg.bsfreq = [49 51];
all_data = ft_preprocessing(cfg);

%
% Get rid of the harmonic too...
cfg = [];
cfg.bsfilter = 'yes';
cfg.bsfreq = [99 101];
all_data = ft_preprocessing(cfg, all_data);


%

% Epoching
NM_LoadSubjectData();
cfg = [];
cfg.pre_stim = -200;
cfg.post_stim = 600;
cfg.trialfun = 'NM_DefineMEEGBaselineTrial';
cfg.datafile = [NM_GetCurrentDataDirectory() '/meg_data/' ...
    GLA_subject '/' GLA_subject '_baseline_sss.fif'];
cfg = ft_definetrial(cfg);

% Apply the fieldtrip preprocessing
data = ft_redefinetrial(cfg, all_data);

%% Artifact rejection
cfg = [];
cfg.method = 'pca';
cfg.channel = 'MEG';
comp = ft_componentanalysis(cfg, data);

cfg = [];
cfg.viewmode = 'component';
cfg.channels = [1:10];
ft_databrowser(cfg,comp);

%% Artifact rejection
cfg = [];
cfg.channel = 'MEG';
cfg = ft_databrowser(cfg,data);
clean_data = ft_rejectartifact(cfg,data);

%% Artifact rejection 2
cfg = [];
cfg.channel = 'MEG';
cfg.method = 'summary';   % 'tral', 'channel', 'summary'
clean_data_2 = ft_rejectvisual(cfg,data);

%% Get the power spectrum

cfg            = [];
cfg.output     = 'pow';
cfg.method     = 'mtmfft';
cfg.foilim     = [0 125];
cfg.tapsmofrq  = 5;
cfg.keeptrials = 'yes';
cfg.channel    = {'MEG'};
freqfourier    = ft_freqanalysis(cfg, data);

%
plot(freqfourier.freq,squeeze(mean(mean(freqfourier.powspctrm,1),2)));


%% Visual inspection

cfg = [];
cfg.dataset = 'ap100009_baseline_sss.fif';
cfg.channel = 'MEG';


%%

cfg = [];
cfg.dataset = 'sa130042_baseline_sss.fif';
cfg.lpfilter = 'yes';
cfg.hpfilter = 'yes';
cfg.dftfilter = 'yes';
cfg.lpfreq = 100;
cfg.padding=10;
cfg.channel = 'MEG0113';
cfg.hpfreq = 1;
% cfg.hpfilttype = 'fir';

data = ft_preprocessing(cfg);

%%
figure
cfg = [];
cfg.showlabels = 'yes'; 
cfg.interactive = 'yes';
cfg.fontsize = 12; 
cfg.layout = 'neuromag306all.lay';

cfg.baseline = [-0.2 0];
cfg.magscale = 10;
ft_multiplotER(cfg, TTest_all_avg{4});

cfg.marker = 'off';
cfg.channel = {TTest_all_meg_data{1}.label{[3:3:306]}};
cfg.xlim = [0:.01:.2];  % Define 12 time intervals
cfg.zlim = [-2e-13 2e-13];      % Set the 'color' limits.
% ft_topoplotER(cfg,TTest_avg)

%%
% Run 1: ch_ind = 185; MEG1642
% Run 2: ch_ind = 185; MEG1642

avg = zeros(1,800);
for t = 1:80
%     avg = avg + meg_data.trial{t}(ch_ind,:);
    avg = avg + TTest_all_meg_data{1}.trial{t}(ch_ind,:);
end
avg = avg/80;
figure; plot(avg);

%%

hdr = ft_read_header('mr080072_baseline_sss.fif');
st_01_ind = find(strcmp(hdr.label,'STI001'));
dat = ft_read_data('mr080072_baseline_sss.fif','chanindx',st_01_ind);


% cmd = ['maxfilter-2.2 -force -f Speeded_Run_1.fif -o Speeded_Run_1_sss.fif -v -frame head -origin 0 0 40 -autobad on -badlimit 4'];

%%

global meeg_data;
data = meeg_data;
cfg                 =[];
cfg.method          = 'summary';
data             = ft_rejectvisual(cfg, data);

%%
cfg = [];
avg_data = ft_timelockanalysis(cfg, data);

%%

figure
cfg = [];
cfg.showlabels = 'yes'; 
cfg.interactive = 'yes';
cfg.fontsize = 12; 
cfg.layout = 'GSN-HydroCel-256.sfp';


% Baseline correct for now
cfg.baseline = [-0.2 0];

% Plot and save
ft_multiplotER(cfg, avg_data);




