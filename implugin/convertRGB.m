function p = convertRGB(obj)
% CONVERTRGB adds a menu toggle for converting between sRGB and CIE data

% DETERMINE THE STATUS
check = 'off';
if obj.sRGB; check = 'on'; end
    
% DEFINE THE MENUS
p = imPlugin(obj,mfilename);
p.plugintype = {'VIS','NIR'};

p.MenuOrder = 1;
p.MenuParent = 'Analysis';
Callback = @(hObject,eventdata) callback_convert(hObject,eventdata,obj);
p.MenuOptions = {'Label','Convert sRGB to CIE','Checked',check,...
    'callback',Callback};

%--------------------------------------------------------------------------
function callback_convert(hObject,~,obj)
% CALLBACK_CONVERT toggles the sRGB conversion (also in imObject pref.)

if obj.sRGB; 
    obj.sRGB = false; 
    obj.sRGBconvert;
    set(hObject,'Checked','off');
else
    obj.sRGB = true;
    obj.sRGBconvert;
    set(hObject,'Checked','on');
end
