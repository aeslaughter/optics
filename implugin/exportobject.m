function p = exportobject(obj)
% EXPORTOBJECT allows user to export the imObject handle

% DEFINE THE MENUS
p = imPlugin(obj,mfilename);
p.plugintype = {};

p.MenuOrder = 7;
p.MenuParent = 'Analysis';
Callback = @(hObject,eventdata) callback_export(hObject,eventdata,obj);
p.MenuOptions = {'Label','Export imObject','Callback',Callback};

%--------------------------------------------------------------------------
function callback_export(hObject,~,obj)
% CALLBACK_EXPORT

% Gather the filename or imObject name
name = obj.imObjectName;
if isempty(name);
    name = obj.filename;
end

% Prompt the user for data export
export2wsdlg({name},{'obj'},{obj})

