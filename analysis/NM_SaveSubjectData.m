% Helper to save the subject data in the right folder
%
% Inputs:
%   * params: {param, val} pairs to be added to subject_data.parameters

function NM_SaveSubjectData(params)

% Pretty simple...
global GLA_subject_data;
global GLA_subject;

% Add each parameter
for p = 1:length(params)
    GLA_subject_data.parameters.(params{p}{1}) = params{p}{2};
end

% Set and save
subject_data = GLA_subject_data; %#ok<NASGU>
save_file = [NM_GetCurrentDataDirectory() '/analysis/' ...
    GLA_subject '/' GLA_subject '.mat'];
save(save_file, 'subject_data');

