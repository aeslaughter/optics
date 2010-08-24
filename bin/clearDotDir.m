function clearDotDir(dotdir)
% CLEARDOTDIR removes dotdir

% CLEAR FIG FILES FROM THE DIRECTORY
if exist(dotdir,'dir');
    fig = dir([dotdir,filesep,'*.fig']);
    for i = 1:length(fig);
        delete([dotdir,filesep,fig(i).name]);
    end
end

% REMOVE THE FOLDER, IF IT IS EMPTY
[stat,~,id] = rmdir(dotdir);
if stat;
    mes = ['The hidden workspace directory (',dotdir,')',...
        ' was not removed, it was not empty.'];
    warning(id,mes);
end
