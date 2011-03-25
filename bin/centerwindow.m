function centerwindow(h,loc)
% CENTERWINDOW centers dialogs within the imObject window

 p = get(h,'Position'); % Dialog window
 p(1) = loc(1) + loc(3)/2 - p(3)/2; % Horiz. position
 p(2) = loc(2) + loc(4)/2 - p(4)/2; % Vert. position
 set(h,'Position',p); % Reposition
