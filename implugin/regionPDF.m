function p = regionPDF(obj)
% IM_REGIONPDF is a imObject plugin for computing EPDFS of image regions

% DEFINE THE MENUS
p = imPlugin(obj,mfilename);
p.plugintype = {'VIS','NIR'};

p.MenuOrder = 3;
p.MenuParent = 'Analysis';
Callback = @(hObject,eventdata) callback_compare(hObject,eventdata,obj,p);
p.MenuOptions = {'Label','Calculate Region(s) Distribution'};

p.MenuSubmenu{2} = {'Label','White','callback',Callback};
p.MenuSubmenu{1} = {'Label','Work','callback',Callback};


% DEFINE THE PLUGIN PREFERENCES
p.Pref(1).Value = false;
p.Pref(1).Label = 'Seperate RGB Colors or XYZ components';

p.Pref(2).Value = 4;
p.Pref(2).Label = 'Output Type';
p.Pref(2).Options = {'EPDF','ECDF','Histogram','Fit(PDF)','Fit(CDF)'};

p.Pref(3).Value = 1;
p.Pref(3).Label = 'PDF/CDF Fit Type';
p.Pref(3).Options = {'Normal','Wiebull'};

p.Pref(4).Value = 4;
p.Pref(4).Label = 'EPDF: Kernel';
p.Pref(4).Options = {'Normal', 'Box', 'Triangle','Epanechnikov'};

p.Pref(5).Value = '30';
p.Pref(5).Label = 'EPDF: Number of Points';

p.Pref(6).Value = '';
p.Pref(6).Label = 'EPDF: Bandwidth (empty = auto)';

p.Pref(7).Value = '30';
p.Pref(7).Label = 'Histogram: No. of Bins';

p.Pref(8).Value = '5';
p.Pref(8).Label = 'Figure Width (in)';

p.Pref(9).Value = '3';
p.Pref(9).Label = 'Figure Height (in)';

%--------------------------------------------------------------------------
function callback_compare(hObject,~,obj,p)
% CALLBACK_COMPARE

% 1 - GATHER THE REGIONS
    imObj = guidata(hObject);
    type = lower(get(hObject,'Label'));
    R = gatherRegions(type,obj);
    if isempty(R); 
        mes = ['At least one "',type,'" region must exist!'];
        warndlg(mes,'Warning!');
        return;
    elseif isnumeric(R) && isnan(R);
        return;
    end
        
% 2 - GATHER THE OPTIONS
    % General options
    opt.rgb = p.Pref(1).Value;
    
    % User options via preferences
    opt.output = p.Pref(2).Options{p.Pref(2).Value};
    opt.fittype = p.Pref(3).Options{p.Pref(3).Value};
    opt.kernel = p.Pref(4).Options{p.Pref(4).Value};
    opt.npoints = str2double(p.Pref(5).Value);
    opt.bandwidth = str2double(p.Pref(6).Value); 
    opt.nbin = str2double(p.Pref(7).Value);
    opt.width = str2double(p.Pref(8).Value);
    opt.height = str2double(p.Pref(9).Value); 
    opt.colorspace = obj.ColorSpace;
    
% 3 - COMPARE THE REGIONS
    h = showDistribution(R,opt); 
    imObj.addChild(h);
    