classdef VE < handle
methods(Static,Hidden)
    function help()
        % TODO
    end
%% INSTALL
    function startup()
        VE('startup');
    end
    function recompileBase()
        VE('self','bMBTRecompile',true);
    end
    function installVE(varargin)
        VE('installPx',varargin{:});
    end
    function reinstallVE(varargin)
        VE('reinstallPx',varargin{:});
    end
    function uninstallVE(varargin)
        VE('uninstallPx',varargin{:});
    end
    function varargout=runAsVE(varargin)
        obj=VE('run',varargin{:});
        [varargout{1:nargout}]=obj.OUT{:};
    end
end
methods(Static)
%% PROJECTS
    function root_config()
        VE.edit_([],'root');
    end
    function env()
        VE.edit_([],'env');
    end
    function config()
        VE.edit_([],'etc');
    end
    function deps()
        VE.edit_([],'prj');
    end
    function todo()
        VE.edit_([],'todo');
    end
    function notes()
        VE.edit_([],'notes');
    end
    function list()
        dire=builtin('getenv','PX_PRJS_ROOT');
        out=VE.get_projects(dire)';
        disp(strjoin(out,newline));
    end
    function initAllProjects()
        % TEST
        VE('all');
    end
    function [out,prj]=isInPrj(dire)
        dire=FilDir.resolve(dire); %% XXX NEEDS TO RUN AS
        prjsdire=builtin('getenv','PX_PRJS_ROOT');
        prjsdire=FilDir.resolve(prjsdire); %% XXX NEEDS TO RUN AS
        out=contains(dire,prjsdire);
        if nargout > 1  && out
            spl=strsplit(strrep(dire,prjsdire,''),filesep);
            prj=spl{2};
        elseif nargout > 1
            prj=[];
        end
    end
    function out=isProject(prj)
        dire=builtin('getenv','PX_PRJS_ROOT');
        PRJS=VE.get_projects(dire);
        out=ismember(prj,PRJS);
    end
%% PRJ
    function switchPrj(prj)
        if nargin < 1; prj=[]; end
        VE('switch','prj',prj);
    end
    function out=getRootOptions(varargin)
        obj=VE('get_root_options',varargin{:});
        out=obj.OUT;
    end
    function out=getOptions(varargin)
        obj=VE('get_options',varargin{:});
        out=obj.OUT;
    end
    function out=lsDeps(prj)
        if nargin < 1; prj=[]; end
        VE('ls_deps','prj',prj);
    end
    function rename(prj)
        % TODO
        if nargin < 1; prj=[]; end
        obj=VE('rename','prj',prj);
    end
%% CURRENT PRJ
    function reload()
        VE('reset');
    end
    function runHook()
        % TODO
        obj=VE('run_hook');
    end
    function prj=compile()
        % XXX TODO
    end
    function out=name()
        out=getenv('PX_CUR_PRJ_NAME');
    end
    function out=getName()
        out=getenv('PX_CUR_PRJ_NAME');
    end
    function out=getDir()
        out=getenv('PX_CUR_PRJ_DIR');
    end
%% ENV
    function out=getEnv()
        obj=VE('get_env');
        out=obj.OUT;
    end
    function out=lsEnv()
        obj=VE('ls_env');
    end
%% WORKSPACES
    function obj=saveWS()
        VE.save_workspace();
    end
    function obj=loadWS()
        VE.workspace_fun('load',false);
    end
    function obj=loadLastWS()
        VE.workspace_fun('load',true);
    end
    function obj=deleteWS()
        VE.workspace_fun('delete',false);
    end
end
properties(Access={?Px,?PxInstaller,?BaseInstaller,?PxBaseUnInstaller,?PxUnInstaller,?PxPrjOptions})
    args
    opts
    Px
    PxI
    PxU
    PxB
    mode
    exitflag={'',''}

    bTest=false
    installDir
    rootDir
    bootDir
    libDir
    binDir
    intDir

    diaryFile
    envFile
    lastSavedWrk

    lastPath
    lastDir
    bRestoreOnCl=false

    selfPath
    selfSrcPath
    aliasPath
    basePath

    bSuccess
    OUT
end
properties(Constant,Access=private)
   MODES={'self','run','ls_env','get_env','ls_deps','get_options','get_root_options'}
   CRITFILES={'VE.m','src','alias'}
