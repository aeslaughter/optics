function d = waitdlg(varargin)
% WAITDLG opens a windows to prompt the user to please wait

% Define the default message
if nargin == 0; varargin{1} = 'Please wait...'; end

% Define the window
d = dialog('Units','Normalized','WindowStyle','Normal',...
    'Tag','imObjectProgressWindow','Name',...
    'Please wait...','Position',[0.4,0.475,0.15,0.05]);
a = annotation(d,'textbox',[0,0,1,1],...
    'String',varargin{1},'HorizontalAlignment','center',...
    'VerticalAlignment','middle');
drawnow;
set(d,'WindowStyle','modal');