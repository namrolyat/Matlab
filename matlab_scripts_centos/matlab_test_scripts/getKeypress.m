function getKeypress

s = serial('/dev/ttyS0');     % create serial object
set(s, 'BaudRate', 115200);
fopen(s);

FlushEvents;
WaitSecs(.5);     

fprintf('\nType in only letter or numbers keys.');
fprintf('\nPress Escape to quit the program.\n');

%startTime = GetSecs();        % initialize variables

FlushEvents;

try
   i = 0;
   while true  
      keyIsDown = 0; 
      while ~keyIsDown
         [keyIsDown, pressedSecs, keyCode] = KbCheck(-1);
      end
     
      fwrite(s,255);               % send Bitsi trigger
      pressedKey = KbName(find(keyCode)); % get key code
      fprintf('\n%d Key: %s', i, pressedKey);
   
      if pressedKey == 'Escape' % stop program when "Escape" is pressed
         break;
      end
     
     
      sameChar = 1;    % initial value for same button check
      while sameChar == 1
         FlushEvents;
         WaitSecs(0.2);
         keyIsDown = 0;               % press another key
         while ~keyIsDown                      % check key down
            [keyIsDown, pressedSecs, keyCode] = KbCheck(-1);
         end
         pressedKey_2 = KbName(find(keyCode)); % get key code
         if pressedKey_2 == pressedKey
             system('xset r off');
             %fprintf('repeating!');
         end
         if ~(pressedKey_2 == pressedKey)
            %fprintf('\nNot the same character!');
            sameChar = 0;  % reset flag to get out of the while loop
            
         end
         %clc;
         FlushEvents;
      end      
      
      FlushEvents;  % clear input buffer
      %clc;
      %system('xset r on');
      i = i + 1;
   end
  

catch E_1
      fclose(s);                   % clean up serial port
      delete(s);
      clear s;
      
      FlushEvents;                      % clear command window   
      system('xset r on');
      
      fprintf('aborted with error');
      rethrow(E_1);
      WaitSecs(2); 
      clc;
      return;
end 
%pressedKey = KbName(find(keyCode)); % get key code
%reactionTime = pressedSecs - startTime;

%fprintf('\nKey %s was pressed at %.4f seconmmds \n\n', pressedKey, reactionTime);

fprintf('\nDone!\n');
WaitSecs(2); 
system('xset r on');

clc;                         % clear command window
fclose(s);                   % clean up serial port
delete(s);
clear s;

