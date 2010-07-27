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
    opt.norm = true;
    opt.rgb = false;
    opt.kernel = 'epanechnikov';
    opt.npoints = 50;
    opt.width = 5;
    opt.height = 3;
    opt = gatheruseroptions(opt,varargin{:});

% 2 - DEFINE THE IMOBJECT HANDLE AND DISABLE THE FIGURE(s)
    imObj = R.parent;
    imObj.progress;
    
% 3 - SEPERATE THE REGIONS AND COMPUTE THE EPDF FUNCTIONS    
    % 3.1 - Prepare for computing regions
    N = length(R);              % The number of regions
    f = zeros(opt.npoints,N);   % Initilize the output (f = prob. dens.)
    xi = f;                     % Initilize the output (xi = refl.)
    k = 1;                      % Initlize counter for RGB option
    rgb = {'Red','Green','Blue'}; % Colors for Red/Green/Blue option

    % 3.2 - Compute the region distributions
    for i = 1:N;
        r = R(i).image; % The current image region
        
        % 3.2.1 - Compute the RGB distributions
        if opt.rgb;
            for j = 1:size(r,3);
                data = r(:,:,j);
                X = reshape(data,numel(data),1);
                a.legend{k} = [R(i).parent.filename,':',R(i).type,':',...
                    R(i).label,'(',rgb{j},')'];
                  [f(:,k),xi(:,k)] = ksdensity(X,'kernel',opt.kernel,...
                    'npoints',opt.npoints);
                k = k + 1;
            end
            
        % 3.2.2 - Compute the mean distributions
        else
            data = mean(r,3); 
            X = reshape(data,numel(data),1);
            a.legend{i} = [R(i).parent.filename,':',R(i).type,':',...
                R(i).label];
            [f(:,i),xi(:,i)] = ksdensity(X,'kernel',opt.kernel,...
                'npoints',opt.npoints);
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
    a.location = 'best';
    a.size = [opt.width,opt.height];

    % 4.3 - Produce the graph
    h = XYscatter(xi,f,'advanced',a);  
    
% 5 - ENABLE THE FIGURE
    imObj.progress;
        