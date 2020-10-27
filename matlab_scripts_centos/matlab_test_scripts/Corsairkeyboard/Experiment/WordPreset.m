% This script is written to precalculate the order of stimuli.
% We have a lot of cells containing different conditions/stimuli, though we
% intend to randomize/ shuffle all stimuli.  
% At the end of this function the output is a column with all stimuli
% shuffled. 

% Eventually in the script loop we will pick a stimulus in continuous
% order through trials. 


% these are shuffles stimulus cells.  Each participant will have a
% different order of  stimuli (except for the first three) 

freestyleWord_Sentence;
pseudoWordSentenceList; 
normalWordList;
normalWordSentenceList; 
pseudoWordList;

% These are the different conditions/ experimental sections that we will
% have.  Here these stimulus lists are put together in a cell.
ExperimentalSections = {freestyleWord_Sentence;PseudoWordList;PseudoWordSentenceList;NormalWordList;NormalWordSentenceList};

% these are the counters per condition.  We don't want to present any
% stimulus more than once and we want to control the presented stimuli.
% These stimuli  are put in cells above
First = 0;
Second = 0;
Third = 0;
Fourth= 0;
Fifth= 0;

%PseudoWordList = 2
%PseudoWordSentenceList = 3
%NormalWordList = 4
%NormalWordSentenceList = 5
% all conditionlists of words are represented by a number 1 to 5.  We want
% condition 1 to be the first conditions that we present before conditions
% 2 till 5.  Thus [1 1 1 0 is added to the vector first. Then the length of
% each list is filled in with the number of the condition (see list above).
% These numbers are repeated and eventually all shuffled up,  so we have a
% randomized condition presentation order.
ConditionRandomizer = Shuffle([repmat(1,(length(freestyleWord_Sentence)),1); repmat(2,(length(PseudoWordList)),1);repmat(3,(length(PseudoWordSentenceList)),1); repmat(4,(length(NormalWordList)),1);repmat(5,(length(NormalWordSentenceList)),1)]);

Word = {};
for Trial =  1:length(ConditionRandomizer);
    
    % Making count vector per condition so each stimulus is offered
    % once. ConTrial stands for the trial in a certain condition.  We
    % pull the words out of a shuffled word/ sentence matrix. Making
    % sure that we don't use words double etc. and still keep track on
    % the presented stimulus word/ sentence.
    
    % If we have had a certain condition from the ConditionRandomizer,  we
    % want to shift a word further in this condition to prevent using this
    % word/sentence double.  Thus each condition has it's own counter. 
    if ConditionRandomizer(Trial,1) == 1;
        First = (First+1);
        ConTrial = First;
    elseif ConditionRandomizer(Trial,1) == 2;
        Second = (Second+1);
        ConTrial = Second;
    elseif ConditionRandomizer(Trial,1) ==3;
        Third = (Third+1);
        ConTrial = Third;
    elseif ConditionRandomizer(Trial,1) ==4;
        Fourth = (Fourth+1);
        ConTrial = Fourth;
    elseif ConditionRandomizer(Trial,1) ==5;
        Fifth = (Fifth+1);
        ConTrial = Fifth;
    end
   
    % ExperimentalSections consists of a five-row collumn.  Condition
    % Randomizer will  randomly give values between 1-5 thus will indicate
    % the row we need in the column of cells within "ExperimentalSections"
    % Once we have a row within ExperimentalSections, we want to select 
    % a stimulus from the selected list in Experimental Sections,  this is
    % done by ConTrial, which stands for "ConditionTrial". ConditionTrial
    % is made to keep track on how many trials we have had for a certain
    % condition, sice we want to control and maintain every time we present
    % a certain condition. Thus this ConTrial selects the Row within the
    % Condition Column, to select the stimulus that will be presented. 

    % These seected stimuli are stored in a cell column called "Word" 
    % this allows stimulus order preset, without any calculations during
    % timing critical proceudres of our experiment.  
    Word{Trial,1} = ExperimentalSections{ConditionRandomizer(Trial,1),1}(ConTrial,1);   
end