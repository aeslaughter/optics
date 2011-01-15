function p = convertRGB(obj)
% CONVERTRGB adds a menu toggle for converting between sRGB and CIE data
 
% Create the plugin and define the file association
p = imPlugin(obj,mfilename);
p.plugintype = {'VIS','NIR'};

% Define the main menu item
p.MenuOrder = 1;
p.MenuParent = 'Analysis';
Callback1 = @(hObject,eventdata) callback_check(hObject,eventdata,obj);
p.MenuOptions = {'Label','Convert image to...','Callback',Callback1};

% Define the submenu items
Callback2 = @(hObject,eventdata) callback_convert(hObject,eventdata,obj);
p.MenuSubmenu{1} = {'Label','XYZ','Tag','xyz','callback',Callback2};
p.MenuSubmenu{2} = {'Label','sRGB','Tag','srgb','callback',Callback2};
p.MenuSubmenu{3} = {'Label','LAB','Tag','lab','callback',Callback2};
p.MenuSubmenu{4} = {'Label','CMYK','Tag','cmyk','callback',Callback2};

%--------------------------------------------------------------------------
function callback_check(hObject,~,obj)
% CALLBACK_CHECK operates when the main menu is selected

% Enable and uncheck all submenu items
h = guihandles(hObject);
set([h.xyz,h.srgb,h.lab,h.cmyk],'checked','off','enable','on');

% Determine the current colorspace of the image 
cur = lower(obj.ColorSpace);
if isempty(cur); 
    set(hObject,'enable','off'); % Disable the current colorspace
else
    set(h.(cur),'Checked','on','enable','off'); % No colorspace defined
end

%--------------------------------------------------------------------------
function callback_convert(hObject,~,obj)
% CALLBACK_CONVERT toggles the sRGB conversion (also in imObject pref.)

type = get(hObject,'Tag');
obj.convertColorSpace(type);