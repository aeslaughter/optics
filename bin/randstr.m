function s = randstr(k)
% RANDOMSTRING creates a random string of characters of length k
C = char([48:57,65:90,97:122]);
idx = randsample(length(C),k,true);
s = C(idx);