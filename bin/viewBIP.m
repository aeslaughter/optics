function varargout = viewBIP(varargin)
% VIEWBIP opens a "true-color" image of a hyperspectral datacube.
%__________________________________________________________________________
% SYNTAX:
%   viewBIP;
%   viewBIP(filename);
%   viewBIP(data,hdr);
%   [data,hdr] = viewBIP(...);
%   [data,hdr,fighandle] = viewBIP(...);
%   C = viewBIP(...);
%__________________________________________________________________________

% 1 - READ DATA/FILE
    if nargin == 1 && ischar(varargin{1})
        [data,hdr] = readBIP(varargin{:});
    elseif nargin == 2;
        data = varargin{1}; hdr = varargin{2};
    else
        error('Inproper input!');
    end
    if isempty(data); return; end

% 2 - ASSGIN RBG WAVELENGTHS
    w{1} = [620,750];
    w{2} = [ceil(min(hdr.wavelength)),495];
    w{3} = [495,570];
    
% 3 - EXTRACT THE RBG DATA
    for i = 1:length(w);
        C(:,:,i) = wavelengthBIP(data,hdr,w{i});
    end
    
% 4 - ADJUST IMAGE FOR RAW INPUT
    if isfield(hdr,'reflectanceScaleFactor');
        C = C/hdr.reflectanceScaleFactor;
    elseif max(max(C)) - min(min(C)) > 100;
        C = C/4095;
    end
    
% 6 - OPEN OR RETURN THE IMAGE   
    if nargout == 1;
        varargout{1} = C;
    else
        fig = imtool(C);
        varargout = {data,hdr,fig};
    end
    