function prefGUI(imobj)
% PREFGUI opens a GUI for editting the plugin preferences of an imObject
%__________________________________________________________________________
% SYNTAX:
%   prefGUI(imobj);
%
% DESCRIPTION:
%   prefGUI(imobj) opens a GUI window for editting the Pref property
%       structure of the implugin objects associated with the imObject
%       with a handle imobj.
%__________________________________________________________________________

% Clear any existing plugin preference windows
    cur = findobj('Name','Plugin Preferences'); delete(cur);

% Open the GUI generated via MATLABs guide
    H = open('prefGUI.fig'); % Opens the GUI window
    guidata(H,imobj); % Stores the imObject handle
    set(H,'Name','Plugin Preferences'); % Set the window name
    h = guihandles(H);
    
% Apply general options
    set(get(h.general,'Children'),'Callback',@callback_general);
    initGeneral(H);
    
% Contruct a list of plugins to select from    
    buildpluginlist(H);

% Initilize by selecting the first preference option    
    h = guihandles(H);
    set(h.pluginlist,'Value',1);
    callback_select(h.pluginlist,[]);

% Create the File menu options    
    m = uimenu(H,'Label','File');
    uimenu(m,'Label','Save','Accelerator','s',...
        'callback',@callback_savepref);
    uimenu(m,'Label','Load','Accelerator','w',...
        'callback',@callback_savepref);
    uimenu(m,'Label','Close','separator','on','Accelerator','q',...
        'callback','close(gcf)');
    
%--------------------------------------------------------------------------
function initGeneral(H)
% INITGENERAL initilizes the general options

% Gather handle information from the GUI
h = guihandles(H);
imObj = guidata(H);
c = get(h.general,'Children');

% Loop through each general option and apply the imObject property
for i = 1:length(c);
    tag = get(c(i),'Tag');
    switch get(c(i),'Style'); 
        case {'checkbox','radiobutton'};
            set(c(i),'Value', imObj.(tag));
        case 'edit'
            set(c(i),'String',imObj.(tag)); 
        case {'popupmenu','listbox'};
            str = get(c(i),'String');
            val = strfind(str,imObj.(tag));
            set(c(i),'Value',val);
    end
    
    % Update the enable/disable
%     user = get(c(i),'UserData');
%     if ~isempty(imObj.type) && sum(strcmpi(imObj.type,user)) == 0;
%         set(c(i),'enable','off');
%     end
%     
end
    



%--------------------------------------------------------------------------
function output = callback_general(hObject,~)
% APPLYGENERALOPTIONS sets the imObjects general options

% Gather the imObject and current uicontrol tag
imObj = guidata(hObject);
tag = get(hObject,'Tag');

% Set the imObject property
switch get(hObject,'Style'); 
    case {'checkbox','radiobutton'};
        output = get(hObject,'Value');
    case 'edit'
        output = get(hObject,'String'); 
    case {'popupmenu','listbox'};
        val = get(hObject,'Value');
        str = get(hObject,'String');
        output = str{val};
end
imObj.(tag) = output;

%--------------------------------------------------------------------------
function buildpluginlist(H)
% BUILDPLUGINLIST creates the selectable list of plugins

% Gather information from GUI
    h = guihandles(H);
    imobj = guidata(H);
    p = imobj.plugins;

% Loop through each plugin and extract the name    
str = cell(size(p));
for i = 1:length(p);
    opt = lower(p(i).MenuOptions(1:2:end));
    idx = strmatch('label',opt)*2;
    str{i} = [p(i).MenuParent,' > ',...
        p(i).MenuOptions{idx}];
end

% Set the callback for the plugin list
set(h.pluginlist,'String',str,'callback',@callback_select);

%--------------------------------------------------------------------------
function callback_select(hObject,~)
% CALLBACK_SELECT operates when a plugin is selected from the list

% Gather information from the GUI
    idx = get(hObject,'Value');
    imobj = guidata(hObject);
    p = imobj.plugins(idx);

% Delete the existing panel    
    h = guihandles(hObject);
    if isfield(h,'OptionsPanel');
        delete(h.OptionsPanel);
    end

% Update the plugin text  
    txt = ['Plugin Options: ',p.plugin,'.m'];
    set(h.plugintext,'String',txt);
    
% Construct the panel to act as parent to the preference controls    
    pos = get(h.pluginlist,'Position');
    pos(1) = pos(1) + 0.475; pos(3) = pos(3) + 0.025;
    thepanel = uipanel(h.figure1,'Units','Normalized','Position',pos,...
        'Tag','OptionsPanel');

% Loop through each preference and create control  
    N = length(p.Pref);
    if N == 0;
        mes = 'No user defined options exist for this plugin.';
        uicontrol(thepanel,'Style','text','String',mes,...
            'Units','Normalized','position',[0.05,0.925,0.9,0.05],...
            'HorizontalAlignment','center');
        return;
    else
        loc = 0.925;
        for i = 1:N;
            pos = [0.05,loc,0.9,0.05]; % Defines position for the control
            insertcontrol(thepanel,pos,p,i); % Inserts the control
            loc = loc - 0.075; % Updates the position
        end
    end
% Determine the enable status for the save/load/clear default buttons
    if ~ispref('implugin',p.plugin);
        enable = 'off';
    else
        enable = 'on';
    end