end
methods(Access=private)
    function obj=VE(mode,varargin)
        if nargin < 1
            mode=[];
        end
        obj.mode=mode;

        % INTIALIZE PATH

        obj.get_self_path();
        obj.lastDir=builtin('cd',obj.selfPath);
        cl=onCleanup(@() obj.restore_path_on_cl());
        obj.create_empty_path();
        obj.add_self_path();

        obj.parse_args(varargin{:});

        % INITIALIZE INSTALL DIRS
        obj.PxI=PxInstaller(obj);
        % INSTALL BASETOOLS, ADD TO PATH
        obj.PxB=BaseInstaller(obj);
        obj.basePath=obj.PxB.mbDir;

        obj.parse_mode();


        if ismember(obj.mode,VE.MODES)
            obj.mode_selector();
        elseif strcmp(obj.mode,'reinstallPx')
            obj.PxU=PxBaseUnInstaller(obj);
            obj.PxI.mode_handler();
        elseif ismember(obj.mode,PxUnInstaller.MODES);
            obj.PxU=PxBaseUnInstaller(obj);
        elseif ismember(obj.mode,PxInstaller.MODES);
            obj.PxI.mode_handler();
        elseif ~obj.PxI.bInstalled
            error('VE not installed');
        else
            obj.Px=Px(obj);
        end

        % NOTE: unless specified
        switch obj.exitflag{1}
        case ''
            obj.bRestoreOnCl=false;
            VE.persist(obj);
            rmpath(obj.selfSrcPath);
            % rmpath(obj.basePath); XXX if symlinked &, will remove mb if dep
            rmpath(obj.binDir);
        end
    end
    function obj= mode_selector(obj)
        obj.exitflag={'restore',''};
        switch obj.mode
        case 'self'
             ;
        case 'run'
            n=nargout(obj.args{1});
            obj.OUT=cell(1,n);
            [obj.OUT{1:n}]=feval(obj.args{:});
        case 'ls_env'
            obj.ls_env();
        case 'get_env'
            obj.get_env();
        case 'ls_deps'
            ve=VE.persist();
            disp(ve.Px.tbl);
        case 'get_options'
            ve=VE.persist();
            obj.OUT=ve.Px.Opts;
            if numel(obj.args) == 1
                obj.OUT=obj.OUT{obj.args{1}};
            elseif numel(obj.args) > 1
                obj.OUT(args{:});
            end
        case 'get_root_options'
            ve=VE.persist();
            obj.OUT=ve.Px.rootOpts;
            if numel(obj.args) == 1
                obj.OUT=obj.OUT{obj.args{1}};
            elseif numel(obj.args) > 1
                obj.OUT(args{:});
            end
        end

    end

    function obj=parse_mode(obj)
        if isempty(obj.mode) && ~obj.PxI.bInstalled
            obj.mode='installPx';
        end
        valModes=[VE.MODES Px.MODES PxInstaller.MODES BaseInstaller.MODES];
        if ~isempty(obj.mode) && ~ismember(obj.mode,valModes)
            error(['Invalid VE Mode: ' obj.mode]);
        end
    end
    function obj=parse_args(obj,varargin)
        if ismember(obj.mode,{'run','get_options','get_root_options'})
            obj.args=varargin;
        else
            obj.args=struct(varargin{:});
        end
        if isfield(obj.args,'installDir')
            obj.installDir=obj.args.installDir;
            if ~endsWith(obj.installDir,filesep);
                obj.installDir=[obj.InstallDir filsep];
            end
            obj.args=rmfield(obj.args,'installDir');
        elseif ~exist([obj.selfPath '.git'],'dir')
            obj.installDir=PxUtil.parent(PxUtil.parent(obj.selfPath));
        else
            error('No Install directory provided');
        end

        %obj.rootDir=[obj.installDir '.px' filesep];
        obj.rootDir=[PxUtil.parent(obj.selfPath)];
        obj.bootDir=[obj.rootDir 'boot' filesep];
        obj.libDir=[obj.bootDir 'lib' filesep];
        obj.binDir=[obj.bootDir 'bin' filesep];
        obj.intDir=[obj.bootDir '.internal' filesep];
        obj.envFile=[obj.intDir 'env'];
        obj.diaryFile=[obj.intDir 'log'];
        obj.lastSavedWrk=[obj.intDir 'last_saved_wrk'];
        if isfield(obj.args,'bTest')
            obj.bTest=obj.args.bTest;
            obj.args=rmfield(obj.args,'bTest');
        end
        if isfield(obj.args,'bMBTRecompile')
            obj.opts.bMBTRecompile=obj.args.bMBTRecompile;
            obj.args=rmfield(obj.args,'bMBTRecompile');
        else
            obj.opts.bMBTRecompile=false;
        end
    end
    function obj=restore_path_on_cl(obj)
        warning('on','MATLAB:dispatcher:nameConflict');
        if obj.bRestoreOnCl
            path(obj.lastPath);
            builtin('cd',obj.lastDir);
        end
    end
    function create_empty_path(obj);
        obj.lastPath=path;
        obj.bRestoreOnCl=true;
        restoredefaultpath;
    end
    function get_self_path(obj)
        spl=strsplit(mfilename('fullpath'),filesep);
        obj.selfPath=[strjoin(spl(1:end-1),filesep) filesep];
    end
    function add_self_path(obj)
        obj.selfSrcPath=[obj.selfPath 'src' filesep];
        obj.aliasPath=[obj.selfPath 'alias' filesep];
        addpath(obj.selfPath);
        addpath(obj.selfSrcPath);

        warning('off','MATLAB:dispatcher:nameConflict');
        addpath(obj.aliasPath);
    end
    function obj=get_install_status()
        obj.bInstalled=PxInstaller.get_install_status();
        obj.bBaseInstalled=BaseInstaller.get_isntall_status();
        obj.bBaseCompiled=BaseInstaller.get_compiled_status();
        obj.bMidInstall=strcmp(obj.bootDir,obj.selfPath);
        % XXX HANDLE THI SLAST ONE
    end
    function ls_env(obj,dir)
        obj.get_env();
        disp(obj.OUT);
    end
    function get_env(obj)
        if ~Fil.exist(obj.envFile)
            obj.OUT=[];
            return
        end
        obj.OUT=Fil.cell(obj.envFile);
        for i = 1:size(obj.OUT,1)
            try
                obj.OUT{i,2}=Env.var(obj.OUT{i});
            catch
                obj.OUT{i,2}='';
            end
        end
    end
