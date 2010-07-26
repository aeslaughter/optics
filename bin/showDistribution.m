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

% 2 - DISABLE THE FIGURE
    H = findobj('enable','on');
    set(H,'enable','off');
    drawnow;
    
% 3 - SEPERATE THE REGIONS AND COMPUTE THE EPDF FUNCTIONS    
    N = length(R);
    f = zeros(opt.npoints,N); 
    xi = f; % Initilize the output arrays
    k = 1; % Initlize counter for RGB option
    rgb = {'Blue','Green','Red'};

    for i = 1:N;
        r = R(i).getRegion(opt.norm); % Get image region information (see imregion)   
        if opt.rgb;
            for j = 1:size(r,3);
                data = reshape(r(:,:,j),1,numel(r(:,:,j)));
                a.legend{k} = [R(i).parent.filename,':',R(i).type,':',R(i).label,'(',rgb{j},')'];
                  [f(:,k),xi(:,k)] = ksdensity(data,'kernel',opt.kernel,...
                    'npoints',opt.npoints);
                k = k + 1;
            end
        else
            data = reshape(r,1,numel(r));
            a.legend{i} = [R(i).parent.filename,':',R(i).type,':',R(i).label];
            [f(:,i),xi(:,i)] = ksdensity(data,'kernel',opt.kernel,...
                'npoints',opt.npoints);
       end
    end

% 4 - BUILD THE GRAPH
    if opt.rgb; a.colororder = [1 0 0;0 1 0;0 0 1]; end

    a.ylabel = 'Prob. Density';
    a.xlabel = 'Brightness';
    a.linewidth = 2;
    a.interpreter = 'tex';
    a.tight = 'on';
    a.fontname = 'times'; a.fontsize = 9;
    a.location = 'best';
    a.size = [opt.width,opt.height];


    h = XYscatter(xi,f,'advanced',a);  
    
    
% 5 - ENABLE THE FIGURE
    set(H,'enable','on');
        