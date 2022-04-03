classdef BaseInstaller < handle
properties
    ve
    bInstalled
    bCompiled
    bCompilable
    bForce
    warn

    mbDir
    mbBinDir
    dlFile
    instFile
    cmpFile
    bRestoreOnCl=false
    bMexSetup
end
properties(Constant)
    BASEURL='https://github.com/portalgun/MatBaseTools'
    BASEV='master'
    MODES={}
end
%methods(Access={?PxInstaller,?Px,?VE})
methods
    function obj=BaseInstaller(ve)
        %cl=onCleanup(@() obj.restore_path_on_cl());
        obj.ve=ve;

        obj.cmpFile=[obj.ve.intDir 'mb_compiled'];
        obj.instFile=[obj.ve.intDir 'mb_installed'];
        obj.dlFile=[obj.ve.intDir '.mb'];

        if obj.ve.opts.bMBTReinstall;
            obj.rm();
        end
        obj.get_install_status();
        obj.install();
    end
    function rm(obj)
        if exist(obj.mbBinDir,'dir')
            delete([obj.mbBinDir '\*']);
        end
        if exist(obj.mbDir,'dir')
            delete([obj.mbDir '\*']);
        end
        if exist(obj.instFile,'file')
            delete(obj.instFile);
        end
        if exist(obj.cmpFile,'file')
            delete(obj.cmpFile);
        end
        if exist(obj.dlFile,'file')
            delete(obj.dlFile);
        end
    end
    function install(obj)
        if ~obj.bInstalled
            obj.download();
        end
        obj.add_path;
        if ~obj.bInstalled
            PxUtil.touch(obj.instFile);
            obj.bInstalled=true;
        end

        obj.get_compiled_status();
        if ~isempty(obj.warn)
            warning(obj.warn,'off');
            cl=onCleanup(@(x) warning(obj.warn,'on'));
        end
        if ~obj.bCompiled || obj.ve.opts.bMBTRecompile
            obj.get_mex_status();
            if obj.bCompilable
                obj.compile();
            else
                PxUtil.warnSoft('Unable to compile base-tools: Some operations will be slower. Fix your C++ compiler for better performance.');
            end
        end
    end
    function get_mex_status(obj);
        %% TODO
        obj.bMexSetup=true; % XXX TOOD
        out=mex.getCompilerConfigurations('Cpp','Supported');
        evalc('mex -setup C++');
        copyfile(fullfile(matlabroot,'extern','examples','cpp_mex','arrayProduct.cpp'),'.','f');

        lastwarn('');
        try
            out=evalc('mex arrayProduct.cpp');
        catch ME
            if strcmp(computer,'GLNXA64') && contains(ME.message,'.mexa64'' is not a MEX file.')
                ;
            else

               obj.bCompilable=false;
               return
            end
            obj.bCompilable=true;

        end
        obj.warn=lastwarn;
        if ~isempty(obj.warn)
            PxUtil.warnSoft(['Matlab mex ' obj.warn]);
        end
    end
%%%
    function obj=get_install_status(obj);
        obj.mbDir=[obj.ve.libDir 'MatBaseTools' filesep];
        if ~exist(obj.ve.libDir,'dir')
            obj.bInstalled=false;
        elseif ~exist(obj.mbDir,'dir') && ~exist(obj.mbDir,'file')
            obj.bInstalled=false;
        elseif ~exist(obj.instFile,'file')
            obj.bInstalled=false;
        else
            obj.bInstalled=true;
        end
    end
    function obj=get_compiled_status(obj)
        if ~exist(obj.ve.binDir,'dir') || ~exist(obj.ve.intDir,'dir')
            obj.bCompiled=false;
        else
            obj.bCompiled=logical(exist(obj.cmpFile,'file'));
        end
    end
%%%
    function obj=download(obj)
        bHasGit=BaseInstaller.isInstalled('git');
        if bHasGit && ~exist(obj.dlFile,'file')
            obj.download_base_tools();
            PxUtil.touch(obj.dlFile);
        else
            error('Git not installed, but required');
        end
    end
    function obj=download_base_tools(obj)
        PxUtil.git_clone(obj.BASEURL,obj.ve.libDir(1:end-1));
        if ~strcmp(obj.BASEV,'master')
            PxUtil.git_checkout(obj.ve.libDir,obj.BASEV);
        end
    end
%%%
    function obj=compile(obj)
        % MB IS IN PATH AT THIS POINT
        if ~obj.bMexSetup
            Error.warnSoft('Mex comapilation is not setup');
            return
        end
        if exist(obj.cmpFile,'file') && ~exist(obj.cmpFile,'dir')
            delete(obj.cmpFile);
        end


        faillist={};
        bSucces=true;
        %%%% TODO use method in px
        if ispc
            str='win32';
            bWin=true;
        else
            str='unix';
            bWin=false;
        end
        list={'home_cpp','isinstalled_cpp',['hostname_' str '_cpp'],['ln_' str '_cpp'],['readlink_' str '_cpp'],['issymlink_' str '_cpp'],'which_cpp'};
        winBadList={'home','isinstalled','which','hostname_win32','ln_win32'};
        %winBadList={'readlink_win32','issymlink_win32','hostname_win32','ln_win32'};
        %winBadList={};
        bFirst=true;
        for i = 1:length(list)
            if ispc() && contains(list{i},winBadList)
                continue
            end
            bForce=obj.ve.opts.bMBTRecompile;

            fname=[obj.mbDir list{i} '.cpp'];

            [bSuccess,ME,cmd,bFirst]=PxCompiler.mex_compile(fname, obj.ve.binDir,bForce,bFirst);
            if ~bSuccess
                faillist{end+1,1}=fname;
                faillist{end  ,2}=ME;
                faillist{end  ,3}=cmd;
            end
        end
        if bSuccess
            Fil.touch(obj.cmpFile);
        else
            assignin('base','cmpfaillist',faillist);
        end
    end
%%%
    function add_path(obj)
        addpath(obj.mbDir);

        p=obj.ve.binDir;
        addpath(p);
    end
    function obj=get_optional_status(obj)
        % TODO
        Sys.isInstalled('find');
        Sys.isInstalled('git');
    end
end
methods(Static)
    function out=isInstalled(cmd)
        if isunix
            [~,out]=unix(['which ' cmd]);
        else
            [~,out]=system(['which ' cmd]);
        end
        out=strsplit(out,newline);
        out=out(~cellfun('isempty',out));

        if isempty(out)
            out=false;
        else
            out=true;
        end
    end


end
end
