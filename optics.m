classdef optics < handle
% OPTICS defines the class for viewing snow optics image files
    
% DEFINE THE PUBLIC PROPERTIES    
properties
    FTP;        % FTP object
    fig;        % Handle of the Program Control Window
    position;   % Position of the Program Control
    exp;        % Folder for the experiment(s) (top level)
    folder;     % Sub folder(s) of the experiment (second level)
    type;       % Folder indicating the type of image (third level)
    angle;      % Angle folder (ZxxVxxY, fourth level)
    thepath;    % Current folder path for ftp download
    
    opticsPath = ''; % Path of savde workspace
    opticsFile = ''; % Filename of saved workspace (*.sws)
    
    % Define the user preferences
    pref = {'keeplocal','appendWorkspace','target'}; % List of option props
    keeplocal = true;           % Toggle for saving/removing local files
    appendWorkspace = true;     % Toggle for clearing exiting files 
    target = 'database';        % The location of the image database
end

% DEFINE THE PRIVATE PROPERTIES
properties (SetAccess = private)
    host = 'caesar.ce.montana.edu';         
    username = 'anonymous';                 
    password = 'snowoptics';
    thedir = '/pub/snow/optics';
    extensions = {'.jpg','.bip','.bil'}; % File extensions to allow
    handles = imObject.empty; % Initilize the imObject handles
    
    version = 0.1; % Uses this to check for updates
    verdate = 'August 18, 2010';
end

