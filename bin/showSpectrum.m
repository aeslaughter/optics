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
    opt.stddev = false; % Computes standard deviation of spectrum

    % 1.2 - Gather the user supplied settings
    opt = gatheruseroptions(opt,varargin{:});
    if opt.stddev; opt.ci = false; end % Turns off C.I. for standard dev

% 2 - COLLECT PARENT IMOBJECT HANDLES AND DISABLE THE IMAGES
    hwait = waitdlg('Performing spectrum calculations, please wait...');

% 3 - CYCLE THROUGH REGIONS AND GATHER THE SPECTRUM DATA
C = {};
for i = 1:length(R);
    % 3.1 - Reshape the data such that size = [npixels,wavelenghts]
    data = R(i).parent.getImage(R(i).type); 
    mask = R(i).getRegionMask;
    if isempty(mask); break; end
    data(~mask,:) = NaN;
    
    % 3.2 - Gather the imObject image handles
    imhandle(i) = R(i).parent.imhandle;

    % 3.3 - Determine the x,y data
    x = R(i).parent.info.wavelength;
        
    % 3.5 - Compute the standard devation, if desired 
    if opt.stddev;
       y = nanstd(data)';
    else
       y = nanmean(data)';
    end

    % 3.6 - Build output array of x,y data
    C = [C,x,y];
    
    % 3.7 - Build the legend
    [~,fn,ext] = fileparts(R(i).parent.filename);
    a.legend{i} = [fn,ext,':',R(i).type,':',R(i).label];
    
    % 3.8 - Compute the perctile data if desired
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
    
    % 4.2 - Turn-off imObject visibility
    set(imhandle,'HandleVisibility','off');
    
    % 4.3 - Graph the data
    [h,ax] = XYscatter(C,'advanced',a);
         set(h,'NextPlot','add');

% 5 - GRAPH THE CONFIDENCE INTERVALS (if desired)
    % 5.1 - Produce the confidence intervals
    if opt.ci; plotCI(x,CI,ax,opt.citype); end
  
    % 5.2 - Turn-on handle visibility of imObjects
    set(imhandle,'HandleVisibility','on');
    
% 6 - CLOSE THE WAIT DIALOG
    delete(hwait);
    
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
                'EdgeColor','none','FaceAlpha',0.25,'HitTest','off');
            set(hline(i),'UserData',user); % Update line user data
            ymax = max(Y); % Max of CIs
            ymin = min(Y); % Min of CIs
        end
end

% Adjust the vertical axis
ylim(ax,[min(ymin),max(ymax)]);
