function ImageInfo
% ImageInfo gathers camera settings for the images in a directory

pth = 'database\2010-06-22 Rad Rec\Initial\VIS\';
outpth = 'C:\Users\pigpen\Documents\MSUResearch\optics\results\';
outname = 'RG3-imagedata.xlsx';
folders = dir(pth);

for i = 1:length(folders)
    cur = folders(i).name;
    if strcmpi(cur(1),'.') || ~isdir([pth,cur]); continue; end
    
    jpg = dir([pth,folders(i).name,filesep,'*.jpg']);
    
    E = {'Filename'; 'Exposure'; 'Fnumber'; 'ISO'};
    for j = 1:length(jpg);
        info = imfinfo([pth,folders(i).name,filesep,jpg(j).name]);
        T = info.DigitalCamera.ExposureTime;
        N = info.DigitalCamera.FNumber;
        S = info.DigitalCamera.ISOSpeedRatings;
        
        E{1,j+1} = jpg(j).name;
        E{2,j+1} = T;
        E{3,j+1} = N;
        E{4,j+1} = S;
        E{5,j+1} = N^2*12.5 / (T * S);
    end
    
    xlswrite([outpth,outname],E,cur);
    
    
end
    