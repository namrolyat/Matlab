function NoiseLevelsAnalysis
%NoiseLevelsAnalysis Analyze data from the NoiseLevelsPilot
%
%Load data, make distributions.

% sbj{1}.ID = '050312RB';
% sbj{1}.UseRuns = 1:24;

% sbj{1}.ID = '050312JJ';
% sbj{1}.UseRuns = 1:24;

% sbj{1}.ID = '070312PK';
% sbj{1}.UseRuns = 1:8;

num_sbj = length(sbj);
num_cond = 4;
CLabels = {'None', 'Low', 'Medium', 'High'};

data_path = 'PilotData/';

%hist_x = -28.5:3:28.5;
%bar_x = -30:6:30;

hist_x = -46.5:3:46.5;
bar_x = -48:6:48;

data = nan(num_sbj, num_cond, length(hist_x));
MAE = nan(num_sbj, num_cond);
coeff = nan(num_sbj, num_cond, 3);

%% Make histograms per sbj x cond
%First load data and store in a matrix of run x trial, then make histograms
%based on all data in each condition

for sbj_idx = 1:num_sbj

    run_files = dir([data_path, 'd', sbj{sbj_idx}.ID, '*run*mat']);
    load([data_path, run_files(1).name], 'Parameters');    
    sbj_data = nan(length(run_files), Parameters.NumTrials);
    
    for run_idx = sbj{sbj_idx}.UseRuns
        load([data_path, run_files(run_idx).name], 'RespDeviation');
        sbj_data(run_idx,:) = RespDeviation(:,1);
    end
    
    for cond_idx = 1:num_cond
    	data(sbj_idx, cond_idx, :) = hist(reshape(sbj_data(Parameters.CondList==cond_idx,:), Parameters.NumRuns/num_cond*Parameters.NumTrials, 1),hist_x);
        MAE(sbj_idx, cond_idx) = squeeze(nanmean(nanmean(abs(sbj_data(Parameters.CondList==cond_idx,:)),2),1));
        coeff(sbj_idx, cond_idx, :) = g_fit([25 8 0], hist_x, squeeze(data(sbj_idx, cond_idx, :))');
    end
        
    
end

%% Plot histograms

histograms = squeeze(mean(data,1)); %Average over subjects (we can do this because the bins are the same)
errorbars = squeeze(std(data,[],1))/sqrt(num_sbj);
MAE = squeeze(mean(MAE,1));
coeff = squeeze(mean(coeff,1));

figure('Name','Response Error Distributions');
maximum=20;

for cond_idx = 1:num_cond
    subplot(2,2,cond_idx);
    hold on
    
    bar(hist_x, squeeze(histograms(cond_idx,:)));
    hold on
    errorbar(hist_x, histograms(cond_idx,:), errorbars(cond_idx, :), '*r');
    %v = axis;
    %if v(4) > max_v, max_v = v(4); end
    axis([bar_x(1), bar_x(end), 0 maximum]);
    set(gca,'XTick', bar_x);
    title(['Noise: ',CLabels{cond_idx}], 'Fontsize', 18);
        
    g = coeff(cond_idx,1) * exp(-((-48:0.1:48)-coeff(cond_idx,3)).^2/(2*coeff(cond_idx,2).^2));
    plot(-48:0.1:48, g, '-r', 'LineWidth', 3);
    text(18,maximum-2, ['sd: ', num2str(coeff(cond_idx,2))]);
    text(18,maximum-3, ['MAE: ', num2str(MAE(cond_idx))]);
    
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
    run_files = dir([data_path, 'd', sbj{sbj_idx}.ID, '*run*mat']);
    
    for run_idx = sbj{sbj_idx}.UseRuns
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

data = nanmean(abs(data),4); %Average over trials, dims: sbj x run x CR. Also we want absolute errors here.
orgdata = nan(num_sbj, num_cond, 4); %Dims: sbj x cond x CR

for sbj_idx = 1:num_sbj
    run_files = dir([data_path, 'd', sbj{sbj_idx}.ID, '*run*mat']);
    load([data_path, run_files(1).name], 'Parameters');
    for cond_idx = 1:num_cond
        orgdata(sbj_idx, cond_idx, :) = squeeze(nanmean(data(sbj_idx,Parameters.CondList==cond_idx,:),2)); %Dimension shrinking rather than reduction    
    end
end

mean_plot = squeeze(nanmean(orgdata,1));
std_plot = squeeze(nanstd(orgdata,[],1))/sqrt(num_sbj);

figure('Name', 'Response Error x CR per condition');

for cond_idx = 1:num_cond
    subplot(2,2,cond_idx);
    for cr_idx = 1:4
        bar(1:4, mean_plot(cond_idx,:));
        hold on
        errorbar(1:4, mean_plot(cond_idx,:), std_plot(cond_idx,:), '*r');
        xlabel('Confidence Rating', 'FontSize', 14);
        ylabel('Response Error', 'FontSize', 14);    
        title(CLabels{cond_idx}, 'FontSize', 18);
        axis([0 5 0 15]);
    end
end

%% Plot CR histograms & means per condition

orgdata = nan(num_sbj, num_cond, 4);

for sbj_idx = 1:num_sbj
    run_files = dir([data_path, 'd', sbj{sbj_idx}.ID, '*run*mat']);
    load([data_path, run_files(1).name], 'Parameters');
    for cond_idx = 1:num_cond
        orgdata(sbj_idx, cond_idx, :) = squeeze(nanmean(CRdata(sbj_idx,Parameters.CondList==cond_idx,:),2)); %Dimension shrinking rather than reduction    
    end
end

mean_plot = squeeze(nanmean(orgdata,1));
std_plot = squeeze(nanstd(orgdata,[],1))/sqrt(num_sbj);

figure('Name','CR Histograms');

for cond_idx = 1:num_cond
    subplot(2,2,cond_idx);
    for cr_idx = 1:4
        bar(1:4, mean_plot(cond_idx,:));
        hold on
        errorbar(1:4, mean_plot(cond_idx,:), std_plot(cond_idx,:), '*r');
        xlabel('Confidence Rating', 'FontSize', 14);
        ylabel('Count', 'FontSize', 14);    
        title(CLabels{cond_idx}, 'FontSize', 18);        
        axis([0 5 0 15]);
    end
end

end

