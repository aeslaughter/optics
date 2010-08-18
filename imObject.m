classdef imObject < handle
% imObject class definition for analysis w/ snow image toolbox     
%__________________________________________________________________________
% SYNTAX:
%   obj = imObject;
%   obj = imObject(filename);
%
% DESCRIPTION:
%   obj = imObject creates an imObject and prompts the user to specify and
%       image file.
%   obj = imObject(filename) same as above put uses the defined file.
%__________________________________________________________________________

% DEFINE THE PUBLIC (EDITABLE) PROPERTIES OF THE IMOBJECT CLASS
properties % Public properties 
    % Properties defining the image 
    filename; % Filename of the image being opened
    norm;     % Coefficient(s) for normalizing image via white region
    info;     % Structure containing image information
    type;     % String dictating the image type
    imposition = []; % Position of the imtool window
    imsize;   % The image size (in pixels) 

    % Properties for user selected regions
    white = imRegion.empty;
    work = imRegion.empty;

    % Properties associated with the overview window
    overview = 'off'; % Open the overview window
    ovposition = [];  % Position to keep the overview window
    
    % Other properties
    imObjectName = ''; % Filename of saved imObject class
    imObjectPath = ''; % Folder used when saving imObject class
    
    % Set general imObject options (a value must be assigned)
    workNorm = true;
    spectralon = true;
    regionPrompt = true;
%     refreshImage = true;
end 
   
% DEFINE THE PRIVIATE PROPERTIES OF THE imObject CLASS
properties (SetAccess = private)
    imhandle; % Handle of the imtool window
    imaxes;   % Handle to the image axis
    plugins;  % Handles to the plugin object(s)
    ovhandle; % Handle of the overview window
    hprog;    % Handles for toggling imObject functionallity 
    children; % Handles of figures to save
    figures = {}; % List of figure names
end

% DEFINE THE DYNAMIC METHODS FOR THE imObject CLASS
methods       
    % imObject: Operates on imObject creation
    function obj = imObject(varargin)
        addpath('imPlugin','bin');
        obj = openimage(obj,varargin{:});
        if isempty(obj.filename); return; end;
        obj.startup;
    end

    % STARTUP: Used to initialize the creation/loading of an imObject
    function obj = startup(obj)      
        % Create the imObject tools and plugins
        addpath('imPlugin','bin');
        createtools(obj);   
        obj.plugins = addplugins(obj);
        addhelpmenu(obj);
        
        % Setup up the overview window
        if strcmpi(obj.overview,'on'); obj.openOverview; end
        
        % Add handle to the root user data
        obj.addRoot;
    end
    
    % OPENOVERVIEW: opens the overview window
    function obj = openOverview(obj)
        obj.ovhandle = imoverview(imhandles(obj.imhandle));
        set(obj.ovhandle,'Units','Normalized');
        if length(obj.ovposition) == 4;
            set(obj.ovhandle,'Position',obj.ovposition);       
        end
    end
    
    % PLUGINPREF: Opens a window for adjuting preferences of plugins
    function obj = pluginpref(obj)
       prefGUI(obj);
    end
    
    % GETIMAGE: returns the raw image data
    function data = getImage(obj,varargin)
        [~,~,ext] = fileparts(obj.filename);   
        switch ext;
            case {'.bil','.bip'}; % Opens a hyperspectral image   
                [data,~] = readBIP(obj.filename);
                data = single(data);
            otherwise; % Opens a traditional image file
                data = single(imread(obj.filename));
        end
       
        c = obj.imsize;
        data = reshape(data,[],c(3));
        
        if nargin == 2 && strcmpi(varargin{1},'raw') ...
                || nargin == 2 && strcmpi(varargin{1},'white');
            return;
        elseif obj.workNorm && ~isempty(obj.norm);
            for i = 1:c(3);
                data(:,i) = data(:,i)./obj.norm(i);
            end
        end   
    end
    
    % CALCNORM: Normalizes the data based on the white region(s)
    function obj = calcNorm(obj)
        % Gather white region handles        
        obj.progress;
        R = obj.white;
        obj.norm = [];
                
        % Prepare the image for analysis
        r = length(R); % Number of white regions to consider
        c = obj.imsize;
        data = obj.getImage('raw');

        % Compute the mean values of the white regions
        theNorm = zeros(r,c(3));
        for i = 1:r;  
            mask = R(i).getRegionMask; 
            for j = 1:c(3);
                theNorm(i,j) = nanmean(data(mask,j));
            end
        end

        % Update the normalization property
        obj.norm = mean(theNorm,1);
        
        % Apply HSI spectralon reference, if desired
