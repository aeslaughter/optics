function p = im_regionPDF(obj)
% IM_REGIONPDF is a imObject plugin for computing EPDFS of image regions

% DEFINE THE MENUS
p = imPlugin(obj,mfilename);
p.plugintype = {'VIS','NIR'};

p.MenuOrder = 1;
p.MenuParent = 'Analysis';
Callback = @(hObject,eventdata) callback_compare(hObject,eventdata,obj,p);
p.MenuOptions = {'Label','Calculate Region PDF(s)'};

p.MenuSubmenu{1} = {'Label','White','callback',Callback};
p.MenuSubmenu{2} = {'Label','Work','callback',Callback};


% DEFINE THE PLUGIN PREFERENCES
p.Pref(1).Value = false;
p.Pref(1).Label = 'Seperate RGB Colors';

p.Pref(2).Value = 4;
p.Pref(2).Label = 'EPDF Kernel';
p.Pref(2).Options = {'Normal', 'Box', 'Triangle','Epanechnikov'};

p.Pref(3).Value = '30';
p.Pref(3).Label = 'Number of Points';

p.Pref(4).Value = '5';
p.Pref(4).Label = 'Figure Width (in)';

p.Pref(5).Value = '3';
p.Pref(5).Label = 'Figure Height (in)';

%--------------------------------------------------------------------------
function callback_compare(hObject,~,obj,p)
% CALLBACK_COMPARE

% 1 - GATHER THE REGIONS
    imObj = guidata(hObject);
    type = lower(get(hObject,'Label'));
    R = obj.(type);
    if isempty(R); 
        mes = ['At least one "',type,'" region must exist!'];
        warndlg(mes,'Warning!');
        return;
    end
        
% 2 - GATHER THE OPTIONS
    % General options
    opt.norm = imObj.workNorm;
    opt.rgb = p.Pref(1).Value;
    
    % User options via preferences
    opt.kernel = p.Pref(2).Options{p.Pref(2).Value};
    opt.npoints = str2double(p.Pref(3).Value);
    opt.width = str2double(p.Pref(4).Value);
    opt.height = str2double(p.Pref(5).Value); 
    
% 3 - COMPARE THE REGIONS
    h = showDistribution(R,opt); 
    imObj.addChild(h);
    