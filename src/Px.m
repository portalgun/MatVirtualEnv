classdef Px < handle
properties
    ve
    bStartup=false

    args

    prj  % MAIN PROJECT
    prjs % currently duplicate of PRJS XXX
    PRJS % ALL PROJECTS
    tbl

    dirs=struct('root',struct(),'prj',struct(),'lnk',struct())
    % root
    %dirs.root.lib
    %dirs.root.var
    %dirs.root.tmp
    %dirs.root.ext
    %dirs.root.etc
    %dirs.root.wrk
    %dirs.root.bin
    %dirs.root.log
    %dirs.root.prj
    %dirs.root.media
    %dirs.root.data

    % prj
    %dirs.prj.prj
    %dirs.prj.wrk
    %dirs.prj.bin
    %dirs.prj.media
    %dirs.prj.data
    %prjVarDir
    %prjLogDir

    % LINK
    %dirs.lnk.wrk
    %dirs.lnk.lib
    %dirs.lnk.src
    %dirs.lnk.bin
    %dirs.lnk.media
    %dirs.lnk.data

    % WRK
    %dirs.wrk{}

    sys
    % hostname
    % os
    % isunix
    % home

    mat
    %year
    %release
    %version
    %root



    % ROOT CONFIG
    diaryFile
    prjEnvFile
    rootEnvFile
    curPrjFile
    curWSFile
    pathFile
    defPathFile
    bInitedFile
    bTemp=false

    rootCfgFile
    rootOpts
    argOpts
    hiddenOpts

    % PRJ CONFIG
    Hist
    Wrk
    Opts
    Cfg
    Cmp
    lastEnv
    path
    pathStr

    OUT
    msg
end
properties(Constant)
    div=char(59)
    sep=char(61)
    MODES={'get','run_hook','copy','rename','rm','switch','prompt','reset','startup','startup1','all','list','compile_prj','compile_files'}
    ROOTFLDS={'test','prvt','wrk','bin','prj','ext','tmp','var','lib','etc','data','media', 'log'}
    ROOTDIRS={'test','prvt','wrk','bin','prj','ext','tmp','var','lib','etc','data','media',['var' filesep 'log']}
    ROOTWRITE={'wrk','bin','media','tmp','var','log'}
    DEFAULTIGNORE={'.git','.px','.svn','.DS_Store','private'}

end
methods(Access = ?VE)
    function obj=Px(ve)
        obj.ve=ve;

        obj.setup_root();
        obj.mode_handler();
        obj.echo();
    end
    function obj=echo(obj)
        switch obj.ve.exitflag{1}
            case 'exit'
                switch obj.ve.exitflag{2}
                case 'prompt'
                    display(['No project entered. Exiting.']);
                    return
                end
        end

        switch obj.ve.mode
        case {'list','get'}
            return
        case 'startup'
            if ~obj.bTemp
                display(['Project ' obj.prj ' loaded.']);
            end
        case 'reset'
            display(['Done reloading project ' obj.prj '.']);
        case 'switch'
            display(['Now on project ' obj.prj '.']);
        otherwise
            if isempty(obj.msg)
                display('Done.')
            else
                display(obj.msg)
            end
        end
    end
