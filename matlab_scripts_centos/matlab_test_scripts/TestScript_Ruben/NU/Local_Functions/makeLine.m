function img = makeLine(iw, ih, DiamPix)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%if nargin<4, Orientation = 0; end
if nargin<3, DiamPix = 1; end

if mod(iw,2), iw = iw+1; end %Must be even
if mod(ih,2), ih = ih+1; end
if mod(DiamPix,2), DiamPix = DiamPix+1; end

%Orientation = 180-Orientation;

%xDiam = floor(DiamPix/sin(Orientation/180*pi));
%if mod(xDiam,2), xDiam = xDiam + 1; end %Must be even
%slope = tan(Orientation/180*pi);
%[x,y] = meshgrid(-iw/2:iw/2-1, ih/2:-1:-ih/2+1);

[x,y] = meshgrid(1:iw, 1:ih);
img = (y > (iw/2-DiamPix/2) & y <= (iw/2+DiamPix/2));



end

