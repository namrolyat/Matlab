% function SetInitialCond()

clear all

expdir = pwd;
datadir='Data_Scanning'; 
%cd([expdir filesep datadir])

numScans = 24;
all_orientations = [10 55 100 145];

rand('twister', sum(100*clock));

%%COUNTERBALANCE ACROSS RUNS
% master_orientations(:,1) = kron(all_orientations', ones(length(all_orientations),1)); %left VF
% master_orientations(:,2) = repmat(all_orientations', length(all_orientations), 1); %right VF
% 
% %orientations, runnrs, VFs
% for i=1:length(all_orientations):numScans
%     ind = Shuffle(1:size(master_orientations,1));
%     master_master(:,i:i+3,:) = reshape(master_orientations(ind,:), length(all_orientations), length(all_orientations), 2); % *2=attended vs unattended, 2=nVF 
% end
% 
% %INDEPENDENTLY PRESENTED IN TWO HEMIFIELDS
% for i=1:numScans
%     ind = [Shuffle(1:length(all_orientations)), Shuffle(1:length(all_orientations))];
%     master_master(:,i,:) = reshape(all_orientations(ind(:)), length(all_orientations), 1, 2); % *2=attended vs unattended, 2=nVF 
% end

%%COUNTERBALANCE ACROSS RUNS; ONE OF EACH ORIENTATION PER RUN
runns = [1 2 3 4; 2 3 4 1; 3 4 1 2; 4 1 2 3];
for i=1:4:numScans
    attended_orientations = Shuffle(all_orientations);
    unattended_orientations = Shuffle(all_orientations);
    for j = 1:4
    [attended_ind,unattended_ind] = find(runns==j);
    master_master(:,i+j-1,1) = attended_orientations(attended_ind);
    master_master(:,i+j-1,2) = unattended_orientations(unattended_ind);
    end
end


subName = input('Initials of subject? (default="tmp")  ','s');		% get subject's initials from user
if isempty(subName); subName = 'tmp'; end

theDate = datestr(date,2);											
theDate(6) = []; theDate(3) = [];									
theDate = [theDate(5:6) theDate(1:2) theDate(3:4)];				

initialcond_file = [theDate '_' subName 'InitialCond_4scanning'];	% name of data file with intial cond.
save(initialcond_file, 'master_master');
cd(expdir)


% for i = all_orientations
%     for j = all_orientations
%         count(i,j) = sum(find(master_master(:,:,1)==i) == find(master_master(:,:,2)==j));
%         disp(['attend: ' num2str(i) ' unattend: ' num2str(j) ' -> ' num2str(count(i,j))])
%     end
% end