function r = gatherRegions(type,currentObj)
% GATHERREGIONS collects and outputs selected work/white regions
%__________________________________________________________________________
% SYNTAX:
%   r = gatherRegions(type,currentObj);
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
    r = promptUser(R,currentObj.(type),currentObj.type);
else % Case when only one region is available (don't prompt)
    r = R;
end

%--------------------------------------------------------------------------
function r = promptUser(R,Rcur,theType)
% PROMPTUSER opens a dialog with the available regions

% Build a list of the available regions (do not allow mismatch of images)
k = 1;
for i = 1:length(R);
    [~,fn,ext] = fileparts(R(i).parent.filename);
    if any(strcmpi(theType,R(i).parent.type));
        list{k} = [fn,ext,' : ',R(i).label];
        k = k + 1;
    end
end

% By default only the regions in the calling imObject are used
for i = 1:length(R); idx(i) = any(R(i) == Rcur); end
vec = 1:length(list);

% Build the dialog
d = dialog('WindowStyle', 'modal', 'Name', 'Select Region(s)...',...
    'Units','Normalized','Position',[0.45,0.45,0.15,0.15]);
hlist = uicontrol(d,'Style','listbox','String',list,'Units',...
    'Normalized','Position',[0.05,0.25,0.9,0.65],'Max',2,...
    'Value',vec(idx));
uicontrol(d,'Style','Pushbutton','String','OK','Units','Normalized',...
    'Position',[0.8,0.05,0.15,0.15],'Callback','uiresume(gcbf)');
uiwait(d);

% Gather the selected regions
if ishandle(hlist);
    val = get(hlist,'Value');
    r = R(val);
    close(d);
else
    r = NaN;
end
