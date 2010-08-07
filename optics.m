classdef optics < handle
    
% DEFINE THE PUBLIC PROPERTIES    
properties
    FTP; % FTP object
    fig; % Handle of the Program Control Window
    exp;
    folder;
    type;
    angle;
    thepath;
end

% DEFINE THE PRIVE PROPERTIES
properties (SetAccess = private)
    host = 'caesar.ce.montana.edu';
    username = 'anonymous';
    password = 'snowoptics';
    thedir = 'pub/snow/optics';
    extensions = {'.jpg','.bip'};
end


methods
    function obj = optics
       % CONNECT TO FTP SITE
       try
            obj.FTP = ftp(obj.host,obj.username,obj.password);
            cd(obj.FTP,obj.thedir);
       catch
           error('optics:FTP:fail','Failed to connect to the FTP server!');
       end
            
       % INTILIZE GUI
       obj.fig = open('controlGUI.fig');
       initControlGUI(obj);

    end
           
    function obj = getFiles(obj)
        h = guihandles(obj.fig);
        data = dir(obj.FTP,[obj.thepath,'/*.*']);
        
        list = {}; k = 1;
        for i = 1:length(data);
            [~,~,e] = fileparts(data(i).name);
            if sum(strcmpi(e,obj.extensions)) == 1
                data(i).name
                list{k} = data(i).name;
                k = k + 1;
            end
        end
        
        if isempty(list);
            set(h.images,'enable','off','String',{},'Value',0);
        else
            set(h.images,'enable','on','String',list,'Value',1);
        end
    end
    
    function closeOptics(obj)
        close(obj.FTP);
        delete(obj.fig);
        
    end
        
end
    
end

%--------------------------------------------------------------------------
function initControlGUI(obj)
% INITCONTROLGUI initilizes the control GUI

h = guihandles(obj.fig);
set(obj.fig,'Name','Optics Program Control');
set(obj.fig,'CloseRequestFcn',@(src,event)closeOptics(obj));
guidata(obj.fig,obj);

set(h.exp,'Callback',@callback_exp,'Value',1);
set(h.folder,'Callback',@callback_folder,'Value',1);
set(h.type,'Callback',@callback_type,'Value',1);
set([h.angles,h.zenith,h.viewer,h.azimuth],'Callback',@callback_angle,...
    'Value',1);

callback_exp(h.exp,[]);

end

%--------------------------------------------------------------------------
function callback_exp(hObject,~)
% CALLBACK_EXP operates when the user selects an experiment

% Gather the optics object and GUI handles
obj = guidata(hObject);
h = guihandles(hObject);

% Gather the folder structure from the FTP site
data = struct2cell(dir(obj.FTP));
str = data(1,:);
set(hObject,'String',str);

% Update the optics object properties and move to the next folder level
obj.exp = str{get(hObject,'Value')};
callback_folder(h.folder,[]);

end

%--------------------------------------------------------------------------
function callback_folder(hObject,~)
% CALLBACK_FOLDER operates when the user selects a folder

% Gather the optics object and GUI handles
obj = guidata(hObject);
h = guihandles(hObject);

% Gather the folder structure from the FTP site
data = struct2cell(dir(obj.FTP,obj.exp));
idx = cell2mat(data(3,:)); % Only considers folders
str = data(1,idx);
set(hObject,'String',str);

% Update the optics object properties and move to the next folder level
obj.folder = str{get(hObject,'Value')};
callback_type(h.type,[]);

end

%--------------------------------------------------------------------------
function callback_type(hObject,~)
% CALLBACK_TYPE operates when the user selects a type

% Gather the optics object
obj = guidata(hObject);

% Gather the folder structure from the FTP site
thepath = buildpath(obj.exp,obj.folder);
data = struct2cell(dir(obj.FTP,thepath));
idx = cell2mat(data(3,:)); % Only considers folders
str = data(1,idx);
set(hObject,'String',str);

% Update the optics object properties and move to the next folder level
obj.type = str{get(hObject,'Value')};
callback_angle(hObject,[]);

end

%--------------------------------------------------------------------------
function callback_angle(hObject,~)
% CALLBACK_ANGLE operates when angle panel is changed or toggled

% Gather the optics object and GUI handles
obj = guidata(hObject);
h = guihandles(hObject);

% Gather files from current directory if toggle is 'off'
value = get(h.angles,'Value');
if ~value
    set([h.zenith,h.viewer,h.azimuth],'enable','off');
    obj.thepath = buildpath(obj.exp,obj.folder,obj.type); 
    obj.angle = '';
    obj.getFiles;
else
    set([h.zenith,h.viewer,h.azimuth],'enable','on');
    obj.angle = getAngleFolder(h,obj);
    obj.thepath = buildpath(obj.exp,obj.folder,obj.type,obj.angle); 
    obj.getFiles;
end
end

%--------------------------------------------------------------------------
function angle = getAngleFolder(h,obj)
% GETANGLEFOLDER gathers the angle, viewer, zintth folder    
    
thepath = buildpath(obj.exp,obj.folder,obj.type);

data = struct2cell(dir(obj.FTP,[thepath,'/Z*']));
str = char(data(1,:));
Z = unique(cellstr(str(:,2:3)));
set(h.zenith,'String',Z);
z = Z{get(h.zenith,'Value')};

data = struct2cell(dir(obj.FTP,[thepath,'/Z',z,'*']));
str = char(data(1,:));
V = unique(cellstr(str(:,5:6)));
set(h.viewer,'String',V);
val = get(h.viewer,'Value');
if length(V) < val; set(h.viewer,'Value',1); end
v = V{get(h.viewer,'Value')};

data = struct2cell(dir(obj.FTP,[thepath,'/Z',z,'V',v,'*']));
str = char(data(1,:)); 
A = unique(cellstr(str(:,7)));
set(h.azimuth,'String',A);
val = get(h.azimuth,'Value');
if length(A) < val; set(h.azimuth,'Value',1); end
a = A{get(h.azimuth,'Value')};

angle = ['Z',z,'V',v,a];

end

%--------------------------------------------------------------------------
function thepath =  buildpath(varargin)

thepath = varargin{1};
for i = 2:length(varargin);
    if ~isempty(varargin{i});
       thepath = [thepath,'/',varargin{i}]; 
    end
end

end




