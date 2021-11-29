classdef PxUnInstaller < handle
properties(Constant)
    MODES={'uninstallPx','reinstallPx'}
end
methods
    function out=PxUnInstaller(obj,ve)
        obj.ve=ve;
    end
    function out=uninstall_base(obj);
        out=false;
        dire=[obj.selfPath 'MatBaseTools'];
        if exist(dire,'dir')

            dirs=dir(dire);
            ind=~vertcat(dirs.isdir);
            names=transpose({dirs(ind).name});
            ind=cellfun(@(x) endsWith(x,'.mexmaci64') | endsWith(x,'.mexw64') | endsWith(x,'.mexa64'),names);
            names=names(ind);
            for i = 1:length(names)
                fname=[dire filesep names{i}];
                delete(fname);
            end

            out=true;
            Px.rm_rf(dire);
        end
    end
    function uninstall(obj,varargin)
        warning('on');
        warning('off','backtrace');

        obj.get_self_path();
        cd(obj.selfPath);
        bInstalled=logical(exist([obj.selfPath '.installed']));
        if ~bInstalled
            warning('Px does not appear to be installed.');
        else
            warning('uninstalling');
        end

        %obj.setup_base_tools();
        out=Px.yn('Continue?');
        if ~out
            return
        end
        clc
        bSuccess=true;

        % GET IMPORTANT DIRS
        rootDir=getenv('PX_ROOT');
        bootDir=obj.selfPath;
        if isempty(rootDir)
            rootDir=Px.parent(obj.selfPath);
        end
        if ~endsWith(rootDir,filesep)
            rootDir=[rootDir filesep];
        end
        arDir=[rootDir 'PxFiles' filesep];

        % STARTUP
        out=obj.rm_startup_line();
        w = warning('query','last');
        if length(w) > 0;
            bSucces=false;
            warning('');
        elseif out
            display('Px removed from startup.');
        end

        % USER DIRS
        out=obj.restore_dirs();
        w = warning('query','last');
        if length(w) > 0;
            bSucces=false;
            warning('');
        elseif out
            display('Prj and/or Lib directories restored to original name and location.');
        end

        % PATH
        out=obj.restore_path(true);
        w = warning('query','last');
        if length(w) > 0;
            bSucces=false;
            warning('');
        elseif out
            display('Original path restored');
        end

        % PX DIRECTORIES
        out=obj.clean_dirs(arDir);
        w = warning('query','last');
        if length(w) > 0;
            bSucces=false;
            warning('');
        elseif out
            display('Px generated files moved into ''PxFiles''.');
        end


        % MATBASETOOLS
        out=obj.uninstall_base();
        w = warning('query','last');
        if length(w) > 0;
            bSucces=false;
            warning('');
        elseif out
            display('Px BaseTools removed');
        end


        % HISTORY
        out=obj.restore_original_history();
        w = warning('query','last');
        if length(w) > 0;
            bSucces=false;
            warning('');
        elseif out
            display('Original history files restored');
        end

        % MARK UNINSTALL
        if bSuccess
            instFile=[obj.selfPath '.installed'];
            if exist(instFile,'file')
                delete(instFile);
                w = warning('query','last');
                if length(w) > 0;
                    error('Something impossible happened. Try rerunning uninstall.');
                else
                    display('Px marked as ''not-installed''')
                end
            end
        else
            display('Issues encountered. Px not completely uninstalled. try rerunning uninstall.')
            return
        end

        % CLEAR ENV
        out=obj.clear_env_uninstall(arDir);
        w = warning('query','last');
        if length(w) > 0
            bSuccess=false;
            error('Problem encountered clearing env variables. This should not happen!');
        elseif out
            display('Px set environmental variables cleared');
        end

        cd ..;
        out=obj.mv_self(bootDir,arDir);
        w = warning('query','last');
        if length(w) > 0
            bSucces=false;
            display('Px not moved. You may have to do this manually');
            warning('');
        elseif out
            display('Px moved into PxFiles/boot');
        end

        if bSuccess
            display('Done.');
        end
    end
    function out=mv_self(obj,bootDir,arDir)
        if ~contains(bootDir,arDir)
            movefile(bootDir,arDir);
            out=true;
        else
            out=false;
        end
    end
    function out=clean_dirs(obj,arDir)
        out=false;

        etcDir=getenv('PX_ETC');
        libDir=getenv('PX_LIB');
        varDir=getenv('PX_VAR');
        binDir=getenv('PX_BIN');
        tmpDir=getenv('PX_TMP');
        wrkDir=getenv('PX_WRK');

        if ~exist(arDir,'dir')
            mkdir(arDir);
        end
        if exist(etcDir,'dir')
            movefile(etcDir,arDir);
            out=true;
        end
        if exist(libDir,'dir')
            movefile(libDir,arDir);
            out=true;
        end
        if exist(varDir,'dir')
            movefile(varDir,arDir);
            out=true;
        end
        if exist(binDir,'dir')
            movefile(binDir,arDir);
            out=true;
        end
        if exist(tmpDir,'dir')
            movefile(tmpDir,arDir);
            out=true;
        end
        if exist(wrkDir,'dir')
            Px.rm_rf(wrkDir);
            out=true;
        end
    end
    function out=clear_env_uninstall(obj,arDir)
        out=false;
        vars=obj.ls_env(arDir);
        if isempty(vars)
            return
        end
        for i = 1:length(vars)
            setenv(vars,'');
            out=true;
        end
    end
    function out=restore_dirs(obj)
        out=false;
        restoreDir=[obj.selfPath '.restore' filesep];
        names={'lib','prj'};
        evars={'PX_LIB','PX_PRJ'};

        for i = 1:length(names)
            name=names{i};

            fil=[restoreDir name 'Loc'];
            if ~exist(fil,'file')
                continue
            end
            loc=Px.cell(fil);
            if iscell(loc)
                loc=loc{1};
            end

            dire=getenv(evars{i});
            if isempty(dire)
                continue
            end
            if ~exist(dire,'dir') && exist(loc,'dir')
                continue
            end
            if ~endsWith(dire,filesep)
                dire=[dire filesep];
            end
            movefile(dire,loc);
            out=true;
        end

    end
    function out=rm_startup_line(obj)
        fname=which('startup');
        [out,ind,lines]=Px.file_contains(fname,'%PXSTARTUP');
        if ~out
            return
        end
        lines(ind)=[];
        Px.rewrite(fname,lines);
    end
    function out=restore_path(obj,bRemove)
        if ~exist('bRemove','var') || isempty(bRemove)
            bRemove=false;
        end
        out=true;
        fname=[obj.selfPath '.restore' filesep 'oldPath'];
        if ~exist(fname,'file')
            out=false;
            return
        end
        p=Px.cell(fname);
        restoredefaultpath;
        if ~isempty(p)
            path(p{1});
        end
        if bRemove
            delete(fname);
        end
    end
end
end
