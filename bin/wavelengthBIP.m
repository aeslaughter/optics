function output = wavelengthBIP(data,hdr,lambda)
% WAVELENGTHBIP extracts average data from the specific wavelengths

% 1 - CHEKC THE INPUT
    W = hdr.wavelength;

% 2 - COLLECT DATA
    % 2.1 - Scalar input returns an interpolated value
    if isscalar(lambda);
        idx = find(W < lambda,1,'last');
        slope = (data(:,:,idx+1) - data(:,:,idx))/(W(idx+1) - W(idx));
        output = data(:,:,idx) + (W(idx+1) - lambda)*slope;

    % 2.2 - A range of wavlenghts returns an average value    
    else
        idx1 = find(W <= lambda(1),1,'last');
        idx2 = find(W >= lambda(2),1,'first');
        temp = data(:,:,idx1:idx2);
        output = mean(temp,3);
    end