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
properties (SetAccess = private)
    parent; % Handle for the parent imObject
    children = []; % Handles to figure windows associated with plugin
    figures = {}; % Filenames of open figures for recall at load
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
        if ~isempty(obj.plugintype) && ~strcmpi(obj.parent.type,...
                obj.plugintype)
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
        if ~isempty(obj.plugintype) && ~strcmpi(obj.parent.type,...
                obj.plugintype)
            set(mm,'enable','off');
        end
    end

    % PUSHTOOLCDATA: gathers the icon image data
    function set.PushtoolCdata(obj,input)
        % Get icon structure from the icon files
        S = geticons;

        % Gather the icon data based on the input type
        if isnumeric(input) && isequal(size(input),[16,16,3]); % Numeric
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
    
    % ADDCHILD: keeps track of figures created using the plugin
    function obj = addChild(obj,newChild)
        obj.children = [obj.children,newChild];
        idx = ishandle(obj.children);
        obj.children = unique(obj.children(idx));
    end
    
    % SAVEOBJ: saves any open figures as it is destroyed
    function obj = saveobj(obj)
        % Gather the figure handles, return if empty
        h = obj.children(ishandle(obj.children));
        
        % Define the path for saving figures
        pth = obj.parent.imObjectPath;
        [~,fn,~] = fileparts(obj.parent.imObjectName);
        figpath = [pth,filesep,'.',fn];
        
        % Remove existing directory, if present
        if exist(figpath,'dir'); 
            rmdir(figpath,'s'); 
        end
        if isempty(h); return; end
        
        % Create the direcotry
        mkdir(figpath); 
        fileattrib(figpath,'+h');

        % Loop through the handles and save the .fig files
        obj.figures = {};
        for i = 1:length(h);
            figname = [figpath,filesep,obj.plugin,'_',num2str(i),'.fig'];
            saveas(h(i),figname); 
            fileattrib(figpath,'+h');
            obj.figures{i} = figname;
        end
    end
end

% DEFINE THE STATIC METHODS OF imPlugin CLASS
methods (Static)
    % LOADOBJ: opens any associated figures when being loaded
    function obj = loadobj(obj)
        for i = 1:length(obj.figures);
           obj.children(i) = open(obj.figures{i}); 
        end 
    end
end      
end

%--------------------------------------------------------------------------
function S = geticons
% GETICIONS loads and compiles the *.ico files into a single structure

    ico = dir(['icon',filesep,'\*.ico']); % Gather the files
    c = {}; fields = {}; % Intilize storage
    
    % Cylce through the files
    for i = 1:length(ico);
        s = load(ico(i).name,'-mat');
        f = fieldnames(s);
        d = struct2cell(s);
        c = [c;d];
        fields = [fields;f];
    end
    S = cell2struct(c,fields);                
end
