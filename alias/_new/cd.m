function out =cd(varargin)

    try
        bAuto=VE.getRootOptions('AutoSwitchOnCd');
        bAuto=VE.getRootOptions('AutoSwitchOnCd');
        cur=builtin('get_env','PX_CUR_PRJ_NAME');
        [bIn,prj]=VE.isInPrj(varargin{1}) ;
        bPrj=numel(varargin) > 0 && numel(dbstack) == 1 && bAuto && bIn && ~strcmp(cur,prj);
    catch ME
        bPrj=0;
    end
    out=builtin('cd',varargin{:});
end
function warningon()
    warning('on','MATLAB:dispatcher:nameConflict');
end
