%function DrawChart

xls = 'C:\Users\pigpen\Documents\MSUResearch\optics\results\results.xlsx';

% Brightness Graphs
if true
    xy_work = xlsread(xls,'bright-work','B3:K4')';
    xy_white = xlsread(xls,'bright-white','B3:K4')';
    L = xlsread(xls,'bright-work','B12:K12')';
    clear a
    a.legend = {'x (work)', 'y (work)', 'x (white)', 'y (white)'};
    a.xlabel = 'Luminance (cd\cdotm^{-1})';
    a.ylabel = 'x and y values';
    a.interpreter = 'tex';
    a.fontsize = 10;
    a.fontname = 'Times';
    a.size = [3.25,2.5];
    a.tight = 'on';
    a.markersize = 5;
    a.linespec = {'sk','ok','sb','ob'};
    a.linewidth = 2;
    XYscatter(L,xy_work,L,xy_white,'advanced',a);
    
    N = xy_work ./ xy_white;
    a.ylabel = 'x* and y* values';
    a.linespec = {'sk','ok'};
    a.legend = {'x*','y*'};
    
    a.ylim = [0.995,1.02]; 
    a.ystep = 0.005;
    XYscatter(L,N,'advanced',a);
end  
    
% Teflon
if false
    x = xlsread(xls,'white-data','B3:W3')';
    y = xlsread(xls,'white-data','B4:W4')'
    L = xlsread(xls,'white-data','B12:W12')';
    [~,ix] = sort(L);

    [xu,xs] = normfit(x);
    [yu,ys] = normfit(y);
    xx = (0.33:0.0001:0.36)';
    X = normpdf(xx,xu,xs);
    Y = normpdf(xx,yu,ys);
    XYscatter(xx,[X,Y])
%     (max(x) - min(x))/mean(x) * 100
%     (max(y) - min(y))/mean(y) * 100
end

if false;
    L = xlsread(xls,'bright-white','B12:K12')';
    x = xlsread(xls,'bright-white','B3:K3')';
    y = xlsread(xls,'bright-white','B4:K4')';

    [px,Sx] = polyfit(log(L),x,1);
    [py,Sy] = polyfit(log(L),y,1);
    fx = polyval(px,log(L));
    fy = polyval(py,log(L));

    [~,xci] = polyconf(p,log(L),Sx,'alpha',0.05);
    [~,yci] = polyconf(p,log(L),Sx,'alpha',0.05);

    eqx = ['x = ',num2str(px(1)),'L + ',num2str(px(2))]
    mean(xci./fx)*100
    eqy = ['y = ',num2str(py(1)),'L + ',num2str(py(2))]
    mean(yci./fy)*100

    a.linespec = {'or','sb','-r','-b'};
    a.linewidth = 1;
    a.markersize = 5;
    a.size = [3.25,2.5];
    a.fontsize = 10;
    a.xlabel ='ln(L)';
    a.ylabel = 'x and y';
    a.tight = 'on';

    XYscatter(log(L),[x,y,fx,fy],'advanced',a);

    Lci = log([L(1); L; L(end); flipud(L)]);
    Xci = [fx(1) - xci(1); fx + xci; fx(end) - xci(end); flipud(fx - xci)];
    Yci = [fy(1) - yci(1); fy + yci; fy(end) - yci(end); flipud(fy - yci)];
    hold on;
    patch(Lci,Xci,'r','EdgeColor','none','FaceAlpha',0.25);
    patch(Lci,Yci,'b','EdgeColor','none','FaceAlpha',0.25);

    h = findobj(gca,'Type','line');
    legend(h(1:2),{'x','y'});
    axis auto;
end

