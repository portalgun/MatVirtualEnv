classdef PxInstaller < handle
properties
    ve
    opts=struct()
    bInstalled
    restoreDir


    instFile
    srcInstlrFile
    destInstlrFile
    oldPath
    oldInstall
    bComplete=false
end
properties(Constant)
    MODES={'installPx','install2','reinstallPx'}
end
methods(Access={?VE,?InstallerTools})
    function obj=PxInstaller(ve)
        obj.ve=ve;
        obj.get_install_status();

        if ismember(obj.ve.mode,PxInstaller.MODES)
            obj.init_install_dir();
        end
    end
    function obj=get_install_status(obj);
        obj.instFile=[obj.ve.intDir '.installed'];
        obj.destInstlrFile=[obj.ve.bootDir '.installer'];
        obj.srcInstlrFile=[obj.ve.selfPath '.installer'];
        if ~exist(obj.ve.bootDir,'dir') || ~exist(obj.ve.intDir,'dir')
            obj.bInstalled=false;
        else
            obj.bInstalled=logical(exist(obj.instFile,'file'));
        end
    end
    function obj=init_install_dir(obj);
        % XXX TODO CLEANUP ON FAILUR
        bInstallDir=false;
        bRootDir=false;
        bBootDir=false;
        bLibDir=false;
        bBinDir=false;
        if ~exist(obj.ve.installDir,'dir')
            mkdir(obj.ve.installDir);
        end
        if ~exist(obj.ve.rootDir,'dir')
            mkdir(obj.ve.rootDir);
        end
        if ~exist(obj.ve.bootDir,'dir')
            mkdir(obj.ve.bootDir);
        end
        if ~exist(obj.ve.libDir,'dir')
            mkdir(obj.ve.libDir);
        end
        if ~exist(obj.ve.binDir,'dir')
            mkdir(obj.ve.binDir);
        end
        if ~exist(obj.ve.intDir,'dir')
            mkdir(obj.ve.intDir);
        end
    end