%         if sum(strcmpi({'HSI'},obj.type)) == 1 && obj.spectralon;
%             data = dlmread('teflon.txt');
%             yi = interp1(data(:,1),data(:,2),...
%                 obj.info.wavelength,'spline','extrap');
%             obj.norm = obj.norm.*yi';
%         end
        
        % Restore functionality
        obj.progress
    end
     
    % SAVEimObject: Allows user to save the imObject
    function saveimObject(obj,thepath,thefile)
        % Determine the file to save
        imFile = fullfile(thepath,thefile);
        spec = {'*.imobj','MATLAB imObject class (*.imobj)'};
        imFile = gatherfile('put','LastUsedimObjectDir',spec,imFile);
        if isempty(imFile); return; end 
 
        % Disable the figure
        obj.progress;
        
        % Update the imtool name
        [~,imF,imE] = fileparts(obj.filename);  
        [P,F,E] = fileparts(imFile);
        obj.imObjectName = [F,E];
        obj.imObjectPath = P;
        set(imgcf,'Name',[F,E,' (',imF,imE,')']);
        
        % Save the object and the children
        save(imFile,'-mat','obj');
        
        % Enable the figure
        obj.progress;
    end
    
    % SAVEOBJ: operates with the imObject is being saved
    function obj = saveobj(obj)
        % Update the positions
        set(obj.imhandle,'Units','normalized');
        obj.imposition = get(obj.imhandle,'position');
        if ishandle(obj.ovhandle);
            obj.ovposition = get(obj.ovhandle,'position');
        end
        
        % Saves the imObjects children figures
        obj.saveChildren;       
    end
        
    % ADDCHILD: keeps track of figures created using the plugin
    function obj = addChild(obj,newChild)
        obj.children = [obj.children,newChild];
        idx = ishandle(obj.children);
        obj.children = unique(obj.children(idx));
    end
    
    % SAVEchildren: Saves children figures
    function saveChildren(obj)
        % Gather the figure handles, return if empty
        h = obj.children(ishandle(obj.children));
        if isempty(h); return; end
        
        % Define the path for saving figures
        pth = obj.imObjectPath;
        [~,fn,~] = fileparts(obj.imObjectName);
        figpath = [pth,filesep,'.',fn];
               
        % Create the direcotry
        mkdir(figpath); 
        fileattrib(figpath,'+h')

        % Loop through the handles and save the .fig files
        obj.figures = {};
        for i = 1:length(h);
            figname = [figpath,filesep,randstr(18),'.fig'];
            hgsave(h(i),figname); 
            obj.figures{i} = figname;
            fileattrib(figname,'+h');
        end   
    end
    
    % PROGRESS: Toggles the funtionallity of the imObject on and off
    function progress(obj,varargin)
        % Disable handles
        if isempty(obj.hprog)
            obj.hprog = findobj('enable','on');
            set(obj.hprog,'enable','off');
            drawnow;
            
        % Enable handles    
        else
            set(obj.hprog,'enable','on');
            obj.hprog = [];
        end
    end
    
    % SET.workNORM: Operates when the workNorm property is changed
    function obj = set.workNorm(obj,input)
        obj.workNorm = input;
        obj.calcNorm;        
    end
    
    % ADDROOT: Adds the created imObject to an array of handles
    function obj = addRoot(obj)
        H = get(0,'UserData');
        if isempty(H);
            H = obj;
        else
            H(end+1) = obj;
        end
        idx = isvalid(H);
        set(0,'UserData',H(idx));
    end
    
    % DELETE: operates when the imObject is being destroyed
    function delete(obj)
        for i = 1:length(obj.children);
            if ishandle(obj.children(i)); delete(obj.children(i)); end
        end
        if ishandle(obj.imhandle); delete(obj.imhandle); end
        delete(obj.work);
        delete(obj.white);
    end
end % end dynamic methods