%% MODES
    function mode_handler(obj)
        mode=obj.ve.mode;
        if isempty(mode)
            mode='prompt';
        end
        switch obj.ve.mode
            case 'all'
                obj.mode_all();
            case 'prompt'
                obj.mode_prompt();
            case 'switch'
                obj.mode_switch();
            case 'get'
                obj.mode_get();
            case 'reset'
                obj.mode_reset();
            case 'startup'
                obj.mode_startup(false);
            case 'startup1'
                obj.mode_startup(true);
            case 'list'
                obj.disp_prjs();
            case 'compile_prj'
                obj.mode_compile_prj();
            case 'compile_file'
                obj.mode_compile_prj();
            case 'rename'
                obj.mode_rename();
            case 'copy'
                obj.mode_copy();
            case 'rm'
                obj.mode_rm();
            otherwise
                error(['Invalid VE Mode: ' obj.ve.mode]);
        end
    end
    function mode_all(obj)
        for i = 1:length(obj.PRJS)
            obj.prj=obj.PRJS{i};
            try
                obj.make_prj_dirs();
                obj.make_wrk_dir();
                obj.get_all_opts();
                obj.setup_extra();
                obj.compile();
            catch
                display(['Error with ' obj.PRJS{i}]);
            end
        end
    end
    function out=INVALIDNAMES(obj)
        flds=fieldnames(obj.dirs.root)';
        out=[obj.ROOTFLDS obj.ve.CMDS flds];
    end
    function mode_copy(obj)
        obj.args=obj.ve.args;

        nn=obj.args.newName;
        on=obj.args.prj;

        % CHECK NAME VALIDITY
        if strcmp(nn,on)
            obj.msg=sprintf('Current project is already named ''%s''.', nn);
            return
        elseif ismember(nn,obj.PRJS)
            obj.msg=sprintf('New project name ''%s'' already exists.', nn);
            return
        elseif ismember(nn,obj.INVALIDNAMES);
            obj.msg=sprintf('New project name ''%s'' conflicts with MVE internals.', nn);
            return
        end

        obj.copy_prj_files(on,nn);
        if ~isempty(obj.msg)
            return
        end
    end
    function mode_rm(obj)
        obj.args=obj.ve.args;

        on=obj.args.prj;
        if strcmp(obj.prj,on)
            obj.msg='Cannot remove an active project. Change to a different project fist.';
            return
        end

        on=obj.args.prj;
        out=Input.yn(['Are you sure you want to delete project ' on '?']);
        if ~out
            return
        end

        obj.rm_prj_files(on);
    end
    function mode_rename(obj)
        obj.args=obj.ve.args;

        nn=obj.args.newName;
        on=obj.args.prj;

        % CHECK NAME VALIDITY
        if strcmp(nn,on)
            obj.msg=sprintf('Current project is already named ''%s''.', nn);
            return
        elseif ismember(nn,obj.PRJS)
            obj.msg=sprintf('New project name ''%s'' already exists.', nn);
            return
        elseif ismember(nn,obj.INVALIDNAMES);
            obj.msg=sprintf('New project name ''%s'' conflicts with MVE internals.', nn);
            return
        end

        % RENAME FILES
        obj.rename_prj_files(on,nn);
        if ~isempty(obj.msg)
            return
        end

        % CHANGE TO PROJECT IF CURRENT
        obj.get_prjs();
        obj.rootOpts{'bWorkspace'}=false;
        if strcmp(obj.prj,on)
            obj.mode_switch(nn);
        end
        obj.ve.exitflag{1}='rename';
    end
    function rename_prj_files(obj,on,nn)
        obj.file_helper(on,nn,'m');
    end
    function copy_prj_files(obj,on,nn)
        obj.file_helper(on,nn,'c');
    end
    function rm_prj_files(obj,on)
        obj.file_helper(on,[],'r');
    end
    function file_helper(obj,on,nn,moude)
        % -rename-
        % etc/prj.(cfg|config)
        % etc/prj.d
        % hook

        % -wrk-
        % rm
        % create new
        % lib?
        nw=['  ' newline];

        % DIRS
        dirs={'wrk','test','bin','prj','var','log','media','data','etc'};
        n=length(dirs);
        bDirOld=false(n,1);
        bDirNew=false(n,1);;
        bDLnOld=false(n,1);
        dirOld=cell(n,1);
        dirNew=cell(n,1);
        msg={};
        for i = 1:length(dirs)
            dire=dirs{i};
            root=obj.dirs.root.(dire);


            dirOld{i}=[root on];
            dirNew{i}=[root nn];
            if strcmp(dire,'etc')
                dirOld{i}=[dirOld{i} '.d'];
                dirNew{i}=[dirNew{i} '.d'];
            end

            bDirOld(i)=Dir.exist(dirOld{i});
            bDLnOld(i)=bDirOld(i) && Dir.isLink(dirOld{i});
            if moude~='r'
                bDirNew(i)=Dir.exist(dirNew{i});
            end
        end
        if any(bDLnOld) && moude ~= 'r'
            dires=strcat({'  '},strjoin(dirOld(bDLnOld),nw));
            msg=[msg sprintf('Directories that are unexpectedly linked:\n%s', dires{1})];
        end
        if any(bDirNew) && moude~='r'
            dires=strcat({'  '},strjoin(dirNew(bDirNew),nw));
            msg=[msg; sprintf('Unexpected existing files:\n%s.', dires{1})];
        end

        %FILES
        etc=obj.dirs.root.etc;
        %hk=obj.dirs.root.hook;
        %files={[etc '%s.config'],[etc '%s.cfg'],[hk '%s.m']};
        files={[etc '%s.config'],[etc '%s.cfg']};
        m=length(files);

        bFilOld=false(m,1);
        bFilNew=false(m,1);;
        bFilOld=false(m,1);
        bFLnOld=false(m,1);
        filOld=cell(m,1);
        filNew=cell(m,1);
        for i = 1:m
            fil=files{i};

            filOld{i}=sprintf(fil,on);
            filNew{i}=sprintf(fil,nn);

            bFilOld(i)=Dir.exist(filOld{i});
            bFLnOld(i)=bFilOld(i) && Fil.isLink(filOld{i});

            if moude~='r'
                bFilNew(i)=Dir.exist(filNew{i});
            end

        end

        if any(bFLnOld) && moude~='r'
            dires=strcat({'  '},strjoin(dirOld(bFLnOld),nw));
            msg=[msg sprintf('Files that are unexpectedly linked:\n%s', dires{1})];
        end
        if any(bFilNew) && moude~='r'
            dires=strcat({'  '},strjoin(dirNew(bFilNew),nw));
            msg=[msg sprintf('Unexpected existing files:\n%s.', dires{1})];
        end
        if ~isempty(msg) && moude ~= 'r'
            str=sprintf('Errors in renaming %s to  %s:\n',on,nn);
            obj.msg=strjoin([str msg],newline);
            return
        end

        % HISTORY FILES

        % RENAME DIRS
        for i = 1:n
            if ~bDirOld(i) && (strcmp(dirs{i},'etc') || moude=='r')
                continue
            elseif ~bDirOld(i)
                Dir.mk(dirNew{i});
                continue
            end
            if moude=='m'
                Dir.mv(dirOld{i},dirNew{i});
            elseif moude=='c'
                % copyfile doesn't handle symlinks
                if strcmp(dirs{i},'wrk')

                    if isunix
                        cmd=sprintf('cp -r %s %s',dirOld{i},dirNew{i});
                        [exitflag,out]=unix(cmd);
                    else
                        TODO
                        cmd=sprintf('cp -r %s %s',dirOld{i},dirNew{i});
                        [exitflag,result]=system(cmd);
                    end
                    if exitflag
                        disp(out)
                    end

                else
                    Dir.cp(dirOld{i},dirNew{i});
                end
            elseif moude=='r'
                if bDLnOld(i)
                    FilDir.unlink(dirOld{i});
                else
                    % WILL PROMPT FOR REMOVAL
                    Dir.rm_rf(dirOld{i});
                end
            end
        end
        % RENAME FILES
        for i = 1:m
            if ~bFilOld(i)
                continue
            end
            if moude=='m'
                Dir.mv(filOld{i},filNew{i});
            elseif moude=='c'
                Dir.cp(filOld{i},filNew{i});
            elseif modue=='r'
                if bFLnOld(i)
                    FilDir.unlink(filOld{i});
                else
                    delete(filOld{i});
                end
            end
        end
    end
    function mode_prompt(obj)
        obj.prompt_prj();
        if strcmp(obj.ve.exitflag{1},'exit')
            return
        end
        obj.setup_prj(obj.prj);
    end
    function mode_get(obj)
        obj.bTemp=true;
        prj=obj.argOpts{'prj'};
        if isempty(prj)
            prj=obj.prj;
        end
        if ~ismember_cell(obj.prj,obj.PRJS)
            error(['Invalid project: ' prj ]);
        end

        if strcmp(obj.ve.exitflag{1},'exit')
            return
        end
        obj.setup_prj();
    end
    function mode_switch(obj,prj)
        curPrj=obj.prj;
        if nargin < 2 || isempty(prj)
            obj.prj=obj.argOpts{'prj'};
        else
            obj.prj=prj;
        end
        if isempty(obj.prj)
            obj.prompt_prj();
        elseif ~ismember(obj.prj,obj.PRJS);
            error(['Invalid project: ' prj ]);
        end

        if strcmp(obj.ve.exitflag{1},'exit')
            return
        end
        if obj.rootOpts{'bWorkspace'};
            obj.Wrk.prompt_save(curPrj);
            obj.Wrk.prompt_load(obj.prj);
        end
        obj.setup_prj();
    end
    function mode_reset(obj)
        obj.setup_prj();
    end
    function mode_startup(obj,bFirst)
        obj.bStartup=true;
        if isempty(obj.prj)
            obj.prompt_prj();
        end
        if strcmp(obj.ve.exitflag{1},'exit')
            return
        end

        if ~isempty(obj.prj)
            obj.setup_prj(obj.prj);
        end
    end
    function mode_complile_files(obj)
        obj.make_prj_dirs();
        obj.make_wrk_dir();

        obj.get_all_opts();
        obj.compile();
        obj.Cmp=PxCompiler(obj);
        obj.Cmp.compile_files();
    end
    function mode_complile_prj(obj)
        obj.make_prj_dirs();
        obj.make_wrk_dir();

        obj.get_all_opts();
        obj.compile();
        obj.Cmp=PxCompiler(obj);
        obj.Cmp.compile_all();
        obj.Cmp.link_to_prj();
    end
