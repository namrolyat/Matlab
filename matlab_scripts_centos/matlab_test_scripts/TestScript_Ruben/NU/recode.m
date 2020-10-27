function recode
%RECODE 
%   Loads pilotdata from when confidence ratings where stored in the Trial
%   struct and saves them as a separate variable. The point being that we
%   don't then have to load the unwieldy Trial struct every time (which
%   contains the stimulus frames as well).

files = dir('PilotData/*PK*run*mat');

for file_idx = 1:length(files);
    fprintf(['Processing file ', files(file_idx).name, '...\n']);
    load(['PilotData/', files(file_idx).name]);
    CR = [Trial.ConfidenceRating];
    save(['PilotData/', files(file_idx).name], 'CR', '-append');    
end


end

