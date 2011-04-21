function [M,ci,v] = computeRegionMeanCI(R,nboot,alpha,rgb)
% COMPUTEREGIONMEAN

% 3.1 - Loop through each of the regions
for i = 1:length(R)
    mask = R(i).getRegionMask;
    I = getImage(R(i).parent);
    if ~rgb
        I = mean(I,2);
    end
    x = I(mask,:);
    n = size(x,1);
    if n > 10000; nn = 10000; else nn = n; end

    N = size(x,2);
    for j = 1:N;  
        M(i,j) = mean(x(:,j));

        xx = x(:,j);
        r = randi(n,[nn,nboot]);
        X = xx(r);

        ci(i,j,:) = prctile(mean(X),[alpha/2,100-alpha/2]);
        v(i,j) = abs(diff(ci(i,j,:))/2);
    end
end