%% PRJS DISPLAY
    function get_prjs(obj)
        obj.PRJS=Dir.dirs(obj.dirs.root.prj);
        ignore=obj.rootOpts{'ignoreDirs'};
        obj.PRJS(ismember(obj.PRJS,ignore))=[];
    end
    function disp_prjs(obj)
        fprintf(['%-31s' newline],'PROJECTS');
        for i = 1:length(obj.PRJS)
            if i > length(obj.PRJS)
                %fprintf(['    %-25s   %3.0f %-25s' newline],repmat(' ',1,25),i+length(obj.PRJS), obj.sprjs{i}); %
                fprintf(['    %-25s   %3.0f %-25s' newline],repmat(' ',1,25),i+length(obj.PRJS), ' '); %
            else
                %fprintf(['%3.0f %-25s   %3.0f %-25s' newline],i, obj.PRJS{i},i+length(obj.PRJS), ' '); %
                fprintf(['%3.0f %-25s ' newline],i, obj.PRJS{i}); %
            end
        end
    end
    function prompt_prj(obj)
        %PROMPT FOR PROJECT
        if ~obj.bStartup
            disp([newline '  r last open poject']);
        elseif isempty(obj.PRJS)
            return
        else
            disp(newline);
        end

        obj.disp_prjs();
        val=['12345677890'];
        while true
            resp=input([newline 'Which Project?: '],'s');
            Mat.rmLastHistory();
            if strcmp(resp,'r') && ~obj.bStartup
                obj.mode_rest();
                return
            end

            if isempty(resp)
                obj.ve.exitflag={'exit','prompt'};
                return
            elseif Str.Num.isInt(resp)
                resp=str2double(resp);
                if resp > length(obj.PRJS) || resp < 0
                    disp('Invalid response')
                    continue
                end
            elseif ismember(resp,obj.PRJS)
                obj.prj=resp;
                return
            end
            break
        end
        obj.prj=obj.PRJS{resp};
        obj.save_cur_prj();
    end