% DEFINE THE METHODS
methods
    % OPTICS: operates on creation of optics object
    function obj = optics
        addpath('bin');
        obj.fig = open('controlGUI.fig'); % Opens the GUI
        obj.startup; % Initlizes the optics class
    end
    
    % STARTUP: initilizes the optics class
    function obj = startup(obj)
       % Connect to the ftp site
        try
            obj.FTP = ftp(obj.host,obj.username,obj.password);
            cd(obj.FTP,obj.thedir);
        catch
            warndlg('Failed to connect to the FTP server!');
        end
            
       % Initilize the GUI
       initControlGUI(obj);
    end
    
    % SETPREF: changes the current optics preferencs
    function obj = opticsPref(obj,pref)
        % Gather handle for the options GUI
        H = findobj('Tag','OpticsOptions');
        
        % Throw an error if called without the options GUI open
        if isempty(H) || ~ishandle(H);
            error('The options window must be opened!');
        else
            h = guihandles(H);
        end
        
        % Gather the new preference
        if isnumeric(obj.(pref));
            obj.(pref) = get(h.(pref),'Value');
        elseif ischar(obj.(pref));
            obj.(pref) = get(h.(pref),'String');
        end
    end
              
    % SETDEFAULTPREF: sets the current preferences as the default
    function obj = setdefaultPref(obj)
        % Loop through each preference and store
        p = obj.pref;
        for i = 1:length(p);
            setpref('OpticsOptions',p{i},obj.(p{i}));
        end
    end
    
    % GETDEFAULTPREF: recalls and implements the default preferences
    function obj = getdefaultPref(obj)  
        % Loop through each preference and load the default
        p = obj.pref;
        for i = 1:length(p);
            if ispref('OpticsOptions',p{i});
                obj.(p{i}) = getpref('OpticsOptions',p{i});
            else % create if it does not already exist
                setpref('OpticsOptions',p{i},obj.(p{i}));
            end
        end
        
        % Applies the default preferences, if the options windows is open       
        H = findobj('Tag','OpticsOptions');
        if ~isempty(H) && ishandle(H);
            h = guihandles(H); % GUI handles of the options window        
            for i = 1:length(p); % Loops through each preference
                if isnumeric(obj.(p{i}));
                    set(h.(p{i}),'Value',obj.(p{i}));
                elseif ischar(obj.(p{i}));
                    set(h.(p{i}),'String',obj.(p{i}));
                end
            end
        end    
    end
           
    % GETFILES: gathers the image files based on the folders selected
    function obj = getFiles(obj)
        % Gather the gui handles and existing images files
        h = guihandles(obj.fig);
        data = dir(obj.FTP,[obj.thepath,'/*.*']);
        
        % Cycle through each file and build a list of images only
        list = {}; k = 1;
        for i = 1:length(data);
            [~,~,e] = fileparts(data(i).name);
            if sum(strcmpi(e,obj.extensions)) == 1
                list{k} = data(i).name;
                k = k + 1;
            end
        end
        
        % Update the GUI object containing the list of images
        if isempty(list);
            set(h.images,'enable','off','String',{},'Value',0);
        else
            set(h.images,'enable','on','String',list,'Value',1);
        end
    end
    
    % OPENIMAGES: operates upon selection of the open button
    function obj = openImages(obj)
        % Gather guihandles and the selected files
        h = guihandles(obj.fig);
        str = get(h.images,'String');
        files = str(get(h.images,'Value'));

        % Change the directory to the current folder and build local path
        cd(obj.FTP,obj.thepath);
        localpath = regexprep(obj.thepath,'/',filesep);
        localpath = [obj.target,filesep,localpath];
        
        % Create the local directory if it does not exist
        if ~exist(localpath,'dir');
            mkdir(localpath);
        end
        
        % Cylce through the images and download to local directory
        for i = 1:length(files);
            filename = [localpath,filesep,files{i}];
            [~,~,ext] = fileparts(filename);
            if ~exist(filename,'file');
                mget(obj.FTP,files{i},localpath);
                if strcmpi('.bil',ext) || strcmpi('.bip',ext);
                    mget(obj.FTP,[files{i},'.hdr'],localpath);
                end
            end
            obj.handles(end+1) = imObject(filename);  
        end
        
        % Return the ftp directory to the base
        cd(obj.FTP,obj.thedir);
        
        % Update the imObject handle list
        idx = isvalid(obj.handles);
        obj.handles = obj.handles(idx);
    end
    
    % SAVEWORKSPACE: operates to save the current workspace
    function saveWS(obj,thepath,thefile)
        % Determine the file to save
        filename = fullfile(thepath,thefile);
        spec = {'*.sws','MATLAB snow optics workspace (*.sws)'};
        filename = gatherfile('put','LastUsedWorkSpaceDir',spec,filename);
        if isempty(filename); return; end 
        
        % Remove invalid (delete) imObjects
        idx = isvalid(obj.handles);
        obj.handles = obj.handles(idx);
        
        % Cycle through each imObject and remove image data (saves space)
        tmp = {'display','image','info'};
        [pth,fname,ext] = fileparts(filename);  
        for i = 1:length(obj.handles);
            % Set the imObject path and filename (used for saving *.figs)
            obj.handles(i).imObjectPath = pth;
            obj.handles(i).imObjectName = [fname,ext];
            
            % Copy the object and remove extenous data
            S(i) = struct(obj.handles(i));
            for j = 1:length(tmp); obj.handles(i).(tmp{j}) = []; end
        end
        
        % Update the control window position
        set(obj.fig,'Units','normalized');
        obj.position = get(obj.fig,'position');
                     
        % Remove . directory if it exits
        [pth,fn] = fileparts(filename);
        dotdir = [pth,filesep,'.',fn];
        if exist(dotdir,'dir'); rmdir(dotdir,'s'); end
        
        % Save the optics object
        obj.opticsPath = pth;
        obj.opticsFile = [fname,ext];
        save(filename,'-mat','obj');
        
        % Restore the imObject data
        for i = 1:length(obj.handles);
            for j = 1:length(tmp); 
                obj.handles(i).(tmp{j}) = S.(tmp{j}); 
            end
        end

    end
    
    % LOADWS: operates when loading a workspace
    function obj = loadWS(obj)
        % Load the *.sws file
        spec = {'*.sws','MATLAB snow optics workspace (*.sws)'};
        filename = gatherfile('get','LastUsedWorkSpaceDir',spec);
        oldObj = obj;
        tmp = load(filename,'-mat'); obj = tmp.obj;
            
        % Update the handles structure
        if obj.appendWorkspace % adds workspace to existing
            obj.handles = [oldObj.handles,obj.handles];
            idx = isvalid(obj.handles);
            obj.handles = obj.handles(idx);
            
        else % removes existing images
            idx = isvalid(obj.handles);
            delete(obj.handles(idx));
            set(obj.fig,'Units','normalized','Position',newObj.position);
        end
        
        % Update the workspace file information and update the folders
        %obj.updateFolders;
    end
       
    % CLOSEOPTICS: operates when the GUI is being closed
    function closeOptics(obj)
        % Close the ftp connection
        close(obj.FTP);
        
        % Delete the imObjects
        idx = isvalid(obj.handles);
        obj.handles = obj.handles(idx);
        for i = 1:length(obj.handles);
            delete(obj.handles(i));
        end
        
        % Delete the program control window
        delete(obj.fig);
        
        % Delete the options window
        H = findobj('Tag','OpticsOptions'); delete(H);
        
        % Delete database images, if desired
        if ~obj.keeplocal
            rmdir(obj.target,'s');
        end
    end   
end

