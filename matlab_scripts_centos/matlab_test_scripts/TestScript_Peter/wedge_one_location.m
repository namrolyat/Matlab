function presentation_time = wedge_one_location(window, width, height, background, starting_angle, parity, time, change_fix)

global distFromScreen;
global pixelsPerCm;
global fixSize;

%Set parameters
angle = 90;
number_concentric_circles = 14;
number_rays_per_wedge = 3;
colors{1} = 255;
colors{2} = 0;
outer_degree = 12; % radius
inner_degree = 1; % radius
size_inner_most_circle = degrees2pixels(inner_degree, distFromScreen, pixelsPerCm);
size_each_cirlce = degrees2pixels((outer_degree-inner_degree)/number_concentric_circles, distFromScreen, pixelsPerCm);
fix_default_colour = 255;
fix_change_colour = 100;

%Draw the wedge ray by ray
for i=1:number_rays_per_wedge
    for j=number_concentric_circles:-1:1
        size = size_inner_most_circle + j*size_each_cirlce;
        if rem(parity+j+i,2) == 1
            which_color = 1;
        else
            which_color = 2;
        end
        
        Screen('FillArc', window, colors{which_color}, [width/2-size, height/2-size, width/2+size, height/2+size],...
            starting_angle+angle*(i-1)/number_rays_per_wedge, angle/number_rays_per_wedge);
    end
end
size = size_inner_most_circle;
Screen('FillOval', window, background, [width/2-size, height/2-size, width/2+size, height/2+size]);

if change_fix
    fix_colour = fix_change_colour;
else
    fix_colour = fix_default_colour;
end
%Screen('DrawDots', window, [width/2, height/2], dotSize, fix_colour);
Screen('DrawLine', window, fix_colour, width/2-fixSize/2, height/2, width/2+fixSize/2, height/2, 2);
Screen('DrawLine', window, fix_colour, width/2, height/2-fixSize/2, width/2, height/2+fixSize/2, 2);

presentation_time = Screen('Flip', window, time);