end
methods(Static, Access=private)
    function out=persist(ve)
        global VE__
        if nargin > 0
            VE__=ve;
        else
            out=VE__;
        end
        if isempty(VE__)
            VE.reload();
        end
    end
    function out=get_projects(rootPrjDir,except)
        if nargin < 2 || isempty(except)
            except=0;
        end
        if nargin < 1 || isempty(rootPrjDir)
            rootPrjDir=getenv('PX_PRJ_DIR');
        end
    % GET ALL PROJECTS IN PROJECT DIRECTORY
        folder=dir(rootPrjDir);
        ind=transpose([folder.isdir]);
        f=transpose({folder.name});
        folders=f(ind);
        out=cell2mat(transpose(cellfun( @(x) isempty(regexp(x,'^\.')),folders,'UniformOutput',false)));
        out=transpose(folders(out));
        if ~except
            ind=startsWith(out,'_');
            out(ind)=[];
        end
    end
    function edit_(prj,type)
        if isempty(prj)
            prj=VE.getName();
        elseif ~VE.isProject(prj)
            error(['Cannot find project ' prj ]);
        end

        switch type
            case 'root'
                fname=[Env.var('PX_ETC') 'Px.config'];
            case 'env'
                fname=[Env.var('PX_ETC') 'ENV.config'];
            case 'prj'
                fname=[Env.var('PX_PRJS_ROOT') prj filesep '.px'];
            case 'etc'
                fname=[Env.var('PX_ETC') prj '.config'];
            case 'hook'
                fname=[Env.var('PX_PRJS_ROOT') prj filesep '.px.m'];
            case 'todo'
                fname=[Env.var('PX_PRJS_ROOT') prj filesep 'todo.org'];
            case 'notes'
                fname=[Env.var('PX_PRJS_ROOT') prj filesep 'notes.org'];
        end
        if ~Fil.exist(fname)
            Fil.touch(fname);
        end
        edit(fname);
        disp('Run VE.r for changes to take effect')
    end
end
methods(Static, Hidden)
    function updateDev()
        instDir=PxUtil.dirParse(getenv('PX_INSTALL'));
        prjDir=[PxUtil.dirParse(getenv('PX_PRJ'))];
        VEPrjDir=[prjDir 'VE' filesep];

        files=VE.CRITFILES;
        for i = 1:length(files)
            src=[VEprjDir files{i}];
            dest=[instDir files{i}];
            FilDir.cp(src,dest);
        end

        src=[prjDir 'MatBaseTools' filesep];
        dest=[instDir 'lib' filesep 'MatBaseTools'];
        FilDir.cp(src,dest);
    end
    function test_install()
        if ismac
            prj='/private/bonicn2/prj/';
            inst='/homes/davwhite/Documents/MATLAB';
        else
            prj='/home/dambam/Cloud/Code/mat/prj/';
            inst=[userpath filesep];
        end
        %prj=[userpath filesep 'myProjects'];;
        Px.installPx(inst,prj,'bTest');
    end
    function test_reinstall()
        if ismac
            prj='/private/bonicn2/prj/';
            inst='/homes/davwhite/Documents/MATLAB';
        else
            prj='~/Cloud/Code/mat/prj/';
            inst=[userpath filesep];
        end
        %prj=[userpath filesep 'myProjects'];;
        Px.reinstallPx(inst,prj,'bTest');
    end
%% ENV VARS
    function out=get_root()
        out=getenv('PX_ROOT');
    end
    function out=get_install()
        out=getenv('PX_INSTALL');
    end
    function out=get_boot()
        out=getenv('PX_INSTALL');
    end
    function out=get_etc_dir()
        out=getenv('PX_ETC');
    end
    function out=get_log_dir()
        out=getenv('LOG');
    end
    function out=get_bin_dir()
        out=getenv('PX_CUR_BIN');
    end
    function out=get_src_dir()
        out=getenv('PX_CUR_PRJ_SRC');
    end
    function out=get_media_dir()
        out=getenv('PX_CUR_MEDIA');
    end
    function out=get_data_dir()
        out=getenv('PX_CUR_DATA');
    end
end
end
