function CardinalAxes
%CARDINALAXES
%
%Analyze pilot data for effects around the cardinal (vertical and
%horizontal) axes. Can use all pilot data as the thing of interest is the
%stimulus orientation, which will have to be within some distance of 0 or
%90 degrees.
% 
% sbj{1}.ID = '050312RB';
% sbj{1}.UseRuns = 1:24;
% 
% sbj{2}.ID = '070312PK';
% sbj{2}.UseRuns = 1:8;
% 
% sbj{3}.ID = '020312SB';
% sbj{3}.UseRuns = 1:18;
% 
% sbj{4}.ID = '050312FV';
% sbj{4}.UseRuns = 1:18;
% 
 sbj{1}.ID = '090312PK';
 sbj{1}.UseRuns = 1:16;
% 
sbj{2}.ID = '090312SB';
sbj{2}.UseRuns = 1:8;

% sbj{5}.ID = '050312JJ';
% sbj{5}.UseRuns = 1:24;

num_sbj = length(sbj);

data_path = 'PilotData/';

hist_x = -46.5:3:46.5;
bar_x = -48:6:48;

data = nan(num_sbj, 2, length(hist_x));
coeff = nan(num_sbj, 2, 3);

CardWidth = 2.5;
CLabels = {['Cardinal +/- ', num2str(CardWidth)], 'Other'};

for sbj_idx = 1:num_sbj
    
    run_files = dir([data_path, 'd', sbj{sbj_idx}.ID, '*run*mat']);
    load([data_path, run_files(1).name], 'Parameters');    
    sbj_data = nan(length(run_files), 2, length(hist_x));
    
    for run_idx = sbj{sbj_idx}.UseRuns
        load([data_path, run_files(run_idx).name], 'OriList', 'RespDeviation');
        Orientations = [OriList{:}];
        Cardinal = ((Orientations > 0 & Orientations < 0+CardWidth) | (Orientations > 180-CardWidth & Orientations < 180) | (Orientations > 90-CardWidth & Orientations < 90+CardWidth));
        sbj_data(run_idx,1,:) = hist(RespDeviation(Cardinal,1),hist_x);
        sbj_data(run_idx,2,:) = hist(RespDeviation(~Cardinal,1),hist_x);        
    end %run_idx
    
    for card_idx = 1:2
        data(sbj_idx,card_idx,:) = squeeze(sum(sbj_data(:,card_idx,:),1))/sum(sum(sbj_data(:,card_idx,:),1),3)*100;            
        coeff(sbj_idx, card_idx, :) = g_fit([40 8 0], hist_x, squeeze(data(sbj_idx, card_idx, :))');
    end
    
    
end %sbj_idx

%% Plot histograms

histograms = squeeze(mean(data,1)); %Average over subjects (we can do this because the bins are the same)
errorbars = squeeze(std(data,[],1))/sqrt(num_sbj);
%MAE = squeeze(mean(MAE,1));
coeff = squeeze(mean(coeff,1));

figure('Name','Response Error Distributions');
maximum=30;

for card_idx = 1:2
    subplot(1,2,card_idx);
    hold on
    
    bar(hist_x, squeeze(histograms(card_idx,:)));
    hold on
    errorbar(hist_x, histograms(card_idx,:), errorbars(card_idx, :), '*r');
    %v = axis;
    %if v(4) > max_v, max_v = v(4); end
    axis([bar_x(1), bar_x(end), 0 maximum]);
    set(gca,'XTick', bar_x);
    title(CLabels{card_idx}, 'Fontsize', 18);
        
    g = coeff(card_idx,1) * exp(-((-48:0.1:48)-coeff(card_idx,3)).^2/(2*coeff(card_idx,2).^2));
    plot(-48:0.1:48, g, '-r', 'LineWidth', 3);
    text(18,maximum-2, ['sd: ', num2str(coeff(card_idx,2))]);
    %text(18,maximum-3, ['MAE: ', num2str(MAE(cond_idx))]);
    
    xlabel('Response Error (deg.)', 'FontSize', 14)
    ylabel('Percentage', 'FontSize', 14)
    
end

disp('here');

end

