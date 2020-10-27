try
    
   colorseq = repmat([1,2], 1, 100);

   runexp   = 1;
   RT=screencolortest(colorseq,runexp);%RT gives you the reaction time of each 
                                     %screen presentation. See lines 46-54 
                                     %from screencolortest for details
Screen('CloseAll');
ShowCursor;
%fwrite(s, 0);
%fwrite(s, 0);
fclose(instrfindall);
delete(instrfindall);

                                     
                                     
catch ME_2
%    fwrite(s, 0);
%    fwrite(s, 0);
    Screen('CloseAll');
    ShowCursor;   
    fclose(instrfindall);
    delete(instrfindall);
    %throw(ME_2);
    rethrow(ME_2);
end  % try..cach..