% DEFINE THE STATIC METHODS FOR imObject CLASS
methods (Static)
    % LOADOBJ: Operates when the object is loaded via load function
    function obj = loadobj(obj)
        % Add required paths
        addpath('imPlugin','bin');
    
        % Load the image, tool, plugins, etc...
        obj = openimage(obj,obj.filename); % Opens the desired image
        obj.startup; % Initilizes the image (as created)

        % Restore work regions
        for i = 1:length(obj.work);
            obj.work(i).createregion('load');
            obj.work(i).addlabel(obj.work(i).label);
        end
        
        % Restore white regions
        for i = 1:length(obj.white);
            obj.white(i).createregion('load');
            obj.white(i).addlabel(obj.white(i).label);
        end
        
        % Open the figures
        for i = 1:length(obj.figures);
           obj.children(i) = hgload(obj.figures{i}); 
        end 

    end
end % ends static methods
end % ends the main classdef

%--------------------------------------------------------------------------
function obj = openimage(obj,varargin)
% OPENIMAGE opens the desired image upon creation/loading of imObject class

% SET/GATHER THE IMAGE FILENAME
spec = {'*.jpg','JPEG Image (*.jpg)';...
    '*.bip;*.bil','HSI Image (*.bip,*.bil)'};
obj.filename = gatherfile('get','LastUsedDir',spec,varargin{:});
if isempty(obj.filename); return; end

% OPEN THE IMAGE
[~,~,ext] = fileparts(obj.filename);   
switch ext;
    case {'.bil','.bip'}; % Opens a hyperspectral image   
        % Reads the *.bip and *.bip.hdr files
        [data, obj.info] = readBIP(obj.filename);
        IM = single(viewBIP(data,obj.info));
        obj.imsize = size(data);
        obj.type = {'HSI'};
    otherwise; % Opens a traditional image file
        IM = imread(obj.filename);
        obj.imsize = size(IM);
        obj.info = imfinfo(obj.filename);
        obj.type = {'VIS','NIR'};
end

% BUILD THE IMAGE NAME
if ~isempty(obj.imObjectName);
    [~,f,e] = fileparts(obj.imObjectName);
    name = [f,e,' (',obj.filename,')'];
else
    [~,f,e] = fileparts(obj.filename);
    name = [f,e];
end

% OPEN THE IMAGE AND ASSIGN OBJ DATA AND 
h = imtool(IM); 
obj.imhandle = h;
obj.imaxes = imgca;
guidata(h,obj);

% SET THE CLOSING FUNCTION AND RESIZE THE IMAGE
set(h,'BusyAction','cancel','Units','Normalize','Name',name,...
    'CloseRequestFcn',@callback_closefcn);
if ~isempty(obj.imposition);
    set(h,'Position',obj.imposition);
end

end   

%--------------------------------------------------------------------------
function createtools(obj)
% CREATETOOLS adds the desired 

% DEFINE THE imObject MENU
h = obj.imhandle; % imtool handle
[~,fn,ext] = fileparts(obj.filename);
set(h,'MenuBar','none');
im = uimenu(h,'Label','im&Object'); % The Regions menu
    uimenu(im,'Label','imObject Save','callback',...
        @(src,event)saveimObject(obj,obj.imObjectPath,...
        obj.imObjectName));
    uimenu(im,'Label','imObject Save as...','callback',...
        @(src,event)saveimObject(obj,'',''));
    uimenu(im,'Label','Open Overview','separator','on','Checked',...
        obj.overview,'callback',@callback_overview);
    uimenu(im,'Label','View Image Information','separator','on',...
        'callback',@(src,event)viewStructure(obj.info,[fn,ext]));
    uimenu(im,'Label','Plugin Preferences','separator','on',...
        'callback',@(src,event)pluginpref(obj));    

% DEFINE THE REGIONS MENU
type = {'Rectangle','Ellipse','Polygon','Freehand'}; % Sub-menu items
m = uimenu(h,'Label','Regions'); % The Regions menu

% DEFINE THE WHITE BACKGROUND REGION MENUS
w = uimenu(m,'Label','Add White Reference','Separator','on');
    for i = 1:length(type);
        uimenu(w,'Label',type{i},'callback',...
            @(src,event)callback_createregion(obj,'white',type{i}));
    end
    uimenu(m,'Label','Clear White Reference(s)','callback',...
        @(src,event)callback_rmregion(obj,'white'));
    
