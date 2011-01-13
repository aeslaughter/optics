function p = exportregion(obj)
% EXPORTREGION allows user to export the data from regions to workspace

% DEFINE THE MENUS
p = imPlugin(obj,mfilename);
p.plugintype = {};

p.MenuOrder = 1;
p.MenuParent = 'Analysis';
Callback = @(hObject,eventdata) callback_export(hObject,eventdata,obj);
p.MenuOptions = {'Label','Export Regions(s)'};

p.MenuSubmenu{1} = {'Label','Work','callback',Callback};
p.MenuSubmenu{2} = {'Label','White','callback',Callback};

% DEFINE THE PLUGIN PREFERENCES

%--------------------------------------------------------------------------
function callback_export(hObject,~,obj)
% CALLBACK_EXPORT

% Gather the regions
type = get(hObject,'Label');
R = gatherRegions(lower(type),obj,'all');

% Return if no regions are selected
if isempty(R); 
    msgbox('No regions exist!','No Regions','warn'); 
    return;
end

% Loop through the regions and seperate out data and create labels for
% export
for r = 1:length(R);
    % Gather image info
    mask = R(r).getRegionMask; 
    I = R(r).parent.getImage;
    [~,f,ext] = fileparts(R(r).parent.filename);
    
    % Build labels
    name{r} = [f,ext,' ',type,' #',strtrim(R(r).label)];
    varname{r} = genvarname([f,type,R(r).label]);
    checklabels{r} = ['Store region ',name{r},' to variable named:'];
    
    % Gather data
    for i = 1:size(I,2);
        data{r}(:,i) = I(mask,i);
    end
end

% Prompt the user for data export
export2wsdlg(checklabels,varname,data);







