%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File: Run_Analysis.m
%
% Notes:
%   * In theory, this function runs the whole analysis, however, it's 
%       primary purpose is to give the structure of the analysis. 
%       - Almost always it would probably be easier to run the functions 
%           one at a time...
%
% Inputs:
% Outputs:
% Usage: 
%   * Run_Analysis()
%
% Author: Douglas K. Bemis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Run_Analysis()

% Set the initial globals
NM_InitializeGlobals();

% Import the data...
NM_ImportData()

% Check the output to make sure everything looks good
NM_CheckData();

% Preprocess the data for analysis
NM_PreprocessData();

% This will preprocess the data that needs it and then perform simple
%   sanity checks (e.g. visual responses, fmri localizer...)
NM_SanityCheckData();

% Run the basis analysis functions
NM_AnalyzeData();