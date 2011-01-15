function d = waitdlg(varargin)
% WAITDLG opens a windows to prompt the user to please wait
%__________________________________________________________________________
% SYNTAX: 
%   waitdlg
%   waitdlg(Message);
%   waitdlg(Message,ParentWindowPosition)
%__________________________________________________________________________

% Define the default message
if nargin == 0; varargin{1} = 'Please wait...'; end

% Define the window
d = dialog('Units','Normalized','WindowStyle','Normal',...
    'Tag','imObjectProgressWindow','Name','Please wait...',...
    'Position',[0.4,0.475,0.15,0.05]);

% Define the message
annotation(d,'textbox',[0,0,1,1],...
    'String',varargin{1},'HorizontalAlignment','center',...
    'VerticalAlignment','middle');

% Center the dialog in parent window, if desired
if nargin == 2; 
    p = get(d,'Position');
    loc = varargin{2};
    p(1) = loc(1) + loc(3)/2 - p(3)/2;
    p(2) = loc(2) + loc(4)/2 - p(4)/2;
    set(d,'Position',p);
end

% Draw the window and make the window modal
drawnow;
set(d,'WindowStyle','modal');