%% ROOT
    function setup_root(obj)

        obj.get_sys_info;

        P=Px.get_root_configs_parse();

        obj.find_root_config();
        cfg=Cfg.read(obj.rootCfgFile,[],[],obj.sys.hostname);
        obj.rootOpts=Args.parse(dict(),P,cfg);

        P=Px.get_px_parse;
        [obj.argOpts,UM]=Args.parseLoose(dict(),P,obj.ve.args);


        % DIRS
        obj.get_root_dirs();

        % FILES
        obj.rootEnvFile=[obj.ve.intDir 'env']; % FOR CLEARING ENV ON SWITCH
        obj.curPrjFile=[obj.ve.intDir 'current_project'];

        obj.Hist=PxHistorian(obj,obj.rootOpts{'bHistory'});

        obj.get_prjs();
        if isempty(obj.prj)
            obj.get_current_prj;
        end
        if obj.rootOpts{'bWorkspace'};
            obj.Wrk=PxWorkspacer(obj);
        end
    end
    function get_sys_info(obj)
        obj.sys.hostname=Sys.hostname();
        obj.sys.os=Sys.os;
        obj.sys.isunix=ismember(obj.sys.os,{'mac','linux'});
        obj.sys.home=Dir.parse(Dir.home());
        [obj.mat.year,obj.mat.release]=Mat.version();
        obj.mat.version=obj.mat.year+obj.mat.release;
        obj.mat.userpath=userpath;
        obj.mat.root=matlabroot;
    end
    function obj=find_root_config(obj);
        if ~isempty(obj.rootCfgFile)
            return
        end
        name='ve.cfg';

        list={[obj.ve.rootDir 'etc' filesep], obj.sys.home, obj.ve.selfPath};
        for i = 1:length(list)
            fname=[list{i} name];
            if Fil.exist(fname)
                obj.rootCfgFile=fname;
                break
            end
        end
        if isempty(obj.rootCfgFile)
            dire=[Dir.parent(obj.ve.selfPath) 'etc' filesep];
            mkdir(dire);
            obj.rootCfgFile=[dire name];
            Fil.touch(obj.rootCfgFile);
        end
    end
    function obj=get_root_dirs(obj)
        flds=Px.ROOTFLDS;
        dirs=Px.ROOTDIRS;
        wDir=obj.rootOpts{'writeDir'};
        bWDir=~isempty(wDir);
        for i = 1:length(flds)
            fld=flds{i};
            if ~isfield(obj.dirs.root,fld) || isempty(obj.dirs.root.(fld))
                obj.dirs.root.(fld)=[obj.ve.rootDir dirs{i} filesep];
            end
            % HANDLE RO
            if bWDir &&  ismember(fld,writeList)
                obj.dirs.root.(f)=[obj.dirs.root.write obj.dirs.root.(fld)];
            end
            % MAKE
            if ~Dir.exist(obj.dirs.root.(fld))
                mkdir(obj.dirs.root.(fld));
            end
        end
    end
