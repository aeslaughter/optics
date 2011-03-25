function p = fractal(obj)
% FRACTAL is a imObject plugin for computing the fractal dimension

% DEFINE THE MENUS
p = imPlugin(obj,mfilename);
p.plugintype = {'VIS','NIR'};

p.MenuOrder = 5;
p.MenuParent = 'Analysis';
Callback = @(hObject,eventdata) callback_fractal(hObject,eventdata,obj,p);
p.MenuOptions = {'Label','Calculate Fractal Dimension'};

p.MenuSubmenu{2} = {'Label','White','callback',Callback};
p.MenuSubmenu{1} = {'Label','Work','callback',Callback};

% DEFINE THE PLUGIN PREFERENCES
p.Pref(1).Value = false;
p.Pref(1).Label = 'Seperate RGB Colors or XYZ components';

p.Pref(2).Value = false;
p.Pref(2).Label = 'Graph Box Size vs. Count';

p.Pref(3).Value = true;
p.Pref(3).Label = 'Graph the Slope';

p.Pref(4).Value = false;
p.Pref(4).Label = 'Compute Percent Differences';

%--------------------------------------------------------------------------
function callback_fractal(hObject,~,obj,p)
% CALLBACK_FRACTAL compares the two regions of interest

% 1 - GATHER THE OPTIONS
    addpath('bin/boxcount');
    rgb = p.Pref(1).Value;
    G1 = p.Pref(2).Value;
    G2 = p.Pref(3).Value;
    PD = p.Pref(4).Value;

% 2 - GATHER THE REGIONS
    % 2.1 - Collect the data
    imObj = guidata(hObject);
    type = lower(get(hObject,'Label'));
    R = gatherRegions(type,obj);
    
    % 2.2 - Return if more than two regions are selected for percent diff.
    if PD && length(R) ~= 2;
        mes =  ['Exactly two "',type,'" regions must be selected, if ',...
            'the percent difference option is selected.'];
        warndlg(mes,'Warning!');
        return;
    end

% 3 - PERFORM FRACTAL ANALYSIS
    k = 1; % Data counter

    % 3.1 - Loop through each of the regions
    for i = 1:length(R);      
        ns = imObj.imsize;
        mask = reshape(R(i).getRegionMask,ns(1:2));
        I = getImage(R(i).parent);
        I = reshape(I,imObj.imsize);
        if ~rgb; I = mean(I,3); end
        
        [~,fn,ext] = fileparts(R(i).parent.filename);
        fname = [fn,ext];
        name = regexprep([R(i).type,'-',R(i).label],' ','');
    
    % 3.2 - Perform fractal calculations
        N = size(I,3);
        for j = 1:N;
            x = I(:,:,j);
            x(~mask) = NaN;
            m = nanmean(nanmean(x));
            x(~mask) = 0;
            x(x < m) = 0;
            x(x >= m) = 1;
            [n(:,k),r(:,k),s(:,k)] = boxcount(x);
            
            if N == 1;
                a.legend{k} = [fname,' ',name]; 
            else
                a.legend{k} = [fname,' ',name,' (',num2str(j),')']; 
            end
            k = k + 1;
        end
    end
    
% 4 - COMPUTE PERCENT DIFF. IF DESIRED    
if PD
    nd = abs(2*(n(:,1:end/2) - n(:,end/2+1:end)) ./ ...
            (n(:,1:end/2) + n(:,end/2+1:end)))*100;  
    sd = abs(2*(s(:,1:end/2) - s(:,end/2+1:end)) ./ ...
            (s(:,1:end/2) + s(:,end/2+1:end)))*100;
    a.y2label = 'Percent Difference';
    a.legend2 = {'Percent Diff.'};
end

% 5 - PRODUCE GRAPHS
    % 5.1 - Define common properties
    a.interpreter = 'latex';
    a.xlabel = 'r (box size)'; 
    a.ylabel ='n(r), number of boxes';
    a.tight = 'off';
    a.linewdith = 2;
    
    % 5.2 - Box size vs. Count
    if G1
        if PD; a.secondary = {r(:,1),nd}; end
        [h,ax] = XYscatter(r,n,'advanced',a);
        set(ax(1),'xscale','log','yscale','log');
        if PD;
            set(ax(2),'xscale','log');  
            linkaxes(ax,'x');
        end
        imObj.addChild(h);
    end
    
    % 5.3 - Slope vs. Count
    if G2
        if PD; a.secondary = {r(:,1),sd}; end
        a.ylabel = '$-\frac{dn}{dr}$';
        [h,ax] = XYscatter(r,s,'advanced',a);
        set(ax,'xscale','log');
        imObj.addChild(h);
    end
    