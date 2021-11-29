classdef PxPrjOptions < handle
properties
    I
    C
    Env
end
properties(Access=private)
    rootCfgFlds
    PX
end
methods
    function obj=PxPrjOptions(PX)

        obj.PX=PX;
        obj.rootCfgFlds=fieldnames(obj.PX.rootOpts);
        obj.I=obj.parse_configs(PX.Cfg.Cfgs);
        obj.merge_opts();
    end
    function Opts=parse_configs(obj,CFGS)
        Opts=[];

        for i = 1:size(CFGS,1)
            prj=CFGS{i,1};
            type=CFGS{i,2};
            dire=CFGS{i,3};
            opts=CFGS{i,4};
            Opts=[Opts obj.parse_config(prj,type,opts,dire)];
        end
    end
    function Opts=parse_config(obj,name,type,cfg,dire)
        Opts=obj.get_opts(name,type,cfg,dire);
        if ~isempty(Opts.matVersion)
            Opts.matVersion=Mat.versionToNum(Opts.matVersion); % TODO
        end
        Opts=obj.get_opt_alt_location(Opts);
        Opts=obj.find_opt_local_hooks(Opts);
        Opts=obj.set_opt_defaults(Opts);

        Opts=obj.get_opt_errors(Opts);
    end
    function out=select_options(obj,name)
        ind=0;
        if strcmp(name,obj.prj)
            out=vertcat(obj.Options(1));
            return
        else
            for i = 1:length(obj.Options)
                if strcmp(name,obj.Options(i).name)
                    ind=i;
                    break
                end
            end
        end
        if ind==0
            error(['No found dependency of the name ' name ]);
        end
        out=vertcat(obj.Options(ind));
    end
    function Opts=get_opts(obj,name,type,cfg,dire);
        Opts=obj.init_Options();
        Opts.name=name;
        Opts.type=type;
        Opts.dire=Dir.parse(dire);
        % TODO normalize

        Opts.exist=Dir.exist(dire);
        if Opts.exist
            Opts.bAdd=true;
        end
        if isnumeric(cfg) && isnan(cfg)
            return
        end

        % OPTIONAL
        if isfield(cfg,'optional')
            Opts.bOptional=(isnan(optional) || logical(cfg.optional));
            cfg.bOptional=cfg.optional;
            cfg=rmfiled(cfg,'optional');
        elseif isfield(cfg,'bOptional')
            Opts.bOptional=(isnan(bOptional) || logical(cfg.bOptional));
        end
        % bRm
        if isfield(cfg,'exclude')
            if isnumeric(cfg.exclude) && isnan(cfg.exclude) || cfg.exclude
                Opts.bRm=true;
                Opts.bAdd=false;
            end
            cfg.bRm=cfg.rm;
            cfg=rmfiled(cfg,'rm');
        elseif isfield(cfg,'bRm') && cfg.bRm
            Opts.bRm=true;
            Opts.bAdd=false;
        end

        skipopts={'location','bOptional','bRm','bJavaPath','setupFile'};
        opts={'version','site','bGitIgnore','matVersion','bAutoCompile','setupfile','prehook','posthook'};
        listOpts={'javainclude','javaexclude','includeH','inlcude','includeL','exclude','mex'};
        flds=fieldnames(cfg);
        if ismember('env',flds)
            Opts.env=cfg{'env'};
        end
        for i = 1:length(flds)
            fld=flds{i};
            if ismember(fld,skipopts)
                continue
            elseif ismember(fld,opts)
                Opts.(fld)=cfg{fld};
            elseif ismember(fld,listOpts)
                if isa(cfg{fld},'dict') && numel(fieldnames(cfg{fld})) < 1
                    Opts.(fld)={''};
                else
                    Opts.(fld)=cfg{fld};
                end
                % XXX handle diff if char struct
            elseif strcmp(fld,'env')
                continue
            elseif ismember(fld,obj.rootCfgFlds)
                if isnan(cfg{fld})
                    Opts.root__{fld}=1;
                else
                    Opts.root__{fld}=cfg{fld};
                end
            else
                Opts.env{fld}=cfg{fld};
            end
        end

    end
    function Opts=get_opt_errors(obj,Opts)
        if ~Opts.exist
            Opts.error.notexist=true;
        end
        if ~Opts.bAdd && Opts.bAdd
            Opts.error.bothaddandrm=true;
        end
        if Opts.matVersion > obj.PX.mat.version
            Opts.error.notmatVersion=true;
        end
        if ~isempty(Opts.prehook)  && ~Fil.exist(Opts.prehook)
            Opts.error.notexistprehook=true;
        end
        if ~isempty(Opts.posthook)  && ~Fil.exist(Opts.posthook)
            Opts.error.notexistposthook=true;
        end
        if ~isempty(Opts.includeL) n=length(Opts.includeL);
            Opts.error.notexistinclude=false(n,1);
            for i = 1:n
                if Dir.exist(Opts.includeL{i})
                    Opts.error.notexistincludeL(i)=true;
                end
            end
        end
        if ~isempty(Opts.include) n=length(Opts.include);
            Opts.error.notexistinclude=false(n,1);
            for i = 1:n
                if Dir.exist(Opts.include{i})
                    Opts.error.notexistinclude(i)=true;
                end
            end
        end
        if ~isempty(Opts.includeH) n=length(Opts.includeH);
            Opts.error.notexistinclude=false(n,1);
            for i = 1:n
                if Dir.exist(Opts.includeH{i})
                    Opts.error.notexistincludeH(i)=true;
                end
            end
        end
        if ~isempty(Opts.exclude)
            n=length(Opts.exclude);
            Opts.error.notexistexclude=false(n,1);
            for i = 1:n
                if ~Dir.exist(Opts.exclude{i})
                    Opts.error.notexistexclude(i)=true;
                end
            end
        end
        if ~isempty(Opts.javainclude)
            n=length(Opts.javainclude);
            Opts.error.notexistjavainclude=false(n,1);
            for i = 1:n
                if ~Fil.exist(Opts.javainclude{i})
                    Opts.error.notexistjavainclude(i)=true;
                end
            end
        end
        if ~isempty(Opts.javaexclude)
            n=length(Opts.javaexclude);
            Opts.error.notexistjavaexclude=false(n,1);
            for i = 1:n
                if ~Fil.exist(Opts.javaexclude{i})
                    Opts.error.notexistjavaexclude(i)=true;
                end
            end
        end
    end
    function Opts=find_opt_local_hooks(obj,Opts)
        basedir=[obj.PX.dirs.root.etc Opts.name '.d' filesep];
        post=[basedir 'posthook.m'];
        pre=[basedir 'pre.m'];
        if Fil.exist(post)
            Opts.posthook=post;
        end
        if Fil.exist(pre)
            Opts.prehook=pre;
        end
    end
    function Opts=get_opt_alt_location(obj,Opts)
        flds=fieldnames(Opts.env);
        ind=ismember(flds,{'ext','location'});

        if ~any(ind)
            return
        end
        fld=flds{ind};
        Opts.dire=Opts.env{'ext'};
        Opts.env=rmfield(Opts.env,fld);
        Opts.exist=Dir.exist(Opts.dire);
        if (isempty(Opts.bRm) || ~Opts.bRm) && Opts.exist
            Opts.bAdd=true;
        end
    end
    function Opts=set_opt_defaults(obj,Opts)
        flds=fieldnames(Opts);
        if isempty(Opts.matVersion)
            Opts.matVersion=0;
        end
        if isempty(Opts.version)
            Opts.version=0;
        end
        for i = 1:length(flds)

            fld=flds{i};

            if Str.RE.ismatch(fld,'^b[A-Z]+.*')
                if isempty(Opts.(fld))
                    Opts.(fld)=false;
                elseif isnan(Opts.(fld))
                    Opts.(fld)=true;
                end
            end
        end
        if ~ismember(flds,'mex')
            Opts.mex={};
        end
    end
    function Options=init_Options(obj)
        Options=struct();
        Options.type=[];
        Options.name=[];

        Options.dire='';
        Options.exist=[];
        Options.bAdd='';
        Options.bRm='';
        Options.bJavaPath='';

        Options.site='';
        Options.version='';
        Options.bOptional='';

        Options.setupFile='';
        Options.prehook='';
        Options.posthook='';

        Options.matVersion='';
        Options.bGitIgnore='';

        Options.javapath={};
        Options.javainclude={};
        Options.javaexclude={};
        Options.include={};
        Options.includeH={};
        Options.includeL={};
        Options.exclude={};
        Optsions.mex=dict();
        Options.env=dict();
        Options.root__=dict();

        Options.error=obj.init_opt_errors();
    end
    function errors=init_opt_errors(obj)
        errors=struct('notexist',false, ...
                      'notexistprehoook',false,...
                      'notexistinclude',false,...
                      'notexistexclude',false,...
                      'notexistjavainclude',false,...
                      'notexistjavaexclude',false,...
                      'notexistposthoook',false,...
                      'notmatversion',false, ...
                      'bothaddandrm',false  ...
                     );
    end
%% MERGE
    function merge_opts(obj)
        obj.C.javainclude=obj.merge_opts_java_include();
        obj.C.javaexclude=obj.merge_opts_java_exclude();
        obj.C.include=obj.merge_opts_include();
        obj.C.includeH=obj.merge_opts_includeH();
        obj.C.includeL=obj.merge_opts_includeL();
        obj.C.exclude=obj.merge_opts_exclude();
        obj.merge_root_opts();
        obj.Env=obj.merge_opts_env;
    end
    function INC=merge_opts_java_include(obj)
        INC={};
        for i = 1:length(obj.I)
            add=[obj.I(i).javainclude];
            if isempty(add)
                continue
            end
            ind=~obj.I(i).error.notexistjavainclude;
            ind=~obj.I(i).error.notexistjavainclude;
            INC=[INC; add(ind)];
        end
    end
    function INC=merge_opts_java_exclude(obj)
        INC={};
        for i = 1:length(obj.I)
            add=[obj.I(i).javaexclude];
            if isempty(add)
                continue
            end
            ind=~obj.I(i).error.notexistjavaexclude;
            INC=[INC; add(ind)];
        end
    end
    function INC=merge_opts_include(obj)
        INC={};
        for i = 1:length(obj.I)
            add=[obj.I(i).include];
            if isempty(add)
                continue
            end
            ind=~obj.I(i).error.notexistinclude;
            INC=[INC; add(ind)];
        end
    end
    function INC=merge_opts_includeH(obj)
        INC={};
        for i = 1:length(obj.I)
            add=[obj.I(i).includeH];
            if isempty(add)
                continue
            end
            ind=~obj.I(i).error.notexistincludeH;
            INC=[INC; add(ind)];
        end
    end
    function INC=merge_opts_includeL(obj)
        INC={};
        for i = 1:length(obj.I)
            add=[obj.I(i).includeL];
            if isempty(add)
                continue
            end
            ind=~obj.I(i).error.notexistincludeL;
            INC=[INC; add(ind)];
        end
    end
    function INC=merge_opts_exclude(obj)
        INC={};
        for i = 1:length(obj.I)
            add=[obj.I(i).exclude];
            if isempty(add)
                continue
            end
            ind=~obj.I(i).error.notexistexclude;
            INC=[INC; add(ind)];
        end
    end
    function E=merge_opts_env(obj)
        S=struct();
        for i = 1:length(obj.I)
            cur=obj.I(i).env;
            flds=fieldnames(cur);
            if isempty(flds)
                continue
            end
            name=Str.Alph.upper(obj.I(i).name);
            for i = 1:length(flds)
                fld=flds{i};
                FLD=[name '__' Str.Alph.upper(fld)];
                val=cur{fld};
                if isnumeric(val)
                    val=Num.toStr(val);
                end
                if iscell(val)
                    continue
                end
                S.(FLD)=val;
            end
        end
        p=obj.get_px_env_opts();
        E=struct(p{:});
        e=Env.read([],obj.PX.dirs.root.etc,obj.PX.sys.hostname,obj.PX.sys.os);
        E=Struct.combinePref(E,e);
        if numel(fieldnames(S)) > 0
            E=Struct.combinePref(S,E);
        end
    end
    function merge_root_opts(obj)
        % XXX NEED OT INSURE OPTIONS ARE ONLY GETTING IN FROM ETC AND ROOT
        prjRootOptions=obj.I(1).root__;
        obj.C.root=prjRootOptions.mergePref(obj.PX.rootOpts,false,true);
        if ismember(fieldnames(prjRootOptions),'ignoreDirs')
           Error.warnSoft(['The ''ignoreDirs'' option is a root VE option.' newline ...
                           'Use the ''exlude'' option to ignore directories on a project level.' newline ...
                           'If you want to change this on the root level, specify it in your root configuration file.']);
        end
    end
    function vars=get_px_env_opts(obj)
        media='';
        if obj.C.root{'bMedia'}
            media=obj.PX.dirs.lnk.media;
        end
        data='';
        if obj.C.root{'bData'}
            data=obj.PX.dirs.lnk.data;
        end
        vars={'PX_INSTALL',obj.PX.ve.selfPath, ...
              'PX_ROOT',obj.PX.ve.rootDir ...
              'PX_ETC',obj.PX.dirs.root.etc, ...
              'PX_VAR',obj.PX.dirs.root.etc, ...
              'PX_LIB',obj.PX.dirs.root.etc, ...
              'PX_PRJS_ROOT',obj.PX.dirs.root.prj, ...
              'PX_CUR_PRJ_NAME',obj.PX.prj, ...
              'PX_CUR_PRJ_DIR',obj.PX.dirs.lnk.wrk, ...
              'PX_CUR_BIN',obj.PX.dirs.lnk.bin, ...
              'PX_LOG',obj.PX.dirs.prj.log, ...
              'PX_TMP',obj.PX.dirs.root.tmp, ...
              'PX_CUR_PRJ_SRC',obj.PX.dirs.prj.prj, ...
              'PX_CUR_MEDIA',media, ...
              'PX_CUR_DATA',data, ...

        };
        %'PX_CUR_VAR_DIR',obj.PX.dirs.lnk.var, ...
    end

end
end