% DEFINE THE STATIC METHODS FOR optics CLASS
methods (Static)
    % LOADOBJ: Operates when the object is loaded via load function
    function obj = loadobj(obj)
        % Add required paths
        addpath('imPlugin','bin');
        obj.fig = findobj('Name','Optics Program Control');
        if isempty(obj.fig);
            obj.fig = open('controlGUI.fig');
            set(obj.fig,'Units','Normalized','Position',obj.position);
        end
        
        obj.startup; % Initilizes the image (as created)
        
    end
end % ends static methods
end

%--------------------------------------------------------------------------
function initControlGUI(obj)
% INITCONTROLGUI initilizes the control GUI

% Gather the handles to the GUI and store optics object handle
h = guihandles(obj.fig);
guidata(obj.fig,obj);

% Set the window name and callbacks for closing the GUI
set(obj.fig,'Name','Optics Program Control');
set(obj.fig,'CloseRequestFcn',@(src,event)closeOptics(obj));
set(h.options,'Callback',@callback_pref);
set(h.exit,'Callback',@(src,event)closeOptics(obj));

% Define callbacks for folder selection
set(h.exp,'Callback',@callback_exp,'Value',1);
set(h.folder,'Callback',@callback_folder,'Value',1);
set(h.type,'Callback',@callback_type,'Value',1);
set([h.angles,h.zenith,h.viewer,h.azimuth],'Callback',@callback_angle,...
    'Value',1);

% Define callback for opening the images
set(h.openimages,'Callback',@(src,event)openImages(obj));

% Define callbacks for the menu items
set(h.WSsave,'callback',@(src,event)saveWS(obj,obj.opticsPath,...
        obj.opticsFile));
set(h.WSsaveas,'callback',@(src,event)saveWS(obj,'',''));
set(h.WSopen,'callback',@(src,event)loadWS(obj));
set(h.gethelp,'callback','gethelp');
set(h.about,'callback','about');

% Get the default preferences
obj.getdefaultPref;

% Set the version propertery
setpref('OpticsObject','version',{obj.version,obj.verdate});

% Intilize the GUI by calling the experiment folder callback
callback_exp(h.exp,[],'init');
end

%--------------------------------------------------------------------------
function callback_exp(hObject,~,varargin)
% CALLBACK_EXP operates when the user selects an experiment

% Gather the optics object and GUI handles
obj = guidata(hObject);
h = guihandles(hObject);

% Gather the folder structure from the FTP site
data = struct2cell(dir(obj.FTP));
str = data(1,:);
set(hObject,'String',str);

% Setup the folder structure, varagin{1} = 'init' uses the saved value
val = initFolder(hObject,obj.exp,varargin{:});
obj.exp = str{val};

% Move to the next folder level
callback_folder(h.folder,[],varargin{:});
end

%--------------------------------------------------------------------------
function callback_folder(hObject,~,varargin)
% CALLBACK_FOLDER operates when the user selects a folder

% Gather the optics object and GUI handles
obj = guidata(hObject);
h = guihandles(hObject);

% Gather the folder structure from the FTP site
data = struct2cell(dir(obj.FTP,obj.exp));
idx = cell2mat(data(3,:)); % Only considers folders
str = data(1,idx);
set(hObject,'String',str);

% Setup the folder structure, varagin{1} = 'init' uses the saved value
val = initFolder(hObject,obj.folder,varargin{:});
obj.folder = str{val};   

% Move to the next folder level
callback_type(h.type,[],varargin{:});
end

%--------------------------------------------------------------------------
function callback_type(hObject,~,varargin)
% CALLBACK_TYPE operates when the user selects a type

% Gather the optics object
obj = guidata(hObject);

% Gather the folder structure from the FTP site
thepath = buildpath(obj.exp,obj.folder);
data = struct2cell(dir(obj.FTP,thepath));
idx = cell2mat(data(3,:)); % Only considers folders
str = data(1,idx);
set(hObject,'String',str);

% Setup the folder structure, varagin{1} = 'init' uses the saved value
val = initFolder(hObject,obj.type,varargin{:});
obj.type = str{val};   

% Move to the next folder level
callback_angle(hObject,[],varargin{:});
end

%--------------------------------------------------------------------------
function callback_angle(hObject,~,varargin)
% CALLBACK_ANGLE operates when angle panel is changed or toggled

% Gather the optics object and GUI handles
obj = guidata(hObject);
h = guihandles(hObject);
hangles = [h.zenith,h.viewer,h.azimuth];

% Gather files from current directory if toggle is 'off'
value = get(h.angles,'Value');
if ~value; % case when 'off' (ignores angle directory)
    set(hangles,'enable','off');
    obj.thepath = buildpath(obj.exp,obj.folder,obj.type); 
    obj.angle = '';
    obj.getFiles;