% DEFINE THE WORK REGION MENUS    
w = uimenu(m,'Label','Add Work Region','Separator','on');
    for i = 1:length(type);
        uimenu(w,'Label',type{i},'callback',...
            @(src,event)callback_createregion(obj,'work',type{i}));
    end
    uimenu(m,'Label','Clear Work Region(s)','callback',...
        @(src,event)callback_rmregion(obj,'work'));   
    
% DEFINE THE TOOLBAR W/ PREFERENCES BUTTON
    icon = load('icon/icons.ico','-mat');
    tbar = uitoolbar(h,'Tag','TheToolBar');
    uipushtool(tbar,'Cdata',icon.save,'TooltipString','Save imObject',...
        'ClickedCallback',@(src,event)saveimObject(obj,obj.imObjectPath,...
        obj.imObjectName));   
    uipushtool(tbar,'Cdata',icon.pref,'TooltipString',...
        'imObject Preferences','ClickedCallback',...
        @(src,event)pluginpref(obj));   
end

%--------------------------------------------------------------------------
function plugin = addplugins(obj)
% ADDPLUGINS searchs the plugin directory and adds plugin options

% LOCATE THE M-FILES IN PLUGIN DIRECTORY
pth = [cd,filesep,'imPlugin',filesep];           
addpath(pth); 
f = dir([pth,'*.m']);

% EVALUATE ALL M-FILES IN PLUGINS DIRECTORY 
% (use if it returns imPlugin object)
k = 1;
for i = 1:length(f);
    [~,name] = fileparts(f(i).name);
    p = feval(name,obj);
    if strcmpi(class(p),'imPlugin');
        plugin(k) = p; % Plugin handle
        Morder(k) = p.MenuOrder; % Desired order for menu item
        Porder(k) = p.PushtoolOrder; % Desired order for pushtool button
        k = k + 1;
    end
end
          
% CREATE THE MENU AND PUSHTOOL CONTROLS 
[~,Mix] = sort(Morder); % Re-orders the menu items
[~,Pix] = sort(Porder); % Re-orders the pushtool items

    % Create the menus items, using appropriate plugin class method
    for i = 1:length(Mix);
        plugin(Mix(i)).createmenuitem;
    end

    % Create the pushtool items, using appropriate plugin class method
    for i = 1:length(Pix);
        plugin(Pix(i)).createpushtool;
    end    
end

%--------------------------------------------------------------------------
function addhelpmenu(obj)
% ADDHELPMENU adds the help and about menu items to the GUI

h = obj.imhandle;
im = uimenu(h,'Label','Help'); % The Regions menu
uimenu(im,'Label','Snow Optics Toolbox Help','Callback','gethelp');
uimenu(im,'Label','About Snow Optics Toolbox','Callback','about');
end

%--------------------------------------------------------------------------
function obj = callback_createregion(obj,type,func)
% CALLBACK_CREATEREGION gathers/creates regions via the imRegion class

% Create the region
R = imRegion(obj,type,func); 

% Add the region to the imObject
n = length(obj.(type)) + 1; 
obj.(type)(n) = R;

% Add the label
R.addlabel([' ',num2str(n)]); 

% Update the norm
if strcmpi('white',type); obj.calcNorm; end;

end

%--------------------------------------------------------------------------      
function obj = callback_rmregion(obj,item)
% CALLBACK_RMREGION removes regions
    delete(obj.(item));  
    obj.(item)= imRegion.empty;
    if strcmpi(item,'white'); obj.norm = []; end
end

%--------------------------------------------------------------------------
function callback_overview(hObject,~)
% CALLBACK_OVERVIEW toggle the overview window  
obj = guidata(hObject);
status = get(hObject,'Checked');
switch status;
    case 'on'; 
        obj.overview = 'off';
        set(hObject,'Checked','off');
        close(obj.ovhandle);
    case 'off';
        obj.overview = 'on';
        set(hObject,'Checked','on');
        obj.openOverview;
end
end

%--------------------------------------------------------------------------
function callback_closefcn(hObject,~)
% CALLBACK_CLOSEFCN closes the imObject by deleting the class and figure
    obj = guidata(hObject);
    figs = obj.plugins.children;
    for i = 1:length(figs); 
        if ishandle(figs(i)); delete(figs(i)); end; 
    end
    delete(obj.plugins); 
    cur = findobj('Name','Plugin Preferences'); delete(cur);
    delete(obj);
end
