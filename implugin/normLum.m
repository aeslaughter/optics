function p = normLum(obj)
% NORMLUM normalizes the image according to the avg. image luminance
 
% Create the plugin and define the file association
p = imPlugin(obj,mfilename);
p.plugintype = {'VIS','NIR'};

% Define the main menu item
p.MenuOrder = 1;
p.MenuParent = 'Analysis';
Callback1 = @(hObject,eventdata) callback_lum(hObject,eventdata,obj);
p.MenuOptions = {'Label','Normalize with luminance','Callback',Callback1};


%--------------------------------------------------------------------------
function callback_lum(hObject,~,obj)
% CALLBACK_LUM operates when the main menu is selected
% (http://en.wikipedia.org/wiki/Exposure_value)

try
    D = obj.info.DigitalCamera;
    N = D.FNumber; % F-stop number
    t = D.ExposureTime; % Exposure time (sec)
    S = D.ISOSpeedRatings; % ISO Setting
    K = 12.5; % Meter calibration constant
    L = N^2*K/(S*t) %  Computes the average luminance

    %obj.image = obj.image/L;
catch
    mes = ['Failed to extract the necessary camera information, ',...
        'the image was not normalized for the average luminance.'];
    warndlg(mes,'Missing Data');
    return;
end
