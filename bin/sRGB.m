function output = sRGB(data,type)
% sRGB converts between sRGB and 1931 CIE XYZ

% Convert the image into single precision data
data = single(data);

% Re-size the data into columns of pixels (only if not already done)
N = ndims(data);
if N == 3;
    [m,n,p] = size(data);
    data = reshape(data,m*n,p);
end

% Perform the conversions
if strcmpi(type,'CIE');
    output = buildXYZ(data);
elseif strcmpi(type,'sRGB');
    output = buildCIE(data);
end

% Return to original size, if needed
if N == 3;
    output = reshape(output,m,n,p);
end

%--------------------------------------------------------------------------
function RGB = buildCIE(data)
% BUILDXYZ converts CIE to sRGB

% Establish waitbar
h = waitbar(0,'Converting image to sRGB format, please wait...');

% Perform matrix calcuation, Equation (6)
M = [3.2406 -1.5372,-0.4986; -0.9689,1.8758,0.0415; 0.0557 -0.2040,1.057];
RGB = zeros(size(data));
N = length(RGB)
for i = 1:N;    
    RGB(i,:) = M*data(i,:)';
    waitbar(i/N,h);
end

% Define the indices for computing 
a = 0.055;
ix1 = RGB <= 0.0031308;
ix2 = RGB > 0.0031308;

% Apply Equations (7) and (8)
RGB(ix1) = RGB(ix1).*12.92;
RGB(ix2) = 1.055.*data(ix2).^(1/2.4) - 0.055;

% Convert the image to values to 8bit data
 RGB = RGB./255;
close(h);

%--------------------------------------------------------------------------
function XYZ = buildXYZ(data)
% BUILDXYZ converts sRGB to CIE

% Establish waitbar
h = waitbar(0,'Converting image to sRGB format, please wait...');

% Convert the image to values from 0 to 1
mx = max(reshape(data,numel(data),1));
if mx > 1;
    data = data./255;
end

% Define the indices for computing 
a = 0.055;
ix1 = data <= 0.04045;
ix2 = data > 0.04045;

% Apply Equations (3) and (4)
data(ix1) = data(ix1)./12.92;
data(ix2) = ((data(ix2) + a)./(1+a)).^2.4;

% Perform matrix calculation, Equation (5)
M = [0.4124,0.3576,0.1805; 0.2126,0.7152,0.0722; 0.0193,0.1192,0.9505];
XYZ = zeros(size(data));
N = length(data);
for i = 1:N;    
    XYZ(i,:) = M*data(i,:)';
    waitbar(i/N,h);
end
close(h);