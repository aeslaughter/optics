function p = gof(obj)
% GOF is a imObject plugin for computing the goodness of fit of two regions

% DEFINE THE MENUS
p = imPlugin(obj,mfilename);
p.plugintype = {'VIS','NIR'};

p.MenuOrder = 4;
p.MenuParent = 'Analysis';
Callback = @(hObject,eventdata) callback_gof(hObject,eventdata,obj,p);
p.MenuOptions = {'Label','Goodness-of-Fit'};

p.MenuSubmenu{2} = {'Label','White','callback',Callback};
p.MenuSubmenu{1} = {'Label','Work','callback',Callback};

% DEFINE THE PLUGIN PREFERENCES
p.Pref(1).Value = false;
p.Pref(1).Label = 'Seperate RGB Colors or XYZ components';

%--------------------------------------------------------------------------
function callback_gof(hObject,~,obj,p)
% CALLBACK_GOF

% 1 - GATHER THE REGIONS
    imObj = guidata(hObject);
    type = lower(get(hObject,'Label'));
    R = gatherRegions(type,obj);
    if isempty(R) || length(R) < 2; 
        mes = ['At least two "',type,'" regions must exist!'];
        warndlg(mes,'Warning!');
        return;
    elseif isnumeric(R) && isnan(R);
        return;
    end
        
    if length(R) ~= 2; 
        mes =  ['Exactly two "',type,'" regions must be selected.'];
        warndlg(mes,'Warning!');
        return;
    end
    
% 2 - GATHER THE OPTIONS
    opt.rgb = p.Pref(1).Value;
    
% 3 - PERFORM GOODNESS-OF-FIT
    % 3.1 - Seperate the data
    for i = 1:length(R)
        mask = R(i).getRegionMask;
        I = getImage(R(i).parent);
        if ~opt.rgb
            I = mean(I,2);
        end
        x{i} = I(mask,:)
    end
B = 10;
 fcn = @(x1,x2) mean(x2) - mean(x1);   
 m1 = bootstrp(B,@mean,x{1})
 m2 = bootstrp(B,@mean,x{2})
 ci = prctile(abs(m2-m1),[5,95])
    
    
    
    
    
% b = 1:0.05op:log10(min(length(x{1}),length(x{2})));
% B = floor(10.^b);
% for i = 1:size(I,2);
%     for j = 1:length(B);
%         j/length(B)
%         for k = 1:50
%             x1 = randsample(x{1}(:,i),B(j));    
%             x2 = randsample(x{2}(:,i),B(j));  
%             [~,Pk(k),~] = kstest2(x1,x2);
%         end
%         P(j) = mean(Pk);
%     end
% end
% figure; plot(B,P);
% set(gca,'xscale','log');
% %     
% X = 0:255;
% [~,p1] = buildpdf(x{1},X);
% [~,p2] = buildpdf(x{2},X);
% figure; bar(X',[p1',p2'],1.15,'grouped'); hold on;
%     
    
    