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
    r = promptUser(R);
else % Case when only one region is available (don't prompt)
    r = R;
end

%--------------------------------------------------------------------------
function r = promptUser(R)
% PROMPTUSER opens a dialog with the available regions

% Build a list of the available regions
for i = 1:length(R);
    [~,fn,ext] = fileparts(R(i).parent.filename);
    list{i} = [fn,ext,' : ',R(i).label];
end

% Build the dialog
d = dialog('WindowStyle', 'modal', 'Name', 'Select Region(s)...',...
    'Units','Normalized','Position',[0.45,0.45,0.15,0.15]);
hlist = uicontrol(d,'Style','listbox','String',list,'Units',...
    'Normalized','Position',[0.05,0.25,0.9,0.65],'Max',2,...
    'Value',1:length(list));
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
