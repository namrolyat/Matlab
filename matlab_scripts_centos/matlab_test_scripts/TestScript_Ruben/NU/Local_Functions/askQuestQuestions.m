function [thresholdGuess,priorSd] = askQuestQuestions()

thresholdGuess = input('What is your initial estimate of the mean threshold?  (default=5, regular scale)');
priorSd = input('What is your initial estimate of the standard deviation of the threshold?  (default=1, log scale)');

if isempty(thresholdGuess), thresholdGuess=5; end
if isempty(priorSd), priorSd=1; end


