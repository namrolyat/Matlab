function BarGratingAnalysis
%BarGratingAnalysis
%
%Carries out analysis of the BarGratingPilot behavioural data. First loads
%all of the data (loop over subject x run), then loops through conditions
%to generate distributions of response errors for each one. 

sbj_list = {'020312SB', '050312FV'};
%sbj_list = {'020312SB'};
%sbj_list={'050312FV'};

num_sbj = length(sbj_list);
num_cond = 3;
CLabels = {'Short Bar', 'Long Bar', 'Grating'};

data_path = 'PilotData/';

hist_x = -28.5:3:28.5;
bar_x = -30:6:30;



%% Make histograms per sbj x cond
%First load data and store in a matrix of run x trial, then make histograms
%based on all data in each condition

data = nan(num_sbj, num_cond, length(hist_x));

for sbj_idx = 1:num_sbj

    run_files = dir([data_path, 'd', sbj_list{sbj_idx}, '*run*mat']);
    load([data_path, run_files(1).name], 'Parameters');    
    sbj_data = nan(length(run_files), Parameters.NumTrials);
    
    for run_idx = 1:length(run_files)
        load([data_path, run_files(run_idx).name], 'RespDeviation');
        sbj_data(run_idx,:) = RespDeviation(:,1);
    end
    
    for cond_idx = 1:num_cond
    	data(sbj_idx, cond_idx, :) = hist(reshape(sbj_data(Parameters.CondList==cond_idx,:), Parameters.NumRuns/num_cond*Parameters.NumTrials, 1),hist_x);
    end
    
end


%% Plot histograms

histograms = squeeze(mean(data,1)); %Average over subjects (we can do this because the bins are the same)
figure;

for cond_idx = 1:num_cond
    subplot(1,num_cond,cond_idx);
    hold on
    
    bar(hist_x, squeeze(histograms(cond_idx,:)));
    %v = axis;
    %if v(4) > max_v, max_v = v(4); end
    axis([bar_x(1), bar_x(end), 0 25]);
    set(gca,'XTick', bar_x);
    title(Parameters.CLabels{cond_idx}, 'Fontsize', 18);
    
    coeff = g_fit([25 10], hist_x, histograms(cond_idx,:));
    
    g = coeff(1) * exp(-(-30:0.1:30).^2/(2*coeff(2).^2));
    plot(-30:0.1:30, g, '-r', 'LineWidth', 5);
    text(6,23, ['sd: ', num2str(coeff(2))]);
    
    xlabel('Response Error (deg.)', 'FontSize', 14)
    ylabel('Count', 'FontSize', 14)
    
end

%{
for sp_idx = 1:cond_idx
    figure(h);
    subplot(1,num_cond,cond_idx)
    axis([v(1:3), max_v]);   %Make it so all plots have the same vertical axis (they have the same horizontal axis already)
end
%}


%% Confidence Ratings
%Go through trials and store RespDeviations based on CR. Basically, just
%make bins of 4 categories. Also, store CR histograms per run so that we
%can look at the distribution and mean per condition.

%data = nan(num_sbj, 4, Parameters.NumTrials*Parameters.NumRuns); %It's assumed in this code that everybody has an equal number of runs
%Dims: sbj x CR x RespDev

data = nan(num_sbj, Parameters.NumRuns, 4, Parameters.NumTrials);
%Dims: sbj x Run x CR RespDev

CRdata = nan(num_sbj, Parameters.NumRuns, 4);

for sbj_idx = 1:num_sbj
    run_files = dir([data_path, 'd', sbj_list{sbj_idx}, '*run*mat']);
    
    for run_idx = 1:Parameters.NumRuns
        load([data_path, run_files(run_idx).name], 'RespDeviation', 'CR');        
        for CR_idx = 1:4
            numQualify = sum(CR == CR_idx);
            %a = [sbj_idx run_idx CR_idx numQualify];
            %disp(a);
            %data(sbj_idx, CR_idx,
            %((run_idx-1)*Parameters.NumTrials)+(1:numQualify)) = RespDeviation([Trial.ConfidenceRating] == CR_idx, 1);
            data(sbj_idx, run_idx, CR_idx, 1:numQualify) = RespDeviation(CR == CR_idx, 1);            
            CRdata(sbj_idx, run_idx, CR_idx) = numQualify;
        end
    end    
end

%% Plot RDs against CRs
%First average over trials to get means per run per CR, then reorganize to
%get means per condition (this requires CondList), then average/std to get
%mean and SEM of Response Error for each condition x CR

data = squeeze(nanmean(abs(data),4)); %Average over trials, dims: sbj x run x CR. Also we want absolute errors here.
orgdata = nan(num_sbj, num_cond, 4); %Dims: sbj x cond x CR

for sbj_idx = 1:num_sbj
    run_files = dir([data_path, 'd', sbj_list{sbj_idx}, '*run*mat']);
    load([data_path, run_files(1).name], 'Parameters');
    for cond_idx = 1:num_cond
        orgdata(sbj_idx, cond_idx, :) = squeeze(nanmean(data(sbj_idx,Parameters.CondList==cond_idx,:),2)); %Dimension shrinking rather than reduction    
    end
end

mean_plot = squeeze(nanmean(orgdata,1));
std_plot = squeeze(nanstd(orgdata,[],1))/sqrt(num_sbj);

figure;

for cond_idx = 1:num_cond
    subplot(1,3,cond_idx);
    for cr_idx = 1:4
        bar(1:4, mean_plot(cond_idx,:));
        hold on
        errorbar(1:4, mean_plot(cond_idx,:), std_plot(cond_idx,:), '*r');
        xlabel('Confidence Rating', 'FontSize', 14);
        ylabel('Response Error', 'FontSize', 14);    
        title(Parameters.CLabels{cond_idx}, 'FontSize', 18);
    end
end

%% Plot CR histograms & means per condition

orgdata = nan(num_sbj, num_cond, 4);

for sbj_idx = 1:num_sbj
    run_files = dir([data_path, 'd', sbj_list{sbj_idx}, '*run*mat']);
    load([data_path, run_files(1).name], 'Parameters');
    for cond_idx = 1:num_cond
        orgdata(sbj_idx, cond_idx, :) = squeeze(nanmean(CRdata(sbj_idx,Parameters.CondList==cond_idx,:),2)); %Dimension shrinking rather than reduction    
    end
end

mean_plot = squeeze(nanmean(orgdata,1));
std_plot = squeeze(nanstd(orgdata,[],1))/sqrt(num_sbj);

figure;

for cond_idx = 1:num_cond
    subplot(1,3,cond_idx);
    for cr_idx = 1:4
        bar(1:4, mean_plot(cond_idx,:));
        hold on
        errorbar(1:4, mean_plot(cond_idx,:), std_plot(cond_idx,:), '*r');
        xlabel('Confidence Rating', 'FontSize', 14);
        ylabel('Count', 'FontSize', 14);    
        title(Parameters.CLabels{cond_idx}, 'FontSize', 18);        
    end
end

end

