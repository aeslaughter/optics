function p = regionmean(obj)
% REGIONMEAN computs mean and confidence interval for selected regions

% DEFINE THE MENUS
p = imPlugin(obj,mfilename);
p.plugintype = {'VIS','NIR'};

p.MenuOrder = 4;
p.MenuParent = 'Analysis';
Callback = @(hObject,eventdata) callback_regmean(hObject,eventdata,obj,p);
p.MenuOptions = {'Label','Region Information'};

p.MenuSubmenu{2} = {'Label','White','callback',Callback,...
    'Tag','RegionMeanWhite'};
p.MenuSubmenu{1} = {'Label','Work','callback',Callback,...
    'Tag','RegionMeanWork'};

% DEFINE THE PLUGIN PREFERENCES
p.Pref(1).Value = true;
p.Pref(1).Label = 'Seperate Colorspace components';

p.Pref(2).Value = '1';
p.Pref(2).Label = 'Alpha Value (%)';

p.Pref(3).Value = '1000';
p.Pref(3).Label = 'Bootstrap Re-samplings';

%--------------------------------------------------------------------------
function callback_regmean(hObject,~,obj,p)
% CALLBACK_GOF compares the two regions of interest

% 1 - GATHER THE REGIONS
    type = lower(get(hObject,'Label'));
    R = gatherRegions(type,obj);
    if isnumeric(R) && isnan(R);
        return;
    end
            
% 2 - GATHER THE OPTIONS
    rgb = p.Pref(1).Value;
    alpha = str2double(p.Pref(2).Value);
    nboot = str2double(p.Pref(3).Value);   
    C = 'xyY';
    
% 3 - COMPUTE THE MEAN AND C.I.
    [M,CI,V] = computeRegionMeanCI(R,nboot,alpha,rgb);
    
% 3 - SEPERATE THE DESIRED DATA
    % 3.1 - Loop through each of the regions
    for i = 1:length(R)
        
        if ~isempty(R(i).parent.imObjectName);
            [~,fn,ext] = fileparts(R(i).parent.imObjectName);
        else
            [~,fn,ext] = fileparts(R(i).parent.filename);
        end
        disp([fn,ext,': ',R(i).type,'-',R(i).label]);

        N = size(M,2);
        for j = 1:N;             
            if N > 1;
                Mstr = [C(j),' Mean: ',num2str(M(i,j))];
            else
                Mstr = ['   Mean: ',num2str(M(i,j))];
            end
            
            disp(Mstr);
            disp(['   CI-1: ' num2str(CI(i,j,1))]);
            disp(['   CI-2: ' num2str(CI(i,j,2))]);
            disp(['    Var: ' num2str(V(i,j))]);
            disp(' ');
        end
    end





    












    
    
