function p = HSIregionPDF(obj)
% IM_REGIONPDF is a imObject plugin for computing EPDFS of image regions

% DEFINE THE MENUS
p = imPlugin(obj,mfilename);
p.plugintype = {'HSI'};

p.MenuOrder = 2;
p.MenuParent = 'Hyperspectral';
Callback = @(hObject,eventdata) callback_compare(hObject,eventdata,obj,p);
p.MenuOptions = {'Label','Calculate Region PDF(s)'};

p.MenuSubmenu{1} = {'Label','Work','callback',Callback};
p.MenuSubmenu{2} = {'Label','White','callback',Callback};

% DEFINE THE PLUGIN PREFERENCES
p.Pref(1).Value = '280,750; 750,3000';
p.Pref(1).Label = 'Wavelength Bands';

p.Pref(2).Value = 'VIS,NIR';
p.Pref(2).Label = 'Wavelength Labels';

p.Pref(3).Value = 4;
p.Pref(3).Label = 'EPDF Kernel';
p.Pref(3).Options = {'Normal', 'Box', 'Triangle','Epanechnikov'};

p.Pref(4).Value = '30';
p.Pref(4).Label = 'Number of Points';

p.Pref(5).Value = '5';
p.Pref(5).Label = 'Figure Width (in)';

p.Pref(6).Value = '3';
p.Pref(6).Label = 'Figure Height (in)';

%--------------------------------------------------------------------------
function callback_compare(hObject,~,~,p)
% CALLBACK_COMPARE

% 1 - GATHER THE REGIONS
    % Gather current object and desired type
    imObj = guidata(hObject);
    type = lower(get(hObject,'Label'));
    
    % Gather the desired regions, across images if desired
    R = gatherRegions(type,imObj);
    if isempty(R); 
        mes = ['At least one "',type,'" region must exist!'];
        warndlg(mes,'Warning!');
        return;
    elseif isnumeric(R) && isnan(R);
        return;
    end
        
% 2 - GATHER THE OPTIONS
    % General options
    opt.norm = imObj.workNorm;
    opt.rgb = false; % Turns off RGB option for VIS|NIR images
    opt.hsi = true; % Turns on HSI option
    
    % User options regarding the calculation of the HSI distributions
    opt.wavelength = eval(['[',p.Pref(1).Value,']']);
    C = textscan(p.Pref(2).Value,'%s','delimiter',',');
    opt.wavelengthlabel = C{1};
    
    % User options regarding computation of EPDF
    opt.kernel = p.Pref(3).Options{p.Pref(3).Value};
    opt.npoints = str2double(p.Pref(4).Value);
    opt.width = str2double(p.Pref(5).Value);
    opt.height = str2double(p.Pref(6).Value); 
     
% 3 - COMPARE THE REGIONS
    h = showDistribution(R,opt); 
    imObj.addChild(h);
    