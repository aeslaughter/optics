function p = HSIstddev(obj)
% IM_REGIONPDF is a imObject plugin for computing EPDFS of image regions

% 1 - DEFINE THE PLUGIN AND CALLBACK
p = imPlugin(obj,mfilename);
p.plugintype = {'HSI'};
Callback = @(hObject,eventdata) callback_stddev(hObject,eventdata,p);

% 2 - DEFINE THE MENU ITEM
p.MenuOrder = 1;
p.MenuParent = 'Hyperspectral';
p.MenuOptions = {'Label','Region Std. Dev. Spectrum(s)'};

% 3 - DEFINE THE SUBMENUS
p.MenuSubmenu{2} = {'Label','White','callback',Callback};
p.MenuSubmenu{1} = {'Label','Work','callback',Callback};

% 4 - DEFINE THE USER PREFERERNCES
p.Pref(1).Value = '5';
p.Pref(1).Label = 'Figure Width (in)';

p.Pref(2).Value = '3';
p.Pref(2).Label = 'Figure Height (in)';

%--------------------------------------------------------------------------
function callback_stddev(hObject,~,p)
% CALLBACK_STDDEV

% 1 - GATHER THE REGIONS
    imObj = guidata(hObject);
    type = lower(get(hObject,'Label'));
    R = gatherRegions(type,imObj);
    if isempty(R); 
        mes = ['At least one "',type,'" region must exist!'];
        warndlg(mes,'Warning!');
        return;
    elseif isnumeric(R) && isnan(R)
        return;
    end
        
% 2 - GATHER THE OPTIONS
    opt.width = str2double(p.Pref(1).Value);
    opt.height = str2double(p.Pref(2).Value); 
    opt.stddev = true;
    
% 3 - COMPARE THE REGIONS
    h = showSpectrum(R,opt); 
    imObj.addChild(h);
