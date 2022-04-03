function install(prjDir,moveOpt,varargin)
    if nargin < 1
        prjDir='';
    end
    if nargin < 2 || isempty(movOpt)
        moveOpt=0;
    end
    VEInstaller('prjDir',prjDir,num2str(moveOpt),varargin{:});
end
