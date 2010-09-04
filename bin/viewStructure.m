function viewStructure(S,name)
% VIEWSTRUCTURE opens a table for displying image information
%__________________________________________________________________________
% SYNTAX: 
%   viewStructure(S,name);
%__________________________________________________________________________

% 1 - DEFINE THE WINDOW AND TABLE FOR DISPLAYING DATA
% 1.1 - Define the dialog window
fig = dialog('Name',[name,' Information'],'Units','Normalized',...
    'Position',[0.3,0.3,0.2,0.4],'WindowStyle','Normal');
guidata(fig,S);

% 1.2 - Define the table
tbl = uitable(fig,'Units','Normalized','Position',[0.05,0.05,0.9,0.9]);
set(tbl,'ColumnName',{'Property';'Value'},'RowName',[],'Units','Pixels',...
    'CellSelectionCallback',{@callback_select,name});
P = get(tbl,'Position');

% 1.3 - Define the export menu item
m = uimenu(fig,'Label','File');
uimenu(m,'Label','Export to workspace','Callback',@callback_export);

% 2 - PREPARE THE STRUCTURE DATA FOR THE TABLE
props = fieldnames(S); % Titles
vals = struct2cell(S); % Values

% Loop through each of the values and address special conditions
for i = 1:length(vals);
    V = vals{i};
    if isstruct(V); % Structure (opens a new viewer when clicked)
       vals{i} = class(V); 
    elseif iscell(V) && isempty(V); % Empty cell array changed to char
       vals{i} = '';
    elseif isnumeric(V); % Numerics are displayed as strings
       vals{i} = mat2str(V);
    end
end

% Insert the data into the table
set(tbl,'Data',[props,vals],'ColumnWidth',{0.3*P(3),0.65*P(3)});

%--------------------------------------------------------------------------
function callback_select(hObject,eventdata,name)
% CALLBACK_SELECT operates when a cell is selected.

% Gather the data from the GUI
S = guidata(hObject);
fn = fieldnames(S);
ind = eventdata.Indices(1);
item = S.(fn{ind});

% Display the selected data and open a new viewer for structures
disp(item);
if isstruct(item);
    viewStructure(item,[name,' ',fn{ind}]);
end

%--------------------------------------------------------------------------
function callback_export(hObject,~)
% CALLBACK_EXPORT operates when the export menu is selected
user = inputdlg('Workspace variable name:','Export...',1,{'info'});
if isempty(user); return; end
assignin('base',user{1},guidata(hObject));
