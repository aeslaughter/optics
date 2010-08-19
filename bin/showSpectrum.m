function h = showSpectrum(R,varargin)
%__________________________________________________________________________
% SYNTAX:
%   h = showSpectrum(R);
%   h = showSpectrum(R,'PropertyName',<PropertyValue>);
%
% DESCRIPTION:
%
%__________________________________________________________________________

% 1 - DEFINE THE USER OPTIONS (note, the defaults prescribed here does not
% get used by im_distributions.m; they are included for completeness as
% this function may be used by itself)

    % 1.1 - Defnine the default values
    opt.width = 5;
    opt.height = 3;
    opt.ci = true;
    opt.citype = 'shaded';
    opt.civalue = 5;

    % 1.2 - Gather the user supplied settings
    opt = gatheruseroptions(opt,varargin{:});

% 2 - COLLECT PARENT IMOBJECT HANDLES AND DISABLE THE IMAGES
    R(1).parent.progress;

% 3 - CYCLE THROUGH REGIONS AND GATHER THE SPECTRUM DATA
C = {};
for i = 1:length(R);
    % 3.1 - Reshape the data such that size = [npixels,wavelenghts]
    data = R(i).parent.getImage;
    
    % Build a cell array of the x,y data
    y = nanmean(data)'; 
    x = R(i).parent.info.wavelength;
    C = [C,x,y];
    
    % Build the legend
    a.legend{i} = [R(i).parent.filename,':',R(i).type,':',R(i).label];
    
    % Compute the perctile data if desired
    if opt.ci;
       CI{i} = prctile(data,[opt.civalue, 100-opt.civalue])';
    end  
end

% 4 - GRAPH THE MEAN SPECTRUMS
    % 4.1 - Define the properties
    a.ylabel = 'Brightness';
    a.xlabel = 'Wavelength (nm)';
    a.fontname = 'Times';
    a.name = 'Region Spectrum(s)';
    a.size = [opt.width, opt.height];
    
    % 4.2 - Graph the data
    [h,ax] = XYscatter(C,'advanced',a);
         set(h,'NextPlot','add');

% 5 - GRAPH THE CONFIDENCE INTERVALS (if desired)
if opt.ci;
    plotCI(x,CI,ax,opt.citype);
end

% 6 - RE-ENABLE THE IMOBJECTS
    R(1).parent.progress;

%--------------------------------------------------------------------------
function plotCI(x,CI,ax,type)
% PLOTCI graphs the confidence level intervals on the figure

% Define the handles for the current lines
hline = findobj(ax,'Type','Line');

% Plot the CI data
switch type
    case 'lines'; % Shows dashed lines for CI
        for i = 1:length(hline);
            user = get(hline(i),'UserData'); % User data of current line
            user.handles = plot(x,CI{i},'--',... % Plots the C.I.
                'Color',get(hline(i),'Color'));
            set(hline(i),'UserData',user); % Updata user data
            ymax(i) = max(max(CI{i})); % Max of current CI
            ymin(i) = min(min(CI{i})); % Min of current CI
        end
        
    case 'shaded'; % Shows a shaded region for the CI      
        for i = 1:length(hline);
            Y = [CI{i}(:,1); CI{i}(end,2);flipud(CI{i}(:,2))]; % X-vertices
            X = [x; x(end); flipud(x)]; % Y-vertices
            user = get(hline(i),'UserData'); % User data of current line
            user.patch = patch(X,Y,get(hline(i),'Color'),... %Plot vertices
                'EdgeColor','none','FaceAlpha',0.25);
            set(hline(i),'UserData',user); % Update line user data
            ymax = max(Y); % Max of CIs
            ymin = min(Y); % Min of CIs
        end
end

% Adjust the vertical axis
ylim(ax,[min(ymin),max(ymax)]);
