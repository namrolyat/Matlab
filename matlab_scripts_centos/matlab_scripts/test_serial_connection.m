% Matlab test script to test serial connection(s)
%-------------------------------------------------------------------------

% Check available ports is Linux
%
% To see what serial ports are available in Linux open a terminal and type
% the following command:
%    setserial -bg /dev/ttyS*
%
% This will list the serial port available as shown below:
%    /dev/ttyS0 at 0x03f8 (irq = 4) is a 16550A
%    /dev/ttyS1 at 0xcc40 (irq = 11) is a 16550A
%    /dev/ttyS2 at 0xcc48 (irq = 11) is a 16550A
%    /dev/ttyS3 at 0xcc50 (irq = 11) is a 16550A
%
% Note: this is a Linux command and not Matlab!
%-------------------------------------------------------------------------

% Create a serial port object in Matlab
%
% To use a serial port in Matlab we first have to create a serial port
% object. To create a serial port object type:
%    s = serial('/dev/ttyS0');
%
% Note: The serial port object gets associated with port ttyS0.
%
% In the Matlab workspace you'll find the object 's' that you just created.
% To inspect the object.rightclick on it and select "Display Summary".
% This will dispaly a summary like the one below:
%
%    Serial Port Object : Serial-/dev/ttyS0
%
%      Communication Settings
%          Port:               /dev/ttyS0
%          BaudRate:           9600
%          Terminator:         'LF'
%
%       Communication State
%          Status:             closed
%          RecordStatus:       off
%
%       Read/Write State
%          TransferStatus:     idle
%          BytesAvailable:     0
%          ValuesReceived:     0
%          ValuesSent:         0
%-------------------------------------------------------------------------

% Configuring Communication Setttings
%
% Before we can write or read data, we have to make sure that the serial
% object and the serial device (e.g. the BITSI) use the same communication
% settings.
% When using the BITSI, the following setting apply:
%    baudRate: 15200 bits/s
%    DataBits: 8 bits
%    Parity:   none
%    StopBits: 1
%
% To set the serial object with the same values, you can type:
%    set(s,'BaudRate',15200,'DataBits',8,'Parity','none','StopBits', 1)
%
% If you want to check any specific attribute, use the get command like:
%    get(s, 'BaudRate')
%    >> ans = 15200
%-------------------------------------------------------------------------

% Connect the serial object to the device
%
% Before we can perform a read or write operation, we must connect the
% serial port object to the device with fopen, as shown below:
%    fopen(s)
%
% If the object was succesfully connected, it's Status property is
% automatically configured to open.
%    get(s, 'Status')
%    >>ans = open
%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Send Code
%
% Now we are ready to send the code. If we want to write an 'A', we type:
%     fwrite(s,'A');
%
% If we want to send an integer we type:
%     fwrite(s,2);
%--------------------------------------------------------------------------

% Close Connection and Clean Up
%
% If we're done using the serial object, we can disconnect from the device,
% remove it from memory and clean the workspace:
%    fclose(s);
%    delete(s);
%    clear(s);
% -------------------------------------------------------------------------


s = serial('com49');      % create serial object

set(s,'BaudRate', 115200)      % config
set(s,'DataBits', 8);
set(s,'Parity','none');
set(s,'StopBits', 1);
set(s,'Terminator','CR');

fopen(s);                      % create connection

fwrite(s, '$');               % send code
fwrite(s, '?');
fwrite(s, '%');
%fwrite(s,2);                   % send code


S = sprintf('%s', '$amp 1%');
 fwrite(s, S);
 fprintf(s, '%s', '$ramp 1000%');
 pause(1); 
 fprintf(s, '%s', '$stim 3%');
 pause(1); 
 fprintf(s, '%s', '$go%');
 pause(5); 

fclose(s);                     % close connection
delete(s);                     % clear memory
clear s;                       % clear workspace
