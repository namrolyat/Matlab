% small script on how to send EEG markers 

% EEGmarker = 'COM1';
EEGmarker = Bitsi('/dev/ttyS0');%EEGm_port,[0 0 0 0 0 0 0 0],30);

for i=1:255

    EEGmarker.sendTrigger(i);% Trigger for marker onset
    pause(0.2) % This is where usually the participant will type the message 
%     EEGmarker.close(i);       % close the marker    here it is after X seconds,  however in our script this will be at the return button press
end

fclose(EEGm_port) 




% This method will return as soon as there is a response. Both
% the response and the timestamp of the response will be returned.
% If 'timeout' seconds have been expired without a response, a response
% of 0 will be returned.
%
% onset      offset
%   +-----------+
%   |  (time)  A|
% --+           +----------------
%          Return button press
% Thus the onn state will start when we present the stimulus.  
% the off state of the marker will be met when the return button is
% pressed.
% All the typing in between is while the marker state is onn.  




%% EEG codes 
% initialize
addpath(bitsidir)
EEGm_port = 'COM1';
EEGmarker = bitsi_connect(EEGm_port,[0 0 0 0 0 0 0 0],30);
fclose(EEGmarker.serial);
clear EEGmarker
EEGmarker = Bitsi(EEGm_port);
%
% % send marker
% EEGmarker.sendTrigger(1); % in this case, marker value of 1
