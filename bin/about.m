function about(varargin)


textbox = {'Version: xx.xx';
           'August XX, 2010';
           'Designed by: Andrew E. Slaughter (andrew.e.slaughter@gmail.com)';
           'http://github.com/aeslaughter/optics'};
       
fid = fopen('license.txt','r');       
lic = textscan(fid,'%s','delimiter','\n'); lic = lic{1};
fclose(fid);

for i = 1:length(lic);
    L(i) = length(lic{i});
end
w = max(L);
h = length(lic);

d = dialog('Units','Normalized','Position',[0.375,0.3,0.25,0.4],'Name',...
    'Snow Optics Toolbox','WindowStyle','Normal');
annotation(d,'textbox',[0.01,0.88,0.98,0.1],'String','Snow Optics Toolbox',...
    'FontSize',10,'EdgeColor','none','FontWeight','Bold');
annotation(d,'textbox',[0.01,0.76,0.98,0.18],'String',textbox,...
    'FontSize',9,'EdgeColor','none','VerticalAlignment','top');
annotation(d,'textbox',[0.01,0.01,0.98,0.74],'String',lic,'FontSize',8);

