classdef PxInstaller < handle
properties
    ve
    bInstalled

    instFile
    args
    oldInstall
end
properties(Constant)
    MODES={'installPx','install2','reinstallPx'}
end
methods(Access={?VE,?InstallerTools})
    function obj=PxInstaller(ve)
        obj.ve=ve;
        obj.get_install_status();
        if ~obj.bInstalled
            obj.init_install_dir();
        end
    end
    function obj=get_install_status(obj);
        obj.instFile=[obj.ve.intDir 'installed'];
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
    function parse_args(obj)
        P=PxInstaller.get_parse();
        % XXX
    end
    function mode_handler(obj);
        switch obj.mode
        case 'insallPx'
            if obj.bInstalled
                error('Px already installed');
            end
            obj.install_px(varargin{2:end});
            return
        case 'uninstallPx'
            obj.uninstall_px();
            return
        case 'reinstallPx'
            clear Px Px_util;
            rehash path;
            obj.reinstall_px(varargin{2:end});
            return
        case 'install2'
            obj.selfPath=varargin{2};
            obj.root=varargin{3};
            obj.rootconfigfile=varargin{4};
            obj.linkPrj=varargin{5};

            obj.setup_base_tools();
            obj.config_root();
            return
        end
    end
    function obj=reinstall(obj,varargin)
        installLoc=varargin{1};
        if ~endsWith(installLoc,filesep)
            installLoc=[installLoc filesep];
        end
        if ~exist(installLoc,'dir')
            error(['Install path ' installLoc '  does not exist']);
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
    function obj=install(obj,varargin);
        oldPath=path;
        assignin('base','oldPath','path');
        bComplete=false;
        %cl=onCleanup(@() Px.restore_path(bComplete,old));

        restoredefaultpath;
        if length(varargin) == 0
            error('Px Install: install destination directory required for first parameter');
        end

        % INSTALLOC
        installLoc=varargin{1};
        if ~endsWith(installLoc,filesep)
            installLoc=[installLoc filesep];
        end
        installLoc=strrep(installLoc,'../',Dir.parent(pwd));
        rootpar=obj.parent(installLoc);
        if ~exist(rootpar,'dir')
            error(['Install location ' rootpar ' does not exist. Manually make this directory fi this is intentional.']);
        end
        obj.root=[installLoc];

        % PRJLOC
        if length(varargin) > 1
            prjLoc=varargin{2};
        else
            prjLoc='';
        end
        if ~endsWith(prjLoc,filesep)
            prjLoc=[prjLoc filesep];
        end
        prjLoc=strrep(prjLoc,'../',Dir.parent(pwd));
        if ~exist(prjLoc,'dir')
            error(['Project location ' prjLoc ' does not exist. Manually make this directory if this is intentional.']);
        elseif ~isempty(prjLoc) && ~strcmp(prjLoc,[obj.root 'prj' filesep])
            movefile(prjLoc,[obj.root 'prj']);
        end

        % LIBLOC
        if length(varargin) > 2
            libLoc=varargin{3};
        else
            libLoc='';
        end
        if ~endsWith(libLoc,filesep)
            libLoc=[libLoc filesep];
        end
        libLoc=strrep(libLoc,'../',Dir.parent(pwd));
        if ~isempty(libLoc) && ~exist(libLoc,'dir')
            error(['Lib location ' libLoc ' does not exist. Manually make this directory if this is intentional.']);
        elseif ~isempty(libLoc) && ~strcmp(libLoc,[obj.root 'lib' filesep])
            movefile(libLoc,[obj.root 'lib']);
        end
        obj.make_restore_dire(oldPath,prjLoc,libLoc);

        %OPTIONS
        if length(varargin) > 3
            opts=struct(varargin{3:end});
        else
            opts=struct();
        end
        obj.parse_installPx(opts);

        obj.move_self();
        out=obj.find_install_config();
        if out
            obj.copy_config();
        end
        old=cd(obj.selfPath);
        %cl=onCleanup(@() cd(old));
        %obj.setup_base_tools();

        obj.handle_startup();
        %Px('install2',obj.selfPath,obj.root,obj.rootconfigfile,obj.linkPrj);

        fname=[obj.ve.intDir '.installed'];
        fclose(fopen(fname, 'w'));
        bComplete=true;

        clear Px Px_util;
        rehash path;
        obj.setup_base_tools();

        clear Px Px_util;
        rehash path;

        disp('New path applied. Old path assigned to your workspace as ''oldPath''');

        %disp('Run ''clear Px Px_util Px_git startup; startup''')
        %cur=[obj.selfPath 'postinstall'];
        addpath(pwd);


        evalin('base','postinstall');
        obj.rm_install_files();

        %cd(obj.selfPath);
        %Px.startup();
    end
    function make_restore_dire(obj,oldPath,prjLoc,libLoc)
        restoreDir=[obj.selfPath '.restore' filesep];
        mkdir(restoreDir);

        Dir.write([restoreDir 'oldPath'],oldPath,true);
        if ~isempty(prjLoc)
            Dir.write([restoreDir 'prjLoc'],prjLoc,true);
        end
        if ~isempty(libLoc)
            Dir.write([restoreDir 'libLoc'],libLoc,true);
        end

    end
    function rm_install_files(obj)
        Dir.rm_rf(obj.oldInstall);
    end
    function handle_startup(obj)
        text=['cd ' obj.selfPath '; Px.startup; %PXSTARTUP'];

        fname=which('startup');
        if ~isempty(fname) && Fil.contains(fname,'%PXSTARTUP');
            return
        elseif ~isempty(fname)
            dir=fileparts(fname);
        end

        up=userpath;
        if isempty(up)
            up=[ getenv('HOME') filesep 'Documents' filesep 'MATLAB' ];
        end

        if ~isempty(fname) &&  contains(dir,matlabroot)
            fname=[up filesep 'startup.m'];
            fid = fopen(fname, 'w');
        elseif ~isempty(fname)
            fid = fopen(fname, 'a');
        else
            error('Cannot find suitable startup file');
        end
        cl=onCleanup(@() fclose(fid));
        fprintf(fid, '%s', text);
    end
    function opts=parse_installPx(obj,opts)
        % TODO
    end
    function out=find_install_config(obj,opts)
        out=false;
        fname=[obj.selfPath 've.cfg'];
        if exist(fname,'file')
            obj.rootconfigfile=fname;
            out=true;
        end
    end
    function obj=copy_config(obj)
        etc=[obj.root 'etc' filesep];
        if ~exist(etc,'dir')
            mkdir(etc);
        end
        dest=[etc 've.cfg'];
        copyfile(obj.rootconfigfile, dest);
        obj.rootconfigfile=dest;
    end
    function obj=move_self(obj)
        if ~exist(obj.root,'dir')
            mkdir(obj.root);
        end
        obj.oldInstall=obj.selfPath;
        dest=[obj.root 'boot' filesep];
        copyfile(obj.selfPath,dest);
        obj.selfPath=dest;
    end
end
methods(Static)
    function P=get_parse()
        P={ ...
           'bTest',[],'isBinary';...
           'bForce',[],'isBinary'; ...
           'root',[],'ischar_e'; ...
           'installDir',[],'ischar_e';
           'linkPrj',[],'ischar_e'
           'prjLoc',[],'ischar_e';
           'libLoc',[],'ischar_e';
           'etcLoc',[],'ischar_e';
           'extLoc',[],'ischar_e';
           'datLoc',[],'ischar_e';
           'medLoc',[],'ischar_e';
        };
    end
end
end