%% PRJ
    function out=bSkipDirs(obj)
        out=strcmp(obj.ve.mode,'switch') && Fil.exist(obj.bInitedFile) && obj.rootOpts{'bMakeDirsOnSwitch'};
    end
    function out=bSkipPath(obj)
        bPathFile=Fil.exist(obj.pathFile);
        out=(strcmp(obj.ve.mode,'startup') && ~obj.rootOpts{'bAutoPathGenOnStartup'} && bPathFile) || ...
            (strcmp(obj.ve.mode,'switch') && ~obj.rootOpts{'bAutoPathGenOnSwith'} && bPathFile);
    end
    function setup_prj(obj,prj)
        if nargin > 1
            obj.prj=prj;
        end

        obj.bInitedFile=[obj.dirs.root.var obj.prj filesep 'bInitzed'];
        if ~obj.bSkipDirs()
            obj.make_prj_dirs();
            obj.make_wrk_dir();
            if ~obj.bTemp
                Fil.touch(obj.bInitedFile);
            end
        end

        obj.get_all_opts();
        if obj.bTemp
            return
        end

        obj.setup_extra();

        obj.set_env();
        obj.compile();

        obj.save_cur_prj();

        if strcmp(obj.ve.mode,'reset')
            bClc=obj.rootOpts{'bClcOnReload'};
            bClear=false;
        elseif strcmp(obj.ve.mode,'switch')
            bClc=obj.rootOpts{'bClcOnSwitch'};
            bClear=obj.rootOpts{'bClcOnSwitch'};
        else
            bClc=false;
            bClear=false;
        end

        obj.setup_path();

        if bClc
            clc;
        end
        if bClear
            evalin('base','clear');
        end
        obj.run_post_hooks();
        builtin('cd',obj.dirs.prj.wrk);
        savepath;  %% XXX NEED to chekck if can save to pathdef
        savepath(obj.pathFile);
        if isempty(obj.mat.userpath) && ~isempty(obj.sys.home)
            def=[obj.sys.home 'Documents' filesep 'MATLAB'];
            if Dir.exist(def)
                userpath(def);
            end
        end
    end
    function get_all_opts(obj,prj)
        if nargin > 1
            obj.prj=prj;
        end
        obj.Cfg=PxPrjConfigs(obj);

        obj.Opts=PxPrjOptions(obj);
        obj.parse_prj_options();

        obj.get_table();
        if ~isempty(obj.tbl)
            obj.prjs=obj.tbl.name;
        end
    end
    function setup_extra(obj)
        if obj.rootOpts{'bHistory'}
            obj.Hist.prjLink();
        end
        if obj.rootOpts{'bGtags'}
            obj.gen_gtags();
        end
    end
    function obj=compile(obj)
        obj.Cmp=PxCompiler(obj);
    end
    function obj=setup_path(obj)
        obj.pathFile=[obj.dirs.root.var obj.prj filesep 'prjPath.m'];

        obj.add_java_paths();
        if obj.bSkipPath
            run(obj.pathFile);
            return
        end
        obj.get_paths();
        Path.set(obj.path);
    end
    function obj=parse_prj_options(obj)
        % MAIN
        obj.populate_curSrc_dir();

        % DEPS
        obj.clone_to_lib();
        obj.rm_removed_dep_symlinks();
        if ~obj.bSkipDirs()
            obj.populate_curLib_dir();
        end

    end
    function obj=clone_to_lib(obj);
        for i = 2:length(obj.Opts.I)
            O=obj.Opts.I(i);
            if isempty(O.site)
                continue
            end
            Dir.git_clone(O.site,O.dire);
            if ~isempty(O.version)
                Dir.git_checkout(O.add,O.version);
            end

        end
    end
    function obj=lock_lib_files(obj)
        % TODO make read only -> make readonly
        % chmod -w
    end
    function obj=save_cur_prj(obj)
        if ~Fil.exist(obj.curPrjFile)
            Fil.touch(obj.curPrjFile);
        end
        Fil.rewrite(obj.curPrjFile,obj.prj);
    end
    function prj=get_current_prj(obj)
        if ~exist(obj.curPrjFile,'file');
            prj=[];
            return
        end
        fid=fopen(obj.curPrjFile);
        tline=fgets(fid);
        fclose(fid);
        if isempty(tline) || isequal(tline,-1)
            prj=[];
            return
        end
        obj.prj=strtrim(strrep(tline,char(10),''));
    end
%% DEPS

    function get_table(obj)
        if isempty(obj.Opts.I) || numel(obj.Opts.I) < 2
            return
        end
        deps=obj.Opts.I;
        deps=deps([deps.bAdd]);
        rmflds={'bRm','bAdd','error','exist','mex','include','exclude','javapath','env','root__'};
        for i = 1:length(rmflds)
            deps=rmfield(deps,rmflds{i});
        end
        obj.tbl=struct2table(deps);

    end
    function ls_deps(obj)
        OUT=obj.deps2table();
        disp([newline '    Dependencies for ' obj.prj newline]);
        disp(OUT);
    end
