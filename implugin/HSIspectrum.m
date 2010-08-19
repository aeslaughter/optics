function p = HSIspectrum(obj)
% IM_REGIONPDF is a imObject plugin for computing EPDFS of image regions

% 1 - DEFINE THE PLUGIN AND CALLBACK
p = imPlugin(obj,mfilename);
p.plugintype = {'HSI'};
Callback = @(hObject,eventdata) callback_spec(hObject,eventdata,p);

% 2 - DEFINE THE MENU ITEM
p.MenuOrder = 1;
p.MenuParent = 'Hyperspectral';
p.MenuOptions = {'Label','Region Spectrum'};

% 3 - DEFINE THE SUBMENUS
p.MenuSubmenu{1} = {'Label','White','callback',Callback};
p.MenuSubmenu{2} = {'Label','Work','callback',Callback};


% 4 - DEFINE THE USER PREFERERNCES
p.Pref(1).Value = true;
p.Pref(1).Label = 'Confidence Interval (C.I.)';

p.Pref(2).Value = 1;
p.Pref(2).Label = 'C.I. Type';
p.Pref(2).Options = {'Shaded','Lines'};

p.Pref(3).Value = '5';
p.Pref(3).Label = 'C.I. Alpha';

p.Pref(4).Value = '5';
p.Pref(4).Label = 'Figure Width (in)';

p.Pref(5).Value = '3';
p.Pref(5).Label = 'Figure Height (in)';

%--------------------------------------------------------------------------
function callback_spec(hObject,~,p)

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
    opt.ci = p.Pref(1).Value;
    opt.citype = lower(p.Pref(2).Options{p.Pref(2).Value});
    opt.civalue = str2double(p.Pref(3).Value);
    opt.width = str2double(p.Pref(4).Value);
    opt.height = str2double(p.Pref(5).Value); 
    
% 3 - COMPARE THE REGIONS
    h = showSpectrum(R,opt); 
    imObj.addChild(h);
    





