function p = im_distributions(obj)

p = imPlugin(obj,mfilename);
p.plugintype = 'VIS|NIR';

p.MenuOrder = 1;
p.MenuParent = 'Analysis';
Callback = @(hObject,eventdata) callback_compare(hObject,eventdata,obj,p);
p.MenuOptions = {'Label','Region Distribution(s)'};

p.MenuSubmenu{1} = {'Label','White','callback',Callback};
p.MenuSubmenu{2} = {'Label','Work','callback',Callback};

p.Pref(1).Value = 4;
p.Pref(1).Label = 'EPDF Kernel';
p.Pref(1).Options = {'Normal', 'Box', 'Triangle','Epanechnikov'};

p.Pref(2).Value = '30';
p.Pref(2).Label = 'Number of Points';

p.Pref(3).Value = '5';
p.Pref(3).Label = 'Figure Width (in)';

p.Pref(4).Value = '3';
p.Pref(4).Label = 'Figure Height (in)';

%--------------------------------------------------------------------------
function callback_compare(hObject,~,obj,p)
% CALLBACK_COMPARE

% 1 - GATHER THE REGIONS
    type = lower(get(hObject,'Label'));
    R = obj.(type);
    if isempty(R); 
        mes = ['At least one "',type,'" region must exist!'];
        warndlg(mes,'Warning!');
        return;
    end
        
% 2 - GATHER THE OPTIONS
    opt.kernel = p.Pref(1).Options{p.Pref(1).Value};
    opt.npoints = str2double(p.Pref(2).Value);
    opt.width = str2double(p.Pref(3).Value);
    opt.height = str2double(p.Pref(4).Value); 
    
% 3 - COMPARE THE REGIONS
    h = showDistribution(R,opt); 
    p.addChild(h);
    
    