%Testscript BITSI
%This script will send triggers to the specified COM port

b = Bitsi('/dev/ttyS0');
i=1;

% if mod(i,2)==1
%     Screen_color = 0;
% else
%     Screen_color = 150;
% end

%Window= Screen('OpenWindow',0,Screen_color);
[window, windowRect] = Screen('OpenWindow', 0, 150);
while i < 257
    %Screen('FillRect', window, [0 1 0]);
    b.sendTrigger(i);
    pause(1);
    i=i+1;
end
Screen('CloseAll');
b.close();