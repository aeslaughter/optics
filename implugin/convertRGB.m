function p = convertRGB(obj)
% CONVERTRGB adds a menu toggle for converting between sRGB and CIE data
   
% DEFINE THE MENUS
p = imPlugin(obj,mfilename);
p.plugintype = {'VIS','NIR'};

p.MenuOrder = 1;
p.MenuParent = 'Analysis';
Callback = @(hObject,eventdata) callback_convert(hObject,eventdata,obj);
p.MenuOptions = {'Label','Convert sRGB to CIE','callback',Callback};

% DEFINE THE PREFERENCES
p.Pref(1).Value = true;
p.Pref(1).Label = 'Prompt user to save new image (C.I.)';

%--------------------------------------------------------------------------
function callback_convert(~,~,obj)
% CALLBACK_CONVERT toggles the sRGB conversion (also in imObject pref.)

% Prompt user for a new filename
[p,f,e] = fileparts(obj.filename);
filename = [p,filesep,f,'(CIE)',e];

[F,P] = uiputfile(e,'Save new image as...',filename);
if isnumeric(F); return; end;
newfile = [P,filesep,F]

% Convert the Colorspace
if strcmpi(obj.ColorSpace,'sRGB');
    I = sRGB(obj.image,'sRGB');
    ColorSpace = 'CIE';
else
    warndlg(['Invalid settings, the conversion',...
        ' is not possible for this image.'],'Invalid format');
    return;
end

% Create and open the new file
imwrite(I,newfile);
obj = imObject(newfile);
obj.ColorSpace = ColorSpace;
    
