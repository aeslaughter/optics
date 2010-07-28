function p = im_HSIlive(obj)
% IM_REGIONPDF is a imObject plugin for computing EPDFS of image regions

% 1 - DEFINE THE PLUGIN AND CALLBACK
p = imPlugin(obj,mfilename);
p.plugintype = {'HSI'};
Callback = @(hObject,eventdata) callback_live(hObject,eventdata,p);

% 2 - DEFINE THE MENU ITEM
p.MenuOrder = 2;
p.MenuParent = 'Hyperspectral';
p.MenuOptions = {'Label','Live Spectrum','Tag','LiveMenu',...
    'Callback',Callback};

% 3 - DEFINE THE TOGGLETOOL BUTTON
p.PushtoolCdata = 'cursor';    
p.PushtoolToggle = true;       
p.PushtoolOrder = 3;            
p.PushtoolOptions = {'ToolTipString','View live spectrum',...
    'ClickedCallback',Callback,'Tag','LiveButton'};% Properties for button

% 4 - DEFINE THE USER PREFERERNCES
p.Pref(1).Value = '5';
p.Pref(1).Label = 'Figure Width (in)';

p.Pref(2).Value = '3';
p.Pref(2).Label = 'Figure Height (in)';

p.Pref(3).Value = true;
p.Pref(3).Label = 'Display coordinates on image';

%--------------------------------------------------------------------------
function callback_live(hObject,~,p)
% CALLBACK_LIVE operates when the user selects the menu or button

% GATHER INFORMATION FROM THE GUI
h = guihandles(hObject);
imObj = guidata(hObject);
M = get(h.LiveMenu,'Checked');

% TOGGLE THE MENUS AND BUTTONS
if strcmpi(M,'off');
    set(h.LiveMenu,'Checked','on');
    set(h.LiveButton,'State','on');
elseif strcmpi(M,'on'); 
    set(h.LiveMenu,'Checked','off');
    set(h.LiveButton,'State','off');
end
    
% RETURN IF THE LIVE VIEWER IS TURNED OFF
B = get(h.LiveButton,'State');
if strcmpi(B,'off'); 
    set(imgcf,'WindowButtonMotionFcn','', 'WindowButtonDownFcn','',...
        'Pointer','arrow');
    return;
end

% IF THE DOES NOT EXIST CREATE THE FIGURE
% fig = get(h.LiveButton,'UserData');
fig = findobj('Name','Live Spectrum');
if isempty(fig) || ~ishandle(fig);
    % Disable figure
    imObj.progress;
    
    % Define the properties
    a.ylabel = 'Brightness';
    a.xlabel = 'Wavelength (nm)';
    a.legend = {'Current Point'};
    a.fontname = 'Times';
    a.name = 'Live Spectrum';
    a.size = [str2double(p.Pref(1).Value),str2double(p.Pref(2).Value)];
    
    % Graph a profile
    X = imObj.info.wavelength;
    Y = squeeze(imObj.image(1,1,:));
    [fig,ax] = XYscatter(X,Y,'advanced',a);
    set(fig,'NextPlot','add','UserData',{},'CloseRequestFcn',...
        @callback_deleteFig);
    
    % Setup the handle for the live view line
    hL = findobj(ax,'Type','Line');
    set(hL,'Tag','LiveLine','Visible','off');
    imObj.addChild(fig); % Adds the figure for saving
    
    % Enable figure
    imObj.progress;
end

% DEFINE THE APPROPRIATE CALLBACKS FOR OPERATING THE LIVE VIEW
set(imgcf,'Units','pixels','WindowButtonMotionFcn',{@callback_mouse,p,false},...
        'Pointer','fullcrosshair','Interruptible','off',...
        'WindowButtonDownFcn',{@callback_mouse,p,true});

%--------------------------------------------------------------------------
function callback_mouse(hObject,~,p,click)
% CALLBACK_MOUSE operates when the mouse is moved and clicked

% GATHER INFORMATION FROM THE GUI
imObj = guidata(hObject);
h = guihandles(hObject);
fig = findobj('Name','Live Spectrum');

% TURN OFF THE LIVE SPECTRUM IF THE FIGURE DOES NOT EXIST
if isempty(fig) || ~ishandle(fig);
    callback_live(h.LiveMenu,[]);
    return;
end

% GATHER THE CURSOR INFORMATION
s = size(imObj.image);          % Image size
c = get(imgca,'CurrentPoint');  % Cursor location
y = round(c(1,1));              % Y-coordinate
x = round(c(1,2));              % X-coordinate

% IF THE CURSOR IS IN THE IMAGE UPDATE THE GRAPH
hfig = guihandles(fig);
if y > 0 && y < s(2) && x > 0 && x < s(1);
    if click
        addPoint(p,x,y)
    else
        Y = squeeze(imObj.image(x,y,:));
        set(hfig.LiveLine,'YData',Y,'Visible','on');
        ylim('auto');
    end
else
    set(hfig.LiveLine,'Visible','off');
end

%--------------------------------------------------------------------------
function addPoint(p,x,y)
% ADDPOINT when the mouse is clicked a point is added to the graph

fig = findobj('Name','Live Spectrum');

hfig = guihandles(fig);
ax = get(hfig.LiveLine,'Parent');

X = get(hfig.LiveLine,'Xdata');
Y = get(hfig.LiveLine,'Ydata');
label = ['X=',num2str(x),',Y=',num2str(y)];

fcn = get(hfig.LiveLine,'ButtonDownFcn');
cline = plot(ax,X,Y,'DisplayName',label,'ButtonDownFcn',fcn);

hline = findobj(ax,'Type','Line');
M = get(hline,'DisplayName');
legend(hline,M);

C = get(cline,'Color');
hp = impoint(imgca,y,x);
hp.setColor(C);

fcn = makeConstrainToRectFcn('impoint',[y,y],[x,x]);
hp.setPositionConstraintFcn(fcn); 

if p.Pref(3).Value;
    hp(end).setString(label);
end

points = get(fig,'UserData');
set(fig,'UserData',[{hp},points]);

%--------------------------------------------------------------------------
function callback_deleteFig(hObject,~)

hp = get(hObject,'UserData');
for i = 1:length(hp); delete(hp{i}); end
delete(hObject)





