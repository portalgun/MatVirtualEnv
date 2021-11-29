function save(varargin)
    try
        bPrj=numel(varargin) > 0 && VE.isProject(varargin{1}) && numel(dbstack) == 1;
    catch ME
        bPrj=0;
        rethrow(ME)
    end
    builtin('save',varargin{:});
end