%%%
    function exitflag=mode_handler(obj);
        exitflag=false;
        switch obj.ve.mode
        case 'installPx'
            if obj.bInstalled
                exitflag=true;
                PxUtil.warnSoft('MVE already installed');
                out=PxUtil.yn('Reinstall');
                if out==1
                    obj.reinstall_px();
                end
                return
            end
            obj.install_px();
            return
        case 'uninstallPx'
            obj.uninstall_px();
            return
        case 'reinstallPx'
            obj.reinstall_px();
            return
        end
    end
    function obj=reinstall_px(obj,varargin)
        installLoc=obj.ve.installDir;
        if ~endsWith(installLoc,filesep)
            installLoc=[installLoc filesep];
        end
        if ~exist(installLoc,'dir')
            error(['Install path ' installLoc ' does not exist']);
        end

        if logical(exist([installLoc '.internal' filesep '.installed']));
            error(['Px not installed at ' installLoc ]);
        end
        obj.root=[installLoc '.px' filesep 'boot' filesep]; % XXX

        Px.rm_rf([obj.root 'MatBaseTools']);
        Px.rm_rf(obj.root);

        %% UNLINK PRJ
        if length(varargin) > 1
            prjLoc=varargin{2};
        else
            prjLoc=[];
        end
        if ~endsWith(prjLoc,filesep)
            prjLoc=[prjLoc filesep];
        end
        %Px.unlink(prjLoc); XXX


        %% INSTALL
        obj.install_px(varargin{:});


    end
    function dire_fun(obj,name)
        errstr='%s %s does not exist. Manually make this directory if this is intentional.';
        if ~isempty(obj.opts.(name)) && ~endsWith(obj.opts.(name),filesep)
            obj.opts.(name)=[obj.opts.(name) 'filesep'];
        end
        src=obj.opts.(name);
        dest=obj.ve.(name);
        bSame=strcmp(src,dest);

        fld=regexprep(name,'Dir$','');
        fld(1)=upper(fld(1));
        moveOpt=obj.opts.(['moveOpt' fld]);

        if (isempty(src) || bSame) && ~Dir.exist(dest)
            mkdir(dest);
        elseif ~~isempty(src) && Dir.exist(src)
            error(errstr,name,src);
        elseif ~isempty(src) && ~bSame
            if moveOpt==0
                copyfile(src,dest);
            elseif moveOpt==1
                movefile(src, dest);
                Dir.write([obj.restoreDir name],src,true);
            elseif moveOpt==2
                FilDir.easyln(src,dest);
            end
        end

    end
    function obj=install_px(obj,varargin);
        installLoc=obj.ve.installDir;
        obj.parse_installPx();

        obj.make_restore_dire;
        %cl=onCleanup(@() Px.restore_path(bComplete,old));

        % Make/link DIRECTORIES
        P=PxInstaller.getP();
        for i = 1:size(P,1)
            name=P{i,1};
            if startsWith(name,'moveOpt')
                continue
            end
            obj.dire_fun(name);
        end

        obj.move_self();

        obj.copy_config();

        obj.handle_startup();

        obj.mark_installed();

        restoredefaultpath;
        cd(obj.ve.bootDir);
        clear VE Px Px_util
        disp('Path reset. Old path assigned to your workspace as ''oldPath''');
        %evalin('base','VE.startup;');
        VE.startup;

    end
    function mark_installed(obj)
        fclose(fopen(obj.instFile, 'w'));
        obj.bComplete=true;
    end
    function oldPath=make_restore_dire(obj)
        obj.restoreDir=[obj.ve.bootDir '.restore' filesep];
        if ~Dir.exist(obj.restoreDir)
            mkdir(obj.restoreDir);
        end
        fil=[obj.restoreDir 'oldPath'];
        if ~Fil.exist(fil)
            Fil.write(fil,obj.ve.lastPath,true);
            oldPath=obj.ve.lastPath;
        else
            oldPath=Fil.cell(fil);
            oldPath=oldPath{1};
        end
        assignin('base','oldPath',oldPath);
    end
    function rm_install_files(obj)
        Dir.rm_rf(obj.oldInstall);
    end
    function handle_startup(obj)
        txt=['cd ' obj.ve.bootDir '; VE.startup; %MVE STARTUP'];

        fname=obj.ve.startupFile;
        if ~isempty(fname) && Fil.contains(fname,'%MVE STARTUP');
            return
        elseif ~isempty(fname)
            dire=fileparts(fname);
        end

        up=obj.ve.userPath;
        if isempty(up)
            up=[ getenv('HOME') filesep 'Documents' filesep 'MATLAB' ];
        end

        if (isempty(fname) && Dir.exist(up)) || (~isempty(fname) && contains(dire,matlabroot))
            fname=[up filesep 'startup.m'];
            fid = fopen(fname, 'w');
        elseif ~isempty(fname)
            fid = fopen(fname, 'a');
        else
            error('Cannot find suitable startup file or location to create one');
        end
        cl=onCleanup(@() fclose(fid));
        fprintf(fid, '%s', txt);
    end
    function opts=parse_installPx(obj,opts)
        obj.opts=Args.parse([],PxInstaller.getP(),obj.ve.args);
    end
    function out=find_install_config(obj,opts)
    end
    function copy_config(obj)
        out=false;
        fname=[obj.ve.selfPath 've.cfg'];
        if ~exist(fname,'file')
            return
        end
        if ~Dir.exist(obj.ve.etc)
            mkdir(obj.ve.etc);
        end
        dest=[etc 've.cfg'];
        copyfile(fname, dest);
    end
    function obj=move_self(obj)
        copyfile(obj.ve.selfPath,obj.ve.bootDir);
        if exist(obj.destInstlrFile,'file')
            delete(obj.destInstlrFile);
        end
    end
end
methods(Static)
    function P=getP()
        P={ ...
           'moveOptPrj',0,'isbinary_e';
           'moveOptLib',0,'isbinary_e';
           'moveOptEtc',0,'isbinary_e';
           'moveOptExt',0,'isbinary_e';
           'moveOptMed',0,'isbinary_e';
           'moveOptDat',0,'isbinary_e';
           'prjDir','','ischar_e';
           'libDir','','ischar_e';
           'etcDir','','ischar_e';
           'extDir','','ischar_e';
           'medDir','','ischar_e';
           'datDir','','ischar_e';
        };
    end
end
end
