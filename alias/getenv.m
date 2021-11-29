function out=getenv(varargin)
    try
        out=Env.var(varargin);
    catch
        out=builtin('getenv',varargin{:});
    end
end
