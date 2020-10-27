function [scrnum,frameHz,pixPerDeg,bigRect,calibrationFile] = GetMonitorInfo(situation) 


scrnum = 0;									% default presentation screen = 1st monitor
bigRect=Screen('Rect', scrnum);   				% Get size of presentation screen in local coordinates

switch situation
    case 0
 	%	Visual Angle Measurements at MacBook Pro Display Taken on June 25,
 	%	2007
	%	Screen dimensions, max viewable height 20.7 cm, max width = 33 cm
	% 	Distance from eye to screen = ~42 cm 
	%	Dimensions of screen 1440 x 900 pixels	
	%   visual_field_horizontal = atan(33/2/42)*180/pi*2 = 42.8955 deg, pixPerDeg = 1440/42.8955 = 33.57
	% 	visual_field_vertical  = atan(20.7/2/42)*180/pi*2 = 27.6870 deg, pixPerDeg = 900/27.6870 = 32.5062
    frameHz = 60;
    pixPerDeg = 33.0381;
    calibrationFile = [];

    case 1
    %   Trio Projector at DCCN
    %   Screen width: 38.5 cm
    %   Screen height: 29 cm
    %   Distance from eye to screen: 80 cm
    %   Screen resolution: 1024x768 pixls
    %   vf_horizontal = atan(38.5/2/80)*180/pi*2 = 27.0592 deg, pixPerDeg = 1024/27.0592 = 37.8430
    %   vf_vertical = atan(29/2/80)*180/pi*2 = 20.5467 deg, pixPerDeg = 768/20.5467 = 37.3783

    frameHz = 60;
    pixPerDeg = 37.6;
    calibrationFile = 'Calibration/calib_01-Mar-2012.mat';
    
    case 2
    %   Behavioural2 lab at DCCN, screen # (from left)
    %   Screen width: 37.5 cm
    %   Screen height: 30.1 cm
    %   Distance from eye to screen: 60 cm
    %   Screen resolution: 1024x768 pixels
    %   vf_horizontal = atan(37.5/2/60)*180/pi*2 = 34.7080 deg, pixPerDeg =
    %   1024/34.7080 = 29.5033
    %   vf_vertical = atan(30.1/2/60)*180/pi*2 = 28.1623, pixPerDeg =
    %   768/28.1623 = 27.2705
    
    frameHz = 60;
    pixPerDeg = 28.3869;
    calibrationFile = 'Calibration/calib_02-Mar-2012.mat';


    otherwise
    error('Invalid situation entered');
end


