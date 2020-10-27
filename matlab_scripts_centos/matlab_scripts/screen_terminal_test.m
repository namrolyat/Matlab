% Linux script to test serial connection(s)
%-------------------------------------------------------------------------

% Check available ports is Linux
%
% To see what serial ports are available in Linux open a terminal and type
% the following command:
%    setserial -bg /dev/ttyS*
%
% This will list the serial port available as shown below:
%                                                   Connector#
%    /dev/ttyS0 at 0x03f8 (irq = 4) is a 16550A     main
%    /dev/ttyS1 at 0xd020 (irq = 17) is a 16650V2   2
%    /dev/ttyS2 at 0xd010 (irq = 18) is a 16650V2   3
%    /dev/ttyS3 at 0xd000 (irq = 19) is a 16650V2   4
%    /dev/ttyS4 at 0xf0a0 (irq = 17) is a 16550A    onboard
%    /dev/ttyS5 at 0xd030 (irq = 16) is a 16650V2   1
%
%-------------------------------------------------------------------------
%
% We assume that a Bitsi is connected to ttySx that we want to connect to.
% Open a terminal window and type:
> screen /dev/ttyS[0,1,2,3,5] 115200

% Now typing on the keyboard will light up the Bitsi input LED's. 
% Kill the current window
> Ctrl+a + k

% if the screen is still running, it will block the port from using.
% "screen -list" can be used to show all current screens and determine if 
% the screen is closed.
