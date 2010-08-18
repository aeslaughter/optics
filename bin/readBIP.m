function [data,hdr] = readBIP(varargin)
% READBIP opens *.bip hyperspectral datacubes.
%__________________________________________________________________________
% SYNTAX:
%   [data,hdr] = readBIP;
%   [data,hdr] = readBIP(filename);
%
%  DESCRIPTION:
%   [data,hdr] = readBIP prompts the user for a *.bip or *.bil 
%       hyperspectral file and returns the data in a 3D array and a data 
%       structure containing the header file information. The output array 
%       is sized as: [x-pixel,y-pixel,wavelength].
%   [data,hdr] = readBIP(filename) same as previous but opens the file
%       specified in "filename".
%
% PROGRAM OUTLINE:
% 1 - DEFINE THE FILE TO OPEN
% 2 - READ THE HEADER FILE
% 3 - DETERMINE THE BIP FILE FORMAT
% 4 - READ THE FILE
% 5 - SET THE LOCATION PREFERENCE
% READHEADER extracts the information from the header file.
%__________________________________________________________________________

% 1 - DEFINE THE FILE TO OPEN
    % 1.1 - Collect last used file location
        if ~ispref('readBIP','location');
            addpref('readBIP','location',[cd,'\']);
        end    
        def = getpref('readBIP','location');   
        
    % 1.2 - Select the file to open (if not pr
        if nargin == 0;
            filterspec = {'*.bip;*.bil';'Hyperspectral file (*.bip,*.bil)'};
            head = 'Select *.bip file...';
            [fn,pth] = uigetfile(filterspec,head,def);
            if fn == 0; data = []; hdr = []; return; end
            filename = [pth,fn];
        
        elseif nargin == 1;
            filename = varargin{1};
        else
            errordlg('Too many inputs!','Input Error!');
        end
        
    % 1.3 - Test that the file exists
        if ~exist(filename,'file');
            errordlg(['File ',filename,' does not exist!'],'Input Error!');
        end
        
% 2 - READ THE HEADER FILE
    hdr = readheader(filename);
   
% 3 - DETERMINE THE BIP FILE FORMAT
    switch hdr.dataType
        case 1;  type = 'uint8';    %  8 bit unsigned integers
        case 12; type = 'uint16';   % 16 bit unsigned integers
        case 4;  type = 'single';   % 4 byte floating point (single)
        case 5;  type = 'double';   % 8 byte floating point (double)
        otherwise
            errordlg('The data type is unknown.','File Error!');
            return;
    end

% 4 - READ THE FILE
    % 4.1 - Initilze the storage arrays
        if strcmpi(hdr.interleave,'bil');
            count = [hdr.samples,hdr.bands];
            frame = zeros(hdr.samples,hdr.bands,hdr.lines,type);
            perm = [3,1,2];
        elseif strcmpi(hdr.interleave,'bip');
            count = [hdr.bands,hdr.samples];
            frame = zeros(hdr.bands,hdr.samples,hdr.lines,type);
            perm = [3,2,1];
        end

    % 4.2 - Collect the data 
        fid = fopen(filename,'r');
        for i = 1:hdr.lines;
            frame(:,:,i) = fread(fid,count,type);
        end
        
    % 4.3 - Change the indexing of data     
        data = permute(frame,perm);
        
 % 5 - SET THE LOCATION PREFERENCE
    setpref('readBIP','location',fileparts(filename));
    
%--------------------------------------------------------------------------
function hdr = readheader(filename)
% READHEADER extracts the information from the header file.

% 1 - CHECK THAT HEADER FILE EXISTS
    hdr_file = [filename,'.hdr'];
    if ~exist(hdr_file,'file');
        errordlg(['The header file ',hdr_file,' does not exist!'],...
            'Input Error!');
    end

% 2 - EXTRACT THE DATA FROM THE HEADER FILE
    fid = fopen(hdr_file);
    A = textscan(fid,'%s%s','delimiter','=');
    fclose(fid);

% 3 - CONVERT THE DATA INTO A STRUCTURE
    % 3.1 - Initilize the structure
        hdr = cell2struct(A{2},genvarname(A{1}),1);

    % 3.2 - Convert numeric values from strings        
        fname = fieldnames(hdr);
        for i = 1:length(fname);
            x = str2double(hdr.(fname{i}));
            if ~isnan(x); hdr.(fname{i}) = x; end
        end    
    
    % 3.3 - Convert wavelength in to a column of numerics
        hdr.wavelength = cell2mat(eval(hdr.wavelength))';