% Define the save/load/clear default buttons
    btnpos = [0.025,0.025,0.30,0.05];
    uicontrol(thepanel,'Units','Normalized','Position',btnpos,...
        'String','Set as default(s)','FontSize',7,'Tag','set',...
        'callback',{@callback_default,p,'set'});

    btnpos(1) = 0.35;
    uicontrol(thepanel,'Units','Normalized','Position',btnpos,...
        'String','Load default(s)','FontSize',7,'Tag','get',...
        'callback',{@callback_default,p,'get'},'enable',enable);

    btnpos(1) = 0.675;
    uicontrol(thepanel,'Units','Normalized','Position',btnpos,...
        'String','Clear default(s)','FontSize',7,'Tag','clear',...
        'callback',{@callback_default,p,'clear'},'enable',enable);

% Disable the preferences if the plugin is a different type than imObject     
if ~isempty(imobj.type) && sum(strcmpi(imobj.type,p.plugintype)) == 0;
    child = findobj(thepanel,'-property','enable');
    set(child,'enable','off');
end

%--------------------------------------------------------------------------
function insertcontrol(h,pos,p,idx)
% INSERTCONTROL builds a control based on the plugin Pref properties

% Define the current preference to insert
    pref = p.Pref(idx);

% Build a toggle control
if islogical(pref.Value);
    ui = uicontrol(h,'Style','Radiobutton','String',pref.Label,...
        'Units','Normalized','position',pos,'Value',pref.Value);
 
% Build a textbox control with a label   
elseif ischar(pref.Value) && isempty(pref.Options);
    pos(3) = 0.3;
    ui = uicontrol(h,'Style','edit','String',pref.Value,...
        'Units','Normalized','position',pos,'BackgroundColor','w');
    
    pos(1) = 0.37; pos(2) = pos(2) - 0.0075; pos(3) = 0.6; 
    uicontrol(h,'Style','text','String',pref.Label,'Units','Normalized',...
        'position',pos,'HorizontalAlignment','left')
 
% Build a popup list control with a label 
elseif isnumeric(pref.Value) && iscell(pref.Options);
    pos(3) = 0.4;
    ui = uicontrol(h,'Style','popupmenu','Value',pref.Value,'String',...
        pref.Options,'Units','Normalized','position',pos,...
        'BackgroundColor','w');
    
    pos(1) = 0.47; pos(2) = pos(2) - 0.01; pos(3) = 0.5; 
    uicontrol(h,'Style','text','String',pref.Label,'Units','Normalized',...
        'position',pos,'HorizontalAlignment','left');
else
    mes = ['An error occured, the preferences for ',p.plugin,...
        ' are ill defined.'];
    errordlg(mes,'Plugin Error');
end

% Establish the callback for the preference control
    set(ui,'callback',{@callback_editpref,p,idx});

%--------------------------------------------------------------------------    
function callback_default(hObject,~,p,action)
% CALLBACK_DEFAULT operates when the user selects a save/load/clear button

% Gather the handles for the preference window
    h = guihandles(hObject);

% Perform the appropriate action (the default values are applied via the
% various methods of the plugin class itself)
switch action
    case 'get'; % Recalls the defaults
        p.getDefaultPref;
        callback_select(h.pluginlist,[]);
        
    case 'set'; % Stores the current settings as defaults
        p.setDefaultPref;
        set([h.get,h.clear],'enable','on');
        
    case 'clear'; % Removes any stored defaults
        p.clearDefaultPref;
        set([h.get,h.clear],'enable','off');
end
        
%--------------------------------------------------------------------------
function callback_editpref(hObject,~,p,item)
% CALLBACK_EDITPREF operates when the user selects a preference control

% Gather the new information from the uicontrol
switch get(hObject,'Style');
    case 'edit'; % Case for edittable text
        p.Pref(item).Value = get(hObject,'String');
        
    case 'radiobutton'; % Case for a logical toggle button
        p.Pref(item).Value = logical(get(hObject,'Value'));
        
    case 'popupmenu'; % Case for a popup list control 
        p.Pref(item).Value = get(hObject,'Value'); 
end

% Execute additional function
if ~isempty(p.Pref(item).Function);
   feval(p.Pref(item).Function);
end

%--------------------------------------------------------------------------
function callback_savepref(hObject,~)
% CALLBACK_SAVEPREF operates when the user selects save/load in file menu

% Gather information from the GUI
    imObj = guidata(hObject);
    h = guihandles(hObject);
    p = imObj.plugins;
    
% Establish the filename for the saved imObject preferences    
spec = {'*.impref','imObject Preferences (*.impref)'};

% Load/Save the preference
switch lower(get(hObject,'Label'));
    
    % Save the preferences
    case 'save';
        % Determine the file to save as
        filename = gatherfile('put','LastUsedPrefDir',spec);
        if isempty(filename); return; end

        % Gather the preferences
        for i = 1:length(p);
            name = genvarname(p(i).plugin);
            plug.(name) = struct(p(i).Pref);
        end

        c = get(h.general,'Children');
        for i = 1:length(c);
           name =  genvarname(get(c(i),'Tag'));
           gen.(name) = callback_general(c(i),[]);
        end
        
        % Store the preferences in a matlab workspace variable
        save(filename,'-mat','plug','gen');

    % Load preferences
    case 'load';
        % Determine the preferences to recall
        filename = gatherfile('get','LastUsedPrefDir',spec);
        if isempty(filename); return; end
        load(filename,'-mat'); % Loads two structures: "plug" and "gen"

        % Update the current preferences with the stored values
        for i = 1:length(p);
           name = genvarname(p(i).plugin);
           if isfield(plug,name);
                p(i).Pref = plug.(name);
           end
        end
        
        % Update the general options
        c = get(h.general,'Children');
        for i = 1:length(c);
            name =  genvarname(get(c(i),'Tag'));
           if isfield(gen,name);
                imObj.(name) = gen.(name);
           end
        end
        initGeneral(hObject);
        
        % Update the GUI
        callback_select(h.pluginlist,[]);
end
