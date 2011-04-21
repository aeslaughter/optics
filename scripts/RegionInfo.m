function [work,white] = RegionInfo(foldername,avgwhite,avgwork)
% REGIONINFO program for computing means on multiple objects
%__________________________________________________________________________
% SYNTAX:
%
% DESCRIPTION:
%
%
%__________________________________________________________________________

% 1 - GATHER FILENAMES
if isempty(foldername);
    foldername = gatherfile('dir','RegionInfoLastDir',{});
end
filename = dir([foldername,filesep,'*.imobj']);
if isempty(filename); return; end

% 2 - ESTABLISH THE HEADERS FOR THE OUTPUT ARRAY
work(:,1) = {'Name'; 'Region'; 'Mean: x';'Mean: y';...
    'CI1: x'; 'CI2: x'; 'CI1: y'; 'CI2: y';...
    'ExposureTime'; 'Fnumber'; 'ISO'; 'L'};
white = work;

% 3 - LOOP THROUGH EACH FILE
N = length(filename);
h = waitbar(0,'Performing image analysis, please Wait...');
for i = 1:N;
    name = [foldername,filesep,filename(i).name]; % Current filename
    load(name,'-mat'); % Load the object
    obj.convertColorSpace('xyl','xyY'); % Convert the colorspace

    % Compute Work Region data
    m = buildarray(obj,'work',avgwork);
    work = [work, m];
    
    % Compute White Region data
    m = buildarray(obj,'white',avgwhite);
    white = [white, m];

    delete(obj);
    waitbar(i/N,h);
end
close(h);

%---------------------------------------------------------------
function [M] = buildarray(obj,type,avg)
% BUILDARRAY constructs the data arrays for the various regions

% Compute the means and confidence intervals
R = obj.(type); % Regions of interest
[m,ci,~] = computeRegionMeanCI(R,1000,1,true); % Compute mean and ci's

% Average the data if desired
if avg;
    m = mean(m,1);
    ci = mean(ci,1);
end

% Collect the camera settings
T = obj.info.DigitalCamera.ExposureTime;
N = obj.info.DigitalCamera.FNumber;
S = obj.info.DigitalCamera.ISOSpeedRatings;
L = N^2*12.5 / (T * S);

% Assign the data to the output array
for j = 1:size(m,1); % Loop through the regions
    M{1,j} = obj.imObjectName; % Add filename
    
    % Define the region label
    if avg; 
        M{2,j} = type;
    else
        M{2,j} = [R(j).type,R(j).label];
    end
    
    M{3,j} = m(j,1); % Mean x
    M{4,j} = m(j,2); % Mean y
    M{5,j} = ci(j,1,1); % Lower c.i. on x
    M{6,j} = ci(j,1,2); % Upper c.i. on x
    M{7,j} = ci(j,2,1); % Lower c.i. on y
    M{8,j} = ci(j,2,2); % Upper c.i. on y
    M{9,j} = T;  % Exposure time
    M{10,j} = N; % F Number
    M{11,j} = S; % Senstivity
    M{12,j} = L; % Luminance
end







   