%% WRK DIR
    function obj=rm_removed_dep_symlinks(obj)
        if size(obj.tbl,1) < 2
            return
        end

        deps=obj.tbl.name(2:end);
        dirs=Dir.dirs(obj.dirs.lnk.lib);
        full=strcat(obj.dirs.lnk.lib,dirs,filesep);

        ind=~ismember(dirs,deps);
        rmdirs=full(ind);
        for i = 1:length(rmdirs)
            if FilDir.isLink(rmdirs{i})
                delete(rmdirs{i}); % works with symlinks
            else
                error('unexpected directory')
            end
        end

    end
    function obj=make_prj_dirs(obj,prj)
        if nargin < 2 || isempty(prj)
            prj=obj.prj;
        end
        flds={'prj','wrk','bin','data','media','var','log','test'};
        % PRJ DIRS
        for i = 1:length(flds)
            fld=flds{i};
            obj.dirs.prj.(fld)=[obj.dirs.root.(fld) prj filesep];
            if ~obj.bTemp && ~Dir.exist(obj.dirs.prj.(fld))
                mkdir(obj.dirs.prj.(fld));
            end
        end
        obj.dirs.root.varlib=[obj.dirs.prj.var 'lib' filesep];
        if ~obj.bTemp && ~Dir.exist([obj.dirs.prj.var 'lib' filesep])
            mkdir(obj.dirs.root.varlib);
        end
    end
    function obj=make_wrk_dir(obj,prj)
        if nargin < 2 || isempty(prj)
            prj=obj.prj;
        end

        % WRK
        obj.dirs.wrk={};
        flds={'bin','lib','src','media','bin','data','var','test'};
        obj.dirs.lnk.wrk=[obj.dirs.root.wrk prj filesep];
        for i =1:length(flds)
            fld=flds{i};
            obj.dirs.lnk.(fld)= [obj.dirs.lnk.wrk fld filesep];
        end
        if obj.bTemp
            return
        end

        % TO CREATE
        flds={'wrk','bin','lib'};
        for i = 1:length(flds)
            fld=flds{i};
            Dir.mk_p(obj.dirs.lnk.(fld));
        end

        % TO LINK
        if obj.rootOpts{'bData'}
            dir=obj.dirs.lnk.data(1:end-1);
            FilDir.easyln(obj.dirs.prj.data,dir);
        elseif ~FilDir.isLink(obj.dirs.lnk.data)
            FilDir.unlink(obj.dirs.lnk.data);
        end
        if obj.rootOpts{'bMedia'}
            dir=obj.dirs.lnk.media(1:end-1);
            FilDir.easyln(obj.dirs.prj.media,dir);
        elseif ~FilDir.isLink(obj.dirs.lnk.media)
            FilDir.unlink(obj.dirs.lnk.media);
        end
        dir=obj.dirs.lnk.var(1:end-1);
        FilDir.easyln(obj.dirs.prj.var,dir);

        % FILES
        if obj.rootOpts{'bProjectile'} && ~exist([obj.dirs.lnk.wrk '.projectile'])
            Fil.touch([obj.dirs.lnk.wrk '.projectile']);
        end
        todoFil=[obj.dirs.prj.prj 'TODO.org'];
        if Fil.exist(todoFil)
            FilDir.easyln(todoFil, [obj.dirs.lnk.wrk 'TODO.org']);
        end

        noteFil=[obj.dirs.prj.prj 'notes.org'];
        if Fil.exist(noteFil)
            FilDir.easyln(noteFil, [obj.dirs.lnk.wrk 'notes.org']);
        end

        pxFil=[obj.dirs.prj.prj 'pkg.cfg'];
        if Fil.exist(pxFil)
            FilDir.easyln(pxFil, [obj.dirs.lnk.wrk 'pkg.cfg']);
        end

    end
    function obj=populate_curSrc_dir(obj)
        src=obj.Opts.I(1).dire;
        dest=obj.dirs.lnk.src;
        if endsWith(dest,filesep)
            dest=obj.dirs.lnk.src(1:end-1);
        end

        FilDir.easyln(src,dest,0,obj.sys.home);
        obj.dirs.wrk{end+1}=dest;
    end
    function obj=populate_curLib_dir(obj);
        %Make sure that projects in each exist, then symlink
        Opts=obj.Opts.I(2:end);
        for i = 1:length(Opts)
            O=Opts(i);
            if ~O.bAdd
                continue
            end
            dest=[obj.dirs.lnk.lib O.name];
            src=O.dire;

            FilDir.easyln(src,dest,0,obj.sys.home);

            obj.dirs.wrk{end+1}=dest;
        end
    end
%% PATH
    function get_paths(obj)

        % PRVT
        if Dir.exist(obj.dirs.root.prvt)
            prvt=obj.dirs.root.prvt;
        else
            prvt=[];
        end

        % EXTRA
        lnk=struct2cell(obj.dirs.lnk);
        [~,wrkDir]=Dir.dirs(obj.dirs.prj.wrk);
        extra=wrkDir(~ismember(wrkDir,lnk));
        if isempty(extra)
            extra=[];
        end

        % LIB
        lib=obj.get_lib_path();

        % AUX
        aux=rmfield(obj.dirs.prj,{'prj','bin'});
        if ~obj.rootOpts{'bMedia'}
            aux=rmfield(aux,'media');
        end
        if ~obj.rootOpts{'bData'}
            aux=rmfield(aux,'data');
        end
        aux=struct2cell(aux);
        if isempty(aux)
            aux=[];
        end


        % BIN
        if ~isempty(obj.prjs)
            bin=strcat(obj.dirs.root.bin,obj.prjs,filesep);
            bin=bin(cellfun(@Dir.exist,bin));
            if isempty(bin)
                bin=[];
            end
        else
            bin=[];
        end


        includeH=obj.Opts.C.includeH;
        includeM=obj.Opts.C.include;
        includeL=obj.Opts.C.includeL;
        exclude =obj.Opts.C.exclude;

        %% prvt
        %% extra
        %% lib
        %% aux
        %% bin
        %% includeH
        %% includeM
        %% includeL
        %% exclude

        vePath={obj.ve.selfPath; ...
                obj.ve.selfSrcPath; ... % REMOVED AT END
                obj.ve.binDir; ...      % REMOVED AT END
                obj.ve.basePath; ...    % REMOVED AT END
                obj.ve.aliasPath ...
               };

        default=obj.handle_default_path();

        obj.path = [ ...
                    vePath;
                    includeH;
                    default;
                    includeM;
                    prvt;
                    extra;
                    aux;
                    lib;
                    bin;
                    includeL;
                ];
    end
    function default=handle_default_path(obj)
        obj.defPathFile=[obj.dirs.root.var 'defaultPath.mat'];
        if obj.rootOpts{'bAutoDefaultPath'}
            default=Path.default();
        elseif ~Fil.exist(obj.defPathFile)
            default=Path.default();
            Fil.write(defPathFile,default,true);
            TODO save
        elseif Fil.exist(defPathFile)
            run(defPathFile);
        end
    end
    function lib=get_lib_path(obj)
        % LIB - gen
        bAdd=Struct.arrSelect(obj.Opts.I,'bAdd');
        types=Struct.arrSelect(obj.Opts.I,'type');

        %bLib=ismember(types,'lib');
        %bPrj=ismember(types,'prj');
        %bExt=ismember(types,'ext');

        if obj.bSkipPath()
            names=Struct.arrSelect(obj.Opts.I,'name',[bAdd]);
            VLDires=strcat(obj.dirs.root.varlib,filesep,names);
            cellfun(@Dir.mk_p,VLDires);
            VLFiles=strcat(VLDires,'path');
            bVLFiles=cellfun(@Fil.exist,VLfiles);

            bSel=bVLFiles;
            TODO
        else
            bSel=ones(size(bAdd));
        end
        par=Struct.arrSelect(obj.Opts.I,'dire',[bAdd & bSel]);
        lib=Path.gen(par);
        if isempty(lib)
            lib=[];
        end
    end
    function add_java_paths(obj)
        jinclude=obj.Opts.C.javainclude;
        jexclude=obj.Opts.C.javaexclude;
        if ~isempty(jinclude)
            %javaaddpath(jinclude);
            e=javaclasspath('-dynamic');
            ind=ismember(jinclude,e);
            jinclude(ind)=[];
            if ~isempty(jinclude)
                %javaclasspath('-v1');
                %javaclasspath(jinclude);
                javaaddpath(jinclude);
            end
            %javaclasspath
        end
        if ~isempty(jexclude)
            javarmpath(jexclude);
        end
    end
%% ENV
    function obj=set_env(obj)
        % REMOVE THINGS THAT WERE SET LAST TIME
        % XXX SHOULD GET PID AND IGNORE IF NOT SAME PID SESSION
        obj.clear_last_env();

        % SET
        flds=fieldnames(obj.Opts.Env);
        for i = 1:numel(flds)
            fld=flds{i};

            if ~ischar(obj.Opts.Env.(fld))
                % XXX
                continue
            end
            if contains(obj.Opts.Env.(fld),'$$')
                mtchs=regexp(obj.Opts.Env.(fld),'\$\$[A-Z_]*','match');
                for j = 1:length(mtchs)
                    ind=ismember(flds,mtchs{j}(3:end));
                    if any(ind)
                        obj.Opts.Env.(fld)=strrep(obj.Opts.Env.(fld), mtchs{j}, obj.Opts.Env.(flds{ind}));
                    end
                end
            end

            try
                setenv(fld,obj.Opts.Env.(fld));
            catch ME
                fld
                rethrow(ME)
            end
        end

        % SAVE
        obj.save_root_env_file();
        if obj.rootOpts{'bSavePrjEnv'}
            obj.save_prj_env_file();
        end
    end
    function obj=clear_last_env(obj)
        obj.read_root_env_file();
        for i = 1:length(obj.lastEnv)
            setenv(obj.lastEnv{i},'');
        end
    end
    function obj=read_root_env_file(obj)
        if Fil.exist(obj.rootEnvFile)
            obj.lastEnv=Fil.cell(obj.rootEnvFile);
        end
    end
    function obj=save_root_env_file(obj)
        if Fil.exist(obj.rootEnvFile)
            Fil.touch(obj.rootEnvFile);
        end
        Fil.rewrite(obj.rootEnvFile, fieldnames(obj.Opts.Env));
    end
    function save_prj_env_file()
        obj.prjEnvFile=[obj.dirs.prj.var 'env'];
        % TODO
        Cfg.save(obj.prjEnvFile,obj.Cfg.Env);
    end
