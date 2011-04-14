function r = gatherRegions(type,currentObj,varargin)
% GATHERREGIONS collects and outputs selected work/white regions
%__________________________________________________________________________
% SYNTAX:
%   r = gatherRegions(type,currentObj);
%   r = gatherRegions(type,currentObj,'single');
%__________________________________________________________________________

% 1 - COLLECT THE AVAILBLE IMOBJECTS FROM THE ROOT USER DATA
h = get(0,'UserData');
idx = isvalid(h);
H = h(idx);

% 2 - RETURN THE CURRENT IMOBJECT REGIONS IF PROMPT IS NOT DESIRED
if ~currentObj.regionPrompt;
    r = currentObj.(type);
    return;
end

% 3 - PROMPT THE USER TO SELECT THE REGIONS
R = [H(:).(type)];
if length(R) > 1; % Prompts user
    r = promptUser(R,currentObj.(type),currentObj,varargin{:});
else % Case when only one region is available (don't prompt)
    r = R;
end

%--------------------------------------------------------------------------
function r = promptUser(R,Rcur,currentObj,varargin)
% PROMPTUSER opens a dialog with the available regions

% Deterime the type
    theType = currentObj.type;

% Build a list of the available regions (do not allow mismatch of images)
k = 1;
for i = 1:length(R);
    [~,fn,ext] = fileparts(R(i).parent.filename);
    if any(strcmpi(theType,R(i).parent.type));
        list{k} = [fn,ext,' : ',R(i).label];
        k = k + 1;
    end
end

% Limit selection to a single region
if ~isempty(varargin) && strcmpi(varargin{1},'single');
    themax = 1;
    thevalue = 1; % No items selected
    name = 'Select Region...';
else
    themax = 2;
    name = 'Select Region(s)...';
    
    % Limits selected region to those of the calling image
    for i = 1:length(R); idx(i) = any(R(i) == Rcur); end
    vec = 1:length(list);
    thevalue = vec(idx);
end

% Build the dialog
d = dialog('WindowStyle', 'modal', 'Name',name,...
    'Units','Normalized','Position',[0.45,0.45,0.15,0.15]);
hlist = uicontrol(d,'Style','listbox','String',list,'Units',...
    'Normalized','Position',[0.05,0.25,0.9,0.65],'Max',themax,...
    'Value',thevalue);
uicontrol(d,'Style','Pushbutton','String','OK','Units','Normalized',...
    'Position',[0.8,0.05,0.15,0.15],'Callback','uiresume(gcbf)');
centerwindow(d,currentObj.imposition);
uiwait(d); drawnow;

% Gather the selected regions
if ishandle(hlist);
    val = get(hlist,'Value');
    r = R(val);
    close(d);
else
    r = NaN;
end