else % case when 'on' (uses angle directory)
    set(hangles,'enable','on');
    obj.angle = getAngleFolder(h,obj,varargin{:});
    obj.thepath = buildpath(obj.exp,obj.folder,obj.type,obj.angle); 
    obj.getFiles;
end

end

%--------------------------------------------------------------------------
function callback_pref(hObject,~)
% CALLBACK_PREF opens the optics object preferences

obj = guidata(hObject);
H = findobj('Tag','OpticsOptions'); delete(H);
H = open('opticsPrefGUI.fig'); drawnow;
h = guihandles(H);

for i = 1:length(obj.pref);
    p = obj.pref{i};
    if isnumeric(obj.(p)) || islogical(obj.(p));
        type = 'Value'; obj.(p) = double(obj.(p));
    elseif ischar(p);
        type = 'String';
    end
    set(h.(p),'Callback',@(src,evnt)opticsPref(obj,p),...
        type,obj.(p));
end

set(h.changetarget,'callback',{@callback_changetarget,obj});
set(h.savedef,'callback',@(src,evnt)setdefaultPref(obj));
set(h.loaddef,'callback',@(src,evnt)getdefaultPref(obj));
set(h.close,'Callback','close(gcbf)');

end

%--------------------------------------------------------------------------
function callback_changetarget(hObject,~,obj)
% CALLBACK_CHANGETARGET changes the targed directory for local image files

% Determine/set the last used directory
if ispref('OpticsOptions','LastUsedOpticsDatabaseDir');
    pth = getpref('OpticsOptions','LastUsedOpticsDatabaseDir');
else
    pth = cd;
end

% Gather the directory
pth = uigetdir(pth,'Select taget directory');
if isnumeric(pth); return; end

% Update the object, GUI, and stored directory
obj.target = pth;
h = guihandles(hObject);
set(h.target,'String',pth);
setpref('OpticsOptions','LastUsedOpticsDatabaseDir',pth);

end

%--------------------------------------------------------------------------
function angle = getAngleFolder(h,obj,varargin)
% GETANGLEFOLDER gathers the angle, viewer, zintth folder    

% Gather the current path based on selected folders
thepath = buildpath(obj.exp,obj.folder,obj.type);

% Gather exiting angles
z = ''; v = ''; a = '';
if ~isempty(obj.angle);
   z = obj.angle(2:3);
   v = obj.angle(5:6);
   a = obj.angle(end);
end

% Define the available zenith angles
zdir = dir(obj.FTP,[thepath,'/Z*']);
if isempty(zdir);
    warndlg('No angle directories exist!');
    set(h.angles,'Value',0); 
    callback_exp(h.exp,[],'init');
    angle = '';
    return;
end
data = struct2cell(dir(obj.FTP,[thepath,'/Z*']));
str = char(data(1,:));
Z = unique(cellstr(str(:,2:3)));
set(h.zenith,'String',Z);
val = initFolder(h.zenith,z,varargin{:});
z = Z{val};

% Define the available viewer angles
data = struct2cell(dir(obj.FTP,[thepath,'/Z',z,'*']));
str = char(data(1,:));
V = unique(cellstr(str(:,5:6)));
set(h.viewer,'String',V);
val = initFolder(h.viewer,v,varargin{:});
if length(V) < val; set(h.viewer,'Value',1); end
v = V{get(h.viewer,'Value')};

% Define the available azimuths
data = struct2cell(dir(obj.FTP,[thepath,'/Z',z,'V',v,'*']));
str = char(data(1,:)); 
A = unique(cellstr(str(:,7)));
set(h.azimuth,'String',A);
val = initFolder(h.azimuth,a,varargin{:});
if length(A) < val; set(h.azimuth,'Value',1); end
a = A{get(h.azimuth,'Value')};

% Output the current angle folder
angle = ['Z',z,'V',v,a];

end

%--------------------------------------------------------------------------
function thepath =  buildpath(varargin)
% BUILDPATH: construct the path for accessing images in the ftp server
thepath = varargin{1};
for i = 2:length(varargin);
    if ~isempty(varargin{i});
       thepath = [thepath,'/',varargin{i}]; 
    end
end
end

%--------------------------------------------------------------------------
function val = initFolder(hObject,str,varargin)
% INITFOLDER initilize the folder sturture of the optics control GUI
    strarray = get(hObject,'String');
    if ~isempty(varargin) && strcmpi(varargin{1},'init') && ~isempty(str);
        val = strmatch(str,strarray);
        if isempty(val); val = get(hObject,'Value'); end
    else
        val = get(hObject,'Value');
    end
    set(hObject,'Value',val) ;
end
