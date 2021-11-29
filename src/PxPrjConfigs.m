classdef PxPrjConfigs < handle
properties
    Cfgs
    seen={}
    etc
end
properties(Access=private)
    PX
end
methods
    function obj=PxPrjConfigs(PX)
        obj.PX=PX;
        obj.Cfgs=obj.get_prj_configs(obj.PX.prj,'prj',obj.PX.dirs.prj.prj,struct());
    end
    function OUT=get_prj_configs(obj,prj,type,dire,parcfg)
        cfg=dict();
        cfgFname=[dire '.px'];
        if Fil.exist(cfgFname)
            cfg=Cfg.read(cfgFname,[],[],obj.PX.sys.hostname);
        end

        %OUT={prj type dire parcfg};
        obj.etc=obj.read_etc_config(prj);
        if ~isempty(obj.etc) && ~isempty(cfg)
            cfg=obj.cfg_combine_fun(obj.etc,cfg,prj);
        elseif ~isempty(obj.etc)
            cfg=obj.etc;
        end
        if numel(fieldnames(parcfg)) > 0
            cfg=obj.cfg_combine_fun(parcfg,cfg,prj);
        end
        if isempty(cfg)
            OUT={prj type dire parcfg};
            return
        end

        [PRJS,TYPES,DIRS,OPTS]=obj.split_config(cfg,prj,type,dire);


        if isempty(PRJS)
            OUT=[];
        end
        OUT={PRJS{1} TYPES{1} DIRS{1} OPTS{1}};
        for i = 2:length(PRJS)
            out=obj.get_prj_configs(PRJS{i},TYPES{i},DIRS{i},OPTS{i});
            OUT=[OUT; out];
        end
    end
    function cfg=read_etc_config(obj,name);
        cfg=[];
        fname=[obj.PX.dirs.root.etc name '.config'];
        if Fil.exist(fname)
            cfg=Cfg.read(fname,[],[],obj.PX.sys.hostname);
        end
    end
    function [NAMES,TYPES,DIRS,OPTS]=split_config(obj,cfg,name,type,dire)
        % HANDLE config ALIASES
        NAMES={name};
        TYPES={type};
        DIRS={dire};
        OPTS={dict};
        flds=fieldnames(cfg);
        for i =1:length(flds)
            fld=flds{i};
            if ~isa(cfg{fld},'dict')
                FLD=type;
                OPTS{1}{fld}=cfg{fld};

                %% if strcmp(fld,'javainclude')
                %%     777777777777777777777
                %%     %cfg
                %%     %cfg{fld}
                %%     OPTS{1}{fld}
                %%     888888888888888888888
                %% end

                continue
            end
            switch Str.Alph.lower(fld)
                case {'l','lib','library'}
                    dire=obj.PX.dirs.root.lib;
                    FLD='lib';
                case {'e','ext','external'}
                    dire=obj.PX.dirs.root.ext;
                    FLD='ext';
                case {'p','prj','project'}
                    dire=obj.PX.dirs.root.prj;
                    FLD='prj';
                otherwise
                    FLD=type;
                    OPTS{1}{fld}=cfg{fld};
                    continue
            end
            prjs=fieldnames(cfg{fld});
            for i = 1:length(prjs)
                prj=prjs{i};
                NAMES{end+1,:}=prj;
                TYPES{end+1,:}=FLD;
                OPTS{end+1,:}=cfg{fld}{prj};
                %if ischar(OPTS{end}) && startsWith(NAMES{end},'FLD__')
                    %NAMES{end}=OPTS{end};
                    %OPTS{end}=dict();
                    %dk
                if ~isa(OPTS{end},'dict') && (isempty(OPTS{end}) || (isnumeric(OPTS{end}) && isnan(OPTS{end})))
                    OPTS{end}=dict();
                end
                if isfield(OPTS{end},'location')
                    DIRS{end+1,:}=OPTS{end}.location;
                elseif strcmp(TYPES{end},'ext') && isfield(OPTS{end},'ext')
                    DIRS{end+1,:}=OPTS{end}.ext;
                else
                    DIRS{end+1,:}=[dire prj filesep];
                end
            end
        end
        IND=ismember(DIRS,obj.seen);
        IND(1)=false;
        NAMES(IND)=[];
        TYPES(IND)=[];
        DIRS(IND)=[];
        OPTS(IND)=[];
        obj.seen=[obj.seen; DIRS];

    end
    function Cfgs=cfg_combine_fun(obj,Cfgs1,Cfgs2,name)
        if isfield(Cfgs1,'env')
            env=Cfgs1{'env'};
            Cfgs1.rmfield('env');
            Cfgs1=Cfgs1.mergePref(env,0,false);
        end
        if isfield(Cfgs2,'env')
            env=Cfgs2{'env'};
            Cfgs2.rmfield('env');
            %Cfgs2=Struct.combinePref(Cfgs2,env,0,false);
            Cfgs2=Cfgs2.mergePref(env,0,true);
        end
        Cfgs=Cfgs1.mergePref(Cfgs2,0,true);
        cellflds={'javainclude','javaexclude','include','exclude','mex'};
        for i = 1:length(cellflds)
            fld=cellflds{i};
            if isfield(Cfgs1,fld) && isfield(Cfgs2,fld)
                Cfgs{fld}=[Cfgs1{fld}; Cfgs2{fld}];
            end
        end
    end

end
end
