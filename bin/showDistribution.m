function h = showDistribution(R,varargin)
%__________________________________________________________________________
% SYNTAX:
%   h = showDistribution(R);
%   h = showDistribution(R,'PropertyName',<PropertyValue>);
%
% DESCRIPTION:
%
%__________________________________________________________________________

% 1 - DEFINE THE USER OPTIONS (note, the defaults prescribed here does not
% get used by im_distributions.m; they are included for completeness as
% this function may be used by itself)

    % 1.1 - Defnine the default values
    opt.rgb = false;
    opt.kernel = 'epanechnikov';
    opt.npoints = 50;
    opt.bandwidth = NaN; %auto
    opt.width = 5;
    opt.height = 3;
    opt.hsi = false;
    opt.wavelength = [380,750; 750,3000];
    opt.wavelengthlabel = {'VIS','NIR'};
    
    % 1.2 - Gather the user supplied settings
    opt = gatheruseroptions(opt,varargin{:});
    
    % 1.3 - Adjust for NaN bandwidth
    if isnan(opt.bandwidth); opt.bandwidth = []; end

% 2 - DEFINE THE IMOBJECT HANDLE AND DISABLE THE FIGURE(s)
    hwait = waitdlg('Performing PDF calculations, please wait...');
    
% 3 - SEPERATE THE REGIONS AND COMPUTE THE EPDF FUNCTIONS    
    % 3.1 - Prepare for computing regions
    N = length(R);              % The number of regions
    f = zeros(opt.npoints,N);   % Initilize the output (f = prob. dens.)
    xi = f;                     % Initilize the output (xi = refl.)
    k = 1;                      % Initilize counter for RGB option
    a.legend = {};              % Initilize the legend (needed for HSI)
    rgb = {'Red','Green','Blue'}; % Colors for Red/Green/Blue option

    % 3.2 - Compute the region distributions
    for i = 1:N;
        data = R(i).parent.getImage(R(i).type); 
        mask = R(i).getRegionMask;

        % 3.2.1 - Compute the RGB distributions
        if opt.rgb;
            for j = 1:size(data,2);
                [~,fname,ext] = fileparts(R(i).parent.filename);
                a.legend{k} = [fname,ext,':',R(i).type,':',...
                    R(i).label,'(',rgb{j},')'];
                X = data(mask,j);
                [f(:,k),xi(:,k)] = ksdensity(double(X),...
                      'kernel',opt.kernel,'npoints',opt.npoints);
                k = k + 1;
            end
            
        % 3.2.2 - Compute Hyperspectral distributions based on wavelenghts
        elseif opt.hsi;
            opt.wavelengthlabel = HSIlabels(opt);
            [f,xi,k,a] = computeHSI(R(i),opt,a,f,xi,k);

        % 3.2.3 - Compute the mean distributions
        else
            data = mean(data,2);
            data = data(mask);
            [~,fname,ext] = fileparts(R(i).parent.filename);
            a.legend{i} = [fname,ext,':',R(i).type,':',...
                R(i).label];
             [f(:,i),xi(:,i)] = ksdensity(data,'kernel',opt.kernel,...
                'npoints',opt.npoints,'width',opt.bandwidth);
       end
    end

% 4 - BUILD THE GRAPH
    % 4.1 - RGB option specific properties
    if opt.rgb; 
        a.colororder = [1 0 0; 0 1 0; 0 0 1]; 
        a.linestyleorder = '-|--|:|-.';
    end

    % 4.2 - Define the general properties
    a.ylabel = 'Prob. Density';
    a.xlabel = 'Brightness';
    a.linewidth = 2;
    a.interpreter = 'none';
    a.tight = 'on';
    a.fontname = 'times'; a.fontsize = 9;
%     a.location = 'best';
    a.size = [opt.width,opt.height];

    % 4.3 - Produce the graph
    h = XYscatter(xi,f,'advanced',a);  
    
% 5 - CLOSE THE WAIT DIALOG
    delete(hwait);
       
%--------------------------------------------------------------------------
function L = HSIlabels(opt)
% HSILABELS gets/builds labels for computation of HSI distributions

% Case when the user defines the label
W = opt.wavelength;
if length(opt.wavelengthlabel) == size(W,1);
    L = opt.wavelengthlabel;
    return;
end
    
% Case when the labels are undefined or incorrectly defined
for i = 1:size(W,1);
    L{i} = [num2str(W(i,1)),'-',num2str(W(i,2))];
end

%--------------------------------------------------------------------------
function [f,xi,k,a] = computeHSI(R,opt,a,f,xi,k)
% COMPUTEHSI calcules the PDF between the desired wavelenghts

% Gather the image wavelenght information
    data = R.parent.getImage(R.type); % The image
    mask = R.getRegionMask; % The selected region
    w = R.parent.info.wavelength; % Wavelenghts in the image
    W = opt.wavelength; % Wavelength bands desired
    L = opt.wavelengthlabel; % Wavelength labels

% Loop throuth    
for i = 1:size(W,2);
    % Seperate the desired data
    idx = w >= W(i,1) & w < W(i,2);
    X = mean(data(mask,idx),2);
    
    % Append the legend
    [~,fn,ext] = fileparts(R.parent.filename);
    a.legend{k} = [fn,ext,':',R.type,':',...
                    R.label,'(',L{i},')'];
    
    % Append the PDF data            
    [f(:,k),xi(:,k)] = ksdensity(X,'kernel',opt.kernel,...
        'npoints',opt.npoints);
    k = k + 1; % Increment the counter
end
         