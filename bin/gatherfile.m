function filename = gatherfile(type,pref,spec,varargin)
% GATHERFILE gets files for reading or saving
%__________________________________________________________________________
% SYNTAX:
%   filename = gatherfile(type,pref,spec)
%   filename = gatherfile(type,pref,spec,varargin)
%
% DESCRIPTION:
%
%__________________________________________________________________________

% PROMPT THE USER FOR A FILENAME
if isempty(varargin) || isempty(varargin{1}); % Case w/o filename set
    % Determine the last used directory
    if ispref('imobject',pref);
        def = getpref('imobject',pref);
    else
        def = cd;
    end
    
    % Account for bad directory entries
    if ~ischar(def); def = cd; end
    
    % Prompt the user for a file
    if strcmpi(type,'get'); % Opening a file
        [name,pth] = uigetfile(spec,'Select image...',def);
    elseif strcmpi(type,'put'); % Saving a file
        [name,pth] = uiputfile(spec,'Save as...',def);
    elseif strcmpi(type,'dir'); % Getting a folder
        [pth] = uigetdir(def,'Select folder...');
        name = '';
    end

    % Check that the cancel buttons was not pushed
    if isnumeric(name); filename = ''; return; end

    % Build the complete filename and store the directory
    filename = fullfile(pth,name);
    setpref('imobject',pref,pth);    

% CHECK THAT THE DESIRE FILE EXISTS ("get" user provided file only)
elseif strcmpi(type,'get');
    filename = varargin{1};
    if ~exist(filename,'file'); 
        error('gatherfile.m','File does not exist.'); 
    end  

% RETURN THE FILENAME ("put" with a user provided file)
else
    filename = varargin{1};
    if exist(filename,'file');
        ans = questdlg('Overwrite exiting file?','Overwrite...',...
            'Yes','Cancel','Cancel');
        if strcmpi(ans,'cancel'); filename = []; end
    end
end
