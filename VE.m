classdef VE < handle
% VE
%   MatVirtualEnv Suite developer API
%   (If using VE from command prompt, use 've' instead [>> help ve]).
%
% Usage:
%   VE.(command)(argument)
%
% Main commands:
%   VE.help([cmd])    - see full list of commands
%   VE.cd([prj])      - change project
%   VE.pwd            - list current project
%   VE.reload         - reload current project
%   VE.config([type]) - configure projects and ve
%
methods(Static,Hidden)
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
    function init_all_projects()
        % TEST
        VE('all');
    end
end
methods(Static)
%% BASIC
    function out=help(thing)
        % Usage:
        %   help [CMD [ARGS]]
        %   List this information
        if nargin < 1; thing=''; end
        [bGd,STR]=VE.cmd_helper(thing,'CMDS');
        meth=['ls_' thing];
        if bGd && ismethod('VE',meth)
            obj=VE(meth);
        elseif bGd
            VE.cmd_helper([],upper(thing));
        end
        if nargout > 0
            out=STR;
        else
            disp(STR);
        end
    end
    function cd(prj)
        % Usage:
        %   prj [prjname]
        %   Switch project
        if nargin < 1;
            prj=[];
        elseif ~ismember(prj,VE.ls_prjs)
            disp(['Invalid prj name: ' prj '.' ])
            return
        end

        VE('switch','prj',prj);
    end
    function OUT=dirname()
        % Usage:
        %   [dir] = dirname
        %   Print project directory

        %out=getenv('PX_CUR_PRJ_DIR');
        out=builtin('getenv','PX_CUR_PRJ_NAME');

        if nargout > 0
            OUT=out;
        else
            disp(out);
        end
    end
    function OUT=pwd()
        % Usage:
        %   [prj] = pwd
        %   Print current project
        out=builtin('getenv','PX_CUR_PRJ_NAME');
        %out=getenv('PX_CUR_PRJ_NAME');
        if nargout > 0
            OUT=out;
        else
            disp(out);
        end
    end
    function reload()
        % Usage;
        %   reload
        %   Reload all configurations

        VE('reset');
    end
    function out=ls(thing,varargin)
        % Usage;
        %   [out] = ls (deps|env|prj|prjs|ve)
        %   List status/configurations
        if nargin < 1; thing=''; end
        bGd=VE.cmd_helper(thing,'LS');
        if bGd
            if numel(varargin) == 0
                eval(['VE.ls_' thing ';']);
            else
                args=strjoin(varargin,''',''');
                cmd=['VE.ls_' thing '(''' args ''');'];
                eval(cmd);
            end
        end
    end
    function config(thing)
        % Usage;
        %   config (ve|root|etc|prj|hook)
        %   Open configuration for  editing
        %   Args:
        %       mve/ve              User configuration for MVE itself
        %                              these are configurations that *are* specific to you as the end user of MVE.
        %       root                User configuration that are persistent across all projects
        %                              these are configurations that *are* specific to you as the end user.
        %       user/usr [name]     User configuration for invidiual package (current if name is ommitted)
        %                              these are configurations that *are* specific to you as the end user.
        %       source/src [name]   source configuration for invidiual package (current if name is ommitted)
        %                              these are configurations that are *not* specific to any end user.
        %       hook [name]         Hook configuration for individual project (current if name is ommitted)

        if nargin < 1; thing=''; end
        bGd=VE.cmd_helper(thing,'CONFIG');
        if bGd
            eval(['VE.config_' thing ';']);
        end
    end
    function ws(cmd)
        % Usage:
        %   ws (save|load|rm)
        %   Mangage workspaces

        if nargin < 1; cmd=''; end
        bGd=VE.cmd_helper(cmd,'WS');
        if bGd
            eval(['VE.ws_' cmd ';']);
        end
    end
    function new(prj)
        % Usage:
        %   new [prj]
        %   Create and switch to new project


        if nargin < 1; thing='';
            bGd=VE.cmd_helper(thing,'NEW');
            %disp('Must specify prj name')
            return
        end
        dire=[builtin('getenv','PX_PRJS_ROOT') prj filesep];
        if Dir.exist(dire)
            Fil.touch([dire 'pkg.cfg']);
            disp(['Project ' prj ' already exists']);
            return
        end
        mkdir(dire);
        Fil.touch([dire 'pkg.cfg']);
        VE.cd(prj);

    end
    function rm(prj)
        % Usage:
        %   rm [prj]
        %   Remove existing project
        %   'prj' cannot be currently active (cd'd)

        if nargin < 1; thing='';
            bGd=VE.cmd_helper(thing,'RM');
            return
        end

        if nargin < 1; prj=[]; end
        obj=VE('rm','prj',prj);
    end
    function copy(varargin)
        % Usage:
        %   copy [prj] [newname]
        %   copy [newname]
        %   Clone current or existing project


        if nargin < 1; thing='';
            bGd=VE.cmd_helper(thing,'COPY');
            return
        elseif nargin==1
            newName=varargin{1};
            prj=VE.pwd();
        elseif nargin==2
            newName=varargin{2};
            prj=varargin{1};
        end

        if nargin < 1; prj=[]; end
        obj=VE('copy','prj',prj,'newName',newName);
    end
    function rename(varargin)
        % Usage:
        %   rename [prj] [newname]
        %   rename [newname]
        %   Rename current or existing project


        if nargin < 1; thing='';
            bGd=VE.cmd_helper(thing,'RENAME');
            return
        elseif nargin==1
            newName=varargin{1};
            prj=VE.pwd();
        elseif nargin==2
            newName=varargin{2};
            prj=varargin{1};
        end


        if nargin < 1; prj=[]; end
        obj=VE('rename','prj',prj,'newName',newName);
    end
    function todo()
        % Usage;
        %   todo
        %   Open project todo for editing

        VE.edit_([],'todo');
    end
    function notes()
        % Usage;
        %   notes
        %   Open project notes for editing

        VE.edit_([],'notes');
    end
    function hook()
        % Usage;
        %   hook
        %   Run project startup hook

        % TODO
        obj=VE('run_hook');
    end
    function prj=compile(file)
        % Usage;
        %   compile [makefile|sourcefile]
        %   Compile specific file or all uncompiled project files
        %
        % XXX TODO
    end
end
methods(Static,Hidden)
    function config_self()
        % -
        %   Configure VE

        VE.edit_([],'ve');
    end
    function config_pkg()
        % -
        %   Configure project as developer. These are overridden by all other options.
        VE.edit_([],'pkg');
    end
    function config_root()
        % -
        %   Configure root. These options affect all projects, but overriden by etc
        VE.edit_([],'root');
    end
    function config_etc()
        % -
        %   Configure project as end user. This is the highest level of configuration.
        VE.edit_([],'etc');
    end
    function config_hook()
        % -
        %   Configure project hook. This is a startup file for individual projects.
        VE.edit_([],'hook');
    end
%% BASIC
%% LS
    function out=ls_env()
        % -
        %  List loaded environment variables
        if nargout < 1
            VE('ls_env');
        else
            obj=VE('get_env');
            out=obj.OUT;
        end
    end
    function OUT=ls_prjs()
        % -
        %  List all projects
        dire=builtin('getenv','PX_PRJS_ROOT');
        out=VE.get_projects(dire)';
        if nargout > 0
            OUT=out;
        else
            disp( Str.tabify(strjoin(out,newline)) );
        end
    end
    function out=ls_deps(prj)
        % -
        %  List project dependency information
        if nargin < 1; prj=[]; end
        VE('ls_deps','prj',prj);
    end
    function out=ls_hooks(prj)
        % -
        %  List hooks that will run when reloading project

        if nargin < 1
            prj=VE.pwd();
        end

        % TODO
        obj=VE('ls_hooks','prj',prj);
        if nargout > 0
            out=obj.OUT;
        else
            disp(Str.tabify(strjoin(obj.OUT,newline)));
        end
    end
    function out=ls_rev(prj)
        if nargin < 1
            prj=VE.pwd();
        end
        [files,prjs]=VE.get_all_pkg_files();
        files(ismember(prjs,prj))=[];
        prjs(ismember(prjs,prj))=[];
        lines=cellfun(@Fil.cell,files,'UniformOutput',false);
        bRm=cellfun(@(x) isempty(x) || ~any(ismember(x,{'p','l','e'})) || ~any(contains(x,prj)) ,lines);
        prjs(bRm)=[];
        files(bRm)=[];

        % TODO CHECK FILES TO BE SRUE
        if nargout > 0
            out=prjs;
        else
            if isempty(prjs)
                prjs='  --none--';
            end
            disp(Str.tabify(strjoin(prjs,newline)));
        end
    end
%% GET
    function out=ls_prj(varargin)
        % -
        %  List specific dependency configuration options
        obj=VE('get_options');
        disp('  Project')
        disp(obj.OUT.I(1));
        disp('  Combined')
        disp(obj.OUT.C);
    end
    function out=ls_dep(varargin)
        % -
        %  List specific dependency configuration options
        if nargin < 1
            VE.ls_deps();
            return
        end
        obj=VE('get_options',varargin{:});
        if nargout > 0
            out=obj.OUT;
        else
            disp(obj.OUT);
        end
    end
    function out = ls_self(varargin)
        % -
        %  List VE configuration options
        obj=VE('get_root_options',varargin{:});
        if nargout > 0
            out=obj.OUT;
        else
            disp(obj.OUT);
        end
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
    function out=isPrj(prj)
        dire=builtin('getenv','PX_PRJS_ROOT');
        PRJS=VE.get_projects(dire);
        out=ismember(prj,PRJS);
    end
%% PRJ
%% CURRENT PRJ
%% ENV
    function out=getEnv()
    end

%% WORKSPACES
    function ws_save()
        % -
        % save workspace
        VE.save_workspace();
    end
    function ws_load()
        % -
        % load workspace
        VE.workspace_fun('load',false);
    end
    function ws_load_last()
        VE.workspace_fun('load',true);
    end
    function ws_rm()
        % -
        % remove saved workspace
        VE.workspace_fun('delete',false);
    end
end
properties(Access={?Px,?PxInstaller,?BaseInstaller,?PxBaseUnInstaller,?PxUnInstaller,?PxPrjOptions,?PxHistorian,?PxWorkspacer})
    args
    opts
    Px
    PxI
    PxU
    PxB
    mode
    exitflag={'',''}

    bTemp
    bTest=false
    installDir
    rootDir
    bootDir
    libDir
    prjDir
    binDir
    intDir

    etcDir
    extDir
    medDir
    datDir

    existPrjDir=''

    startupFile
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
    userPath

    bSuccess
    OUT
end
properties(Constant,Access=?Px)
   MODES={'rename','self','run','ls_env','get_env','ls_deps','ls_deps_rev','ls_hooks','get_options','get_root_options'}
   CRITFILES={'VE.m','src','alias'}
   CMDS={'help','cd','pwd','reload','config','new','rm','rename','copy','rm','ls','dirname','ws','hook','compile','todo','notes'}
   HIST={'hist_save','hist_load','hist_rm'}

   CONFIG={'config_root','config_etc','config_pkg','config_hook','config_self'}
   LS={'ls_deps','ls_dep','ls_env','ls_prj','ls_prjs','ls_self','ls_hooks','ls_rev'}
   WS={'ws_save','ws_load','ws_rm'}


   CD={};
   PWD={};
   RELOAD={};
   NEW={};
   RM={};
   RENAME={};
   COPY={};
   DIRNAME={};
   HOOK={};
   COMPILE={};
   TODO={};
   NOTES={};

   MAIN={'help','cd','pwd','source','config'}
end
methods(Access=private)
    function obj=VE(moude,varargin)
        if nargin < 1
            moude=[];
        end
        obj.mode=moude;
        VE.warnOff();

        % INTIALIZE PATH
        %if ismember(obj.mode,PxInstaller.MODES)
            obj.startupFile=which('startup');
            obj.userPath=userpath;
        %end

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
        elseif ismember(obj.mode,PxUnInstaller.MODES);
            obj.PxU=PxBaseUnInstaller(obj);
        elseif ismember(obj.mode,PxInstaller.MODES);
            exitflag=obj.PxI.mode_handler();
        elseif ~obj.PxI.bInstalled
            error('VE not installed');
        else
            obj.Px=Px(obj);
        end

        % NOTE: unless specified
        switch obj.exitflag{1}
        case 'rename'
            obj.bRestoreOnCl=false;
            if obj.bTemp
                return
            else
                VE.persist(obj);
            end
        case ''
            obj.bRestoreOnCl=false;
            if obj.bTemp
                return
            else
                VE.persist(obj);
            end
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
            obj.ls_env_();
        case 'get_env'
            obj.get_env();
        case 'ls_deps'
            if strcmp(obj.args.prj,VE.pwd());
                ve=VE.persist();
            else
                ve=VE('get','prj',obj.args.prj);
            end
            disp(ve.Px.tbl);
        case 'ls_hooks'
            if isempty(obj.args) || strcmp(obj.args.prj,VE.pwd());
                ve=VE.persist();
            else
                ve=VE('get','prj',obj.args.prj);
            end
            hooks=vertcat({ve.Px.Opts.I.posthook});
            ind=find(~cellfun(@isempty,hooks));
            obj.OUT=vertcat({ve.Px.Opts.I(ind).name})';
        case 'ls_deps_rev'
            % XXX
        case 'get_options'
            if isempty(obj.args) || strcmp(obj.args.prj,VE.pwd());
                ve=VE.persist();
            else
                ve=VE('get','prj',obj.args.prj);
            end
            obj.OUT=ve.Px.Opts;

            if isempty(obj.args)
                return
            end
            ind=find(ismember(vertcat({obj.OUT.I.name}),obj.args));

            if isempty(ind)
                disp(['Invalid dependency name(s) ' strjoin(obj.args,',')]);
                return
            end
            obj.OUT=obj.OUT.I(ind);
        case 'get_root_options'
            ve=VE.persist();
            obj.OUT=ve.Px.rootOpts;
            if numel(obj.args) == 1
                obj.OUT=obj.OUT{obj.args{1}};
            elseif numel(obj.args) > 1
                obj.OUT(args{:});
            end
        case 'rename'
            obj.Px=Px(obj);
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

        bReInstall=strcmp(obj.mode,'reinstallPx');

        if isfield(obj.args,'installDir')
            obj.installDir=obj.args.installDir;
            if ~endsWith(obj.installDir,filesep);
                obj.installDir=[obj.InstallDir filsep];
            end
            obj.args=rmfield(obj.args,'installDir');
        elseif ~exist([obj.selfPath '.internal' filesep '.installed'],'file')
            error('No Install directory provided');
        end

        %obj.rootDir=[obj.installDir 'pkg.cfg' filesep];
        if isempty(obj.installDir)
            obj.rootDir=[PxUtil.parent(obj.selfPath)];
        else
            obj.rootDir=obj.installDir;
        end

        obj.bootDir=[obj.rootDir 'boot' filesep];
        obj.prjDir=[obj.rootDir 'prj' filesep];
        obj.libDir=[obj.bootDir 'lib' filesep];
        obj.binDir=[obj.bootDir 'bin' filesep];
        obj.intDir=[obj.bootDir '.internal' filesep];

        obj.etcDir=[obj.rootDir 'etc' filesep];
        obj.extDir=[obj.rootDir 'ext' filesep];
        obj.medDir=[obj.rootDir 'media' filesep];
        obj.datDir=[obj.rootDir 'data' filesep];

        obj.envFile=[obj.intDir 'env'];
        obj.diaryFile=[obj.intDir 'log'];
        obj.lastSavedWrk=[obj.intDir 'last_saved_wrk'];

        flds={...
             'bTest',false;
             'bTemp',false;
        };
        for i = 1:size(flds,1)
            fld=flds{i,1};
            if isfield(obj.args,fld)
                obj.(fld)=obj.args.(fld);
                obj.args=rmfield(obj.args,fld);
            else
                obj.(fld)=flds{i,2};
            end
        end
        flds={...
             'bMBTRecompile',bReInstall;
             'bMBTReinstall',bReInstall;
        };
        for i = 1:size(flds,1)
            fld=flds{i,1};
            if isfield(obj.args,fld)
                obj.opts.(fld)=obj.args.(fld);
                obj.args=rmfield(obj.args,fld);
            else
                obj.opts.(fld)=flds{i,2};
            end
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
        %spl=strsplit(mfilename('fullpath'),filesep);
        %obj.selfPath=[strjoin(spl(1:end-1),filesep) filesep];
        obj.selfPath=strrep(which('VE'),'VE.m','');
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
    function ls_env_(obj,dir)
        obj.get_env();
        disp(obj.OUT);
    end
    function get_env(obj)
        if ~Fil.exist(obj.envFile)
            obj.OUT=[];
            return
        end
        obj.OUT=Fil.cell(obj.envFile);
        obj.OUT(:,2)=Env.var(obj.OUT(:,1));
    end
end
methods(Static, Access=private)
    function first_startup()
        VE('startup1');
    end
    function [bGd,STR]=cmd_helper(thing,name)
        C=VE.(name); % CALL PROPERTY
        if isempty(C)
            name=['VE.' lower(name)];
            STR=help(name);
            bGd=~isempty(STR);
            if nargout < 2
                disp(STR);
            end
            return
        end
        if ismember(name,{'CMDS','MAIN','WS','HIST'})
            bCmd=true;
            type='commands';
            t='command';
            line=3;
        else
            bCmd=false;
            type='arguments';
            t='argument';
            line=2;
        end
        STR='';
        lname=lower(name);
        full=[lname '_' thing];
        if isempty(thing)
            bGd=false;
        elseif ~ismember(thing,C) && ~ismember(full,C);
            bGd=false;
            STR=['  Invalid ' t ' ''' thing '''' newline];
        else
            bGd=true;
        end
        if ~bGd
            STR=[STR '  Valid ' type ':'];
            out=VE.get_help_short(C,line);
            if bCmd
                out=Cell.toStr([C' out']);
            else
                C=strrep(C, [lname '_'], '');
                out=Cell.toStr([C' out']);
            end
            STR=[STR newline Str.tabify(out,4)];
            if nargout < 2
                disp(STR);
            end
        end
    end
    function out=persist(ve)
        global VE__;
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
            %rootPrjDir=getenv('PX_PRJ_DIR');
            rootPrjDir=builtin('getenv','PX_PRJ_DIR');
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
            prj=VE.pwd();
        elseif ~VE.isProject(prj)
            error(['Cannot find project ' prj ]);
        end


        configExt='.cfg';

        opts=VE.ls_self();
        switch type
            case {'ve','mve','VE','MVE'}
                fname=[Env.var('PX_ETC') 've.cfg'];
                ed=opts{'configEditor'};
            case 'root'
                fname=[Env.var('PX_ETC') 'root.cfg'];
                ed=opts{'configEditor'};
            case {'src','source'}
                fname=[Env.var('PX_PRJS_ROOT') prj filesep 'pkg.cfg'];
                ed=opts{'configEditor'};
            case 'usr'
                fname=[Env.var('PX_ETC') prj '.cfg'];
                ed=opts{'configEditor'};
            case 'hook'
                dire=[Env.var('PX_ETC') prj '.d' filesep];
                if ~exist(dire,'dir')
                    mkdir(dire);
                end
                fname=[dire 'posthook.m'];
                ed=opts{'externalEditor'};
            case 'todo'
                fname=[Env.var('PX_PRJS_ROOT') prj filesep 'todo' opts{'todoExt'}];
                ed=opts{'todoEditor'};
            case 'notes'
                fname=[Env.var('PX_PRJS_ROOT') prj filesep 'notes' opts{'notesExt'} ];
                ed=opts{'notesEditor'};
            case 'readme'
                fname=[Env.var('PX_PRJS_ROOT') prj filesep 'README' opts{'readmeExt'}];
                ed=opts{'readmeEditor'};
        end
        if ~Fil.exist(fname)
            Fil.touch(fname);
        end
        if isempty(ed) || ismember(ed,{'matlab','mat','MATLAB','MAT'})
            edit(fname);
        elseif isunix
            cmd=[ed ' ' fname];
            [out1,out2]=unix(cmd);
        elseif ispc
            cmd=[ed ' ' fname];
            system(cmd);
        end
        disp('Run ''ve reload'' for changes to take effect')
    end
    function out=get_help_short(cmd,line)
        if iscell(cmd)
            out=cellfun(@(x) VE.get_help_short(x,line),cmd,'UniformOutput',false);
            return
        end
        out=help(['VE.' cmd]);
        spl=strsplit(out,newline);
        if numel(spl) >= line
            out=spl{line};
        else
            out=spl{1};
        end
    end
    function get_help(cmd)
        if ismethod(VE.cmd)
        end
    end
end
methods(Static, Hidden)
    function get_deps_rev(prj)
        % TODO, read files to be sure
    end
    function [files,PRJS]=get_all_pkg_files()
        dire=Dir.parse(getenv('PX_PRJS_ROOT'));
        PRJS=Dir.dirs(dire);
        opts=VE.ls_self();
        ignore=opts{'ignoreDirs'};
        PRJS(ismember(PRJS,ignore))=[];
        files=strcat(dire,PRJS,filesep,'pkg.cfg');
        ind=~cellfun(@Fil.exist,files);
        files(ind)=[];
        PRJS(ind)=[];
    end
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
    function warnOff()
        warning('off','MATLAB:dispatcher:nameConflict');
    end
end
end
