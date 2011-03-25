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

p.Pref(2).Value = '10';
p.Pref(2).Label = 'Alpha Value (%)';

p.Pref(3).Value = '1000';
p.Pref(3).Label = 'Bootstrap Re-samplings';

p.Pref(4).Value = false;
p.Pref(4).Label = 'Write results to Excel worksheet';

%--------------------------------------------------------------------------
function callback_gof(hObject,~,obj,p)
% CALLBACK_GOF compares the two regions of interest

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
    rgb = p.Pref(1).Value;
    alpha = str2double(p.Pref(2).Value);
    nboot = str2double(p.Pref(3).Value);
    exl = p.Pref(4).Value;
    
% 3 - SEPERATE THE DESIRED DATA
    % 3.1 - Loop through each of the regions
    for i = 1:length(R)
        mask = R(i).getRegionMask;
        I = getImage(R(i).parent);
        if ~rgb
            I = mean(I,2);
        end
        x{i} = I(mask,:);
        n{i} = size(x{i},1);
        if n{i} > 10000; nn{i} = 10000; else nn{i} = n{i}; end
        name{i} = [R(i).type,'-',R(i).label];
        [~,fn,ext] = fileparts(R(i).parent.filename);
        fname{i} = [fn,ext];
    end
    
    % 3.2 - Build the output name
    if strcmp(fname{1},fname{2});
        outname = fname{1};
    else
        outname = [fname{1},' : ',fname{2}];
    end
    
% 4 - COMPARE THE MEANS OF THE SAMPLE
    N = size(x{1},2);
    h = waitdlg('Comparing regions, please wait...',...
            get(imObj.imhandle,'position'));
    for i = 1:N;        
        % 4.1 - Re-assign current image vector
        x1 = x{1}(:,i);
        x2 = x{2}(:,i); 
        
        %4.2 - Build random samples
        R1 = randi(n{1},[nn{1},nboot]);
        R2 = randi(n{2},[nn{2},nboot]);
        X1 = x1(R1);
        X2 = x2(R2);

        % 4.3 - Perform bootstrap on mean and standard deviation
        PDM = abs(2*(mean(x1) - mean(x2))/(mean(x1) + mean(x2)))*100;
        MN = mean(X2) - mean(X1);
        PDS = abs(2*(std(x1)./mean(x1) - std(x2)./mean(x2))...
            /(std(x1)./mean(x1) + std(x2)./mean(x2)))*100;
        SD = std(X2)./mean(X2) - std(X1)./mean(X1); 
        ci1 = prctile(MN,[alpha/2,100-alpha/2]);
        ci2 = prctile(SD,[alpha/2,100-alpha/2]);
        
        % 4.4 - Test for normality  of mean via chi squared    
        [H,p1] = chi2gof(MN);
        if H; chi1 = 'Non-normal';
        else chi1 = 'Normal';
        end   
        
        % 4.5 - Test for normality  of std via chi squared    
        [H,p2] = chi2gof(SD);
        if H; chi2 = 'Non-normal';
        else chi2 = 'Normal';
        end   

        % 4.6 - Build output
        if N > 1;
            theoutname = [outname,' (',num2str(i),')'];
        else
            theoutname = outname;
        end
        region = [regexprep(name{1},' ',''),' : ',...
            regexprep(name{2},' ','')];
        
        labels = {'Filename','Regions',...
            'Mean-1', 'COV-1',...
            'Mean-2', 'COV-2',...           
            '% Diff. Means', '% Diff. COV',...
            'Mean C.I. (high)', 'Mean C.I. (low)',...
            'COV C.I. (high)', 'COV C.I. (low)',...
            'Chi^2 p-value (mean)','Chi^2 (mean)',...
            'Chi^2 p-value (COV)','Chi^2 (COV)'};
        output(i,:) = {theoutname, region,...
            mean(x1), std(x1),...
            mean(x2), std(x2),...
            PDM, PDS,...
            ci1(1), ci1(2),...
            ci2(1), ci2(2),...
            p1, chi1,...
            p2, chi2}; 
    end
    close(h);

% % 5 - REPORT RESULTS 
    if ~exl; % Case when printing to the screen
        for i = 1:size(output,1);
            cur = output(i,:);
            for j = 1:length(cur);
                disp([labels{j},': ',num2str(cur{j})]);
            end
            disp(' ');
        end
    else % Case when output is written to excel
        exceloutput(imObj,labels,output);
    end

%--------------------------------------------------------------------------
function exceloutput(imObj,L,data)

filename = gatherfile('put','gofxlsfile',{'*.xlsx','Excel 2007 (*.xlsx)'});
if isempty(filename); return; end;

[~,fname,ext] = fileparts(imObj.filename);
sheet = [fname,ext];

A = false;
if exist(filename,'file');
    [~,sheets] = xlsfinfo(filename);
    if any(strcmp(sheet,sheets)); 
        A = true;
    end
end

if A
    [~,~,raw] = xlsread(filename,sheet);
    raw = [raw,data'];
    xlswrite(filename,raw,sheet,'A1');
else
    xlswrite(filename,L',sheet,'A1');
    xlswrite(filename,data',sheet,'B1');
end




    












    
    
