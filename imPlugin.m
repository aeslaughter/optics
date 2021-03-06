classdef imPlugin < handle
% imPlugin class definition for imobject plugins  
%__________________________________________________________________________
% SYNTAX:
%   imPlugin(imObjectHandle);
%
% DESCRIPTION:
%__________________________________________________________________________

% DEFINE THE PUBLIC PROPERTIES OF THE CLASS
properties % Public properties
    MenuParent = '';    % The name of the parent menu
    MenuOptions = {};   % Property parings defining the uimenu item
    MenuSubmenu = {};   % Cell array of uimenu items for submenus
    MenuOrder = NaN;    % The placement order within the partent

    PushtoolCdata = [];     % Image name or icons.ico or icons.mat
    PushtoolToggle = false; % True = uitoggletool; false = uipushtool
    PushtoolOrder = NaN;    % The placement order of the button
    PushtoolOptions = {};   % Property pairings for the button

    % Defines the data structure for the user editable preferences
    Pref = struct('Value',{},'Options',{},'Label',{},'Function',{});

    plugin;     % String containing the name of the plugin
    plugintype; % String defininig the type of image
end
  
% SET THE PRIVATE PROPERTIES OF THE CLASS
properties (SetAccess = private, Transient = true)
    parent; % Handle for the parent imObject
end

% DEFINE THE METHODS OF THE imPlugin CLASS
methods   
    % IMPLUGION: operates when the imPlugin object is created
    function obj = imPlugin(imObject,PluginName)
        obj.parent = imObject;              % Gather the image handle
        obj.plugin = PluginName;            % The plugin name
        obj = obj.getDefaultPref;           % Load the defaults
    end

    % CREATEMENUITEM: contructs the menu item(s)
    function createmenuitem(obj)
        % Return if the parent menu is empty
        if isempty(obj.MenuParent); return; end

        % Locate or create the parent menu
        h = obj.parent.imhandle;
        m = findall(h,'Label',obj.MenuParent);
        if isempty(m); 
            m = uimenu(h,'Label',obj.MenuParent); 
        end

        % Create the menu items
        mm = uimenu(m,obj.MenuOptions{:});

        % Create the submenus
        sub = obj.MenuSubmenu;
        if ~isempty(sub) && iscell(sub);
            for i = 1:length(sub);
                uimenu(mm,sub{i}{:});
            end
        end

        % Set the enable setting
        if ~isempty(obj.plugintype) && sum(strcmpi(obj.parent.type,...
                obj.plugintype)) == 0
            set(mm,'enable','off');
        end
    end

    % CREATEPUSHTOOL: constructs the toolbar buttons
    function createpushtool(obj)
        % Return if the pushtool settings are empty
        if isempty(obj.PushtoolCdata); return; end

        % Determine the type of button to produce
        if obj.PushtoolToggle;
            func = 'uitoggletool';
        else
            func = 'uipushtool';
        end
        
        % Locate or create the toolbar for button placement  
        h = obj.parent.imhandle; % Handle of the image
        tbar = findobj(h,'Tag','TheToolBar');
        if isempty(tbar);
            tbar = uitoolbar(h,'Tag','TheToolBar');
        end

        % Create the button
        mm = feval(func,tbar,'Cdata',obj.PushtoolCdata,...
            obj.PushtoolOptions{:});
        
        % Set the enable setting
        if ~isempty(obj.plugintype) && sum(strcmpi(obj.parent.type,...
                obj.plugintype)) == 0;
            set(mm,'enable','off');
        end
    end

    % PUSHTOOLCDATA: gathers the icon image data
    function set.PushtoolCdata(obj,input)
        % Get icon structure from the icon files
        S = geticons;

        % Gather the icon data based on the input type
        if isnumeric(input) && all(size(input)==[16,16,3]); % Numeric
            obj.PushtoolCdata = input;
        elseif exist(input,'file'); % Image file
            obj.PushtoolCdata = imread(input);
        elseif isfield(S,input); % icon file structure name
            obj.PushtoolCdata = S.(input);
        else
            warning('Input for icon image Cdata was not recognized');
            obj.PushtoolCdata = rand(16,16,3);
        end
    end

    % SETDEFAULTPREF: stores the plugin preferences via MATLAB pref
    function obj = setDefaultPref(obj)
        setpref('imPlugin',obj.plugin,obj.Pref);
    end

    % GETDEFAULTPREF: loads stored default preferences 
    function obj = getDefaultPref(obj)
        if ispref('imPlugin',obj.plugin);
            obj.Pref = getpref('imPlugin',obj.plugin);
        end
    end

    % CLEARDEFAULTPREF: clears any stored preferences
    function obj = clearDefaultPref(obj)
        rmpref('imPlugin',obj.plugin);
    end
end     
end

%--------------------------------------------------------------------------
function S = geticons
% GETICIONS loads and compiles the *.ico files into a single structure

    ico = dir(['icon',filesep,'*.ico']); % Gather the files
    c = {}; fields = {}; % Intilize storage
    
    % Cylce through the files
    for i = 1:length(ico);
        s = load(['icon',filesep,ico(i).name],'-mat');
        f = fieldnames(s);
        d = struct2cell(s);
        c = [c;d];
        fields = [fields;f];
    end
    S = cell2struct(c,fields);                
end