%% HOOKS
    function obj=run_post_hooks(obj)
        for i = length(obj.Opts.I):-1:1
            if ~obj.Opts.I(i).bAdd || isempty(obj.Opts.I(i).posthook)
                continue
            end
            name=obj.Opts.I(i).name;
            hk=obj.Opts.I(i).posthook;
            obj.run_hook(name,hk);
        end
    end
    function obj=run_hook(obj,prjName,hk)
       nhk=[obj.dirs.root.tmp prjName '_hook.m'];
       if exist(hk,'file') % can't use Fil here
           copyfile(hk,nhk);
           cmd=['run(''' nhk ''')'];
           try
                evalin('base',cmd);
                if obj.rootOpts{'bHookPrint'}
                    disp(['Ran ' prjName ' hook']);
                end
            catch ME
                assignin('base',[prjName '_hookME'],ME);
                disp(['ERROR: project hook ' prjName  '''. View ''' prjName '_hookME'' in base']);
            end
            delete(nhk);
        end
    end
%% tb
%% LIB
%% GTAGS
    function obj=gen_gtags(obj)
        if obj.sys.isunix
            unix(['cd $PX_CUR_WRK && gtags &']);
        else
            disp('Gtags not yet supported for Windows')
        end
    end
    function obj=gen_gtags_all(obj)
        if obj.sys.isunix
            unix([obj.ve.selfPath 'gen_gtags.sh']);
        else
            disp('Gtags not yet supported for Windows')
        end
    end
end
methods(Static, Access=?PxPrjOptions)
    function P=get_px_parse()
        P={ ...
           'prj',[],'ischar_e';
           'bForce',false,'Num.isBinary';
           'compileFnames','','ischarcell';
        };

    end
    function P=get_root_configs_parse()
        P={ ...
           'bHistory', false, 'isBinary'; ...
           'bAutoSaveHistory',false,'isBinary'; ...
           'bWorkspace', true, 'isBinary';...
           'bAutoSaveWorkspace',true,'isBinary'; ...
           'bCompilePromt',false,'isBinary'; ...
           'bAutoCompile',false, 'isBinary'; ...
           'bForceCompile', false, 'isBinary';...
           'bDiary',false,'isBinary';...
           'bRootDiary',false,'isBinary';...
           'bLockLib',false,'isBinary';
           'externalEditor', '','ischar';
           'pager','','ischar';...
           'bMedia',true, 'isBinary';... % DONE
           'bData',true, 'isBinary';...  % DONE
           'bGtags',false, 'isBinary'; ...       % DONE
           'bProjectile', false, 'isBinary'; ... % DONE
           'bGitIgnore',false, 'isBinary';...
           'bHookPrint',true,'isBinary';... % DONE
           'ignoreDirs',Px.DEFAULTIGNORE,'iscell'; ... % DONE
           'bClcOnReload', true, 'isBinary';  ... %% DONE
           'bSession',true, 'isBinary';
           'bClcOnSwitch', true, 'isBinary';  ... %% DONE
           'bClearOnSwitch',true,'isBinary';  ... %% DONE
           'writeDir','','ischar';                     % TEST
           'AutoSwitchOnCd', true, 'isBinary'; ... % XXX?
           'bSavePrjEnv',false,'isBinary'; % XXX?
           'bAutoPathGenOnStartup',true,'isBinary';  % TEST
           'bAutoPathGenOnSwith',true,'isBinary';    % TEST
           'bAutoDefaultPath',true,'isBinary';  %  allow path caching of default
           'bMakeDirsOnSwitch',false,'isBinary';       % TEST

           'readmeExt','.txt','ischar';
           'todoExt','.txt','ischar';
           'notesExt','.txt','ischar';

           'configEditor','matlab','ischar';
           'readmeEditor','matlab','ischar';
           'todoEditor','matlab','ischar';
           'notesEditor','matlab','ischar';
          };
    end
end
end

    %%         FilDir.easyln(src,dest,0,obj.sys.home);

    %%         %if (~ispc && ~exist([obj.dirs.lnk.wrk name],'dir')) || (ispc && ~exist([obj.dirs.lnk.wrk name],'file'))
    %%         %
    %%         obj.dirs.wrk{end+1}=dest;
    %%     end
    %% end
