classdef PxHistorian < Handle
methods
    function obj=make_history(obj)
        Mat.saveHistory();
        %/home/dambam/.matlab/java/jar/mlservices.jar
        %% MAKE history files
        destDir=obj.dirs.root.var;
        mdir=Dir.parse(prefdir);

        names={'history.m','History.xml','History.bak'};
        % History.xml = desktop command history

        for i = 1:length(names)
            history_fun(names{i},obj.prj,destDir,mdir,obj.sys.home);
        end

        Mat.historyReload();

        function history_fun(name,prj,destDir,mdir,home)
            mHist=[mdir name];
            if ~Fil.exist(mHist)
                error(['History file ' name ' does not exist']);
            end
            pHist=[destDir name '_' prj];
            if ~Fil.exist(pHist)
                Fil.touch(pHist);
            end

            bSym=FilDir.isLink(mHist);
            if bSym && strcmp(FilDir.readLink(mHist),pHist);
                return
            elseif bSym
                delete(mHist);
            else
                movefile(mHist,[mHist '_bak']);
            end

            FilDir.easyln(pHist,mHist,false,home); % XXX SLOW 4
            FilDir.easyln(mHist,obj.dirs.root.wrk,false,home);

        end
    end
    function out=restore_original_history(obj)
        out=false;
        dire=prefdir;
        if ~endsWith(dire,filesep)
            dire=[dire filesep];
        end
        mHistM=[dire 'history.m'];
        mHistX=[dire 'History.xml'];
        mHistB=[dire 'History.bak'];

        % DELETE SYMS
        if Dir.isLink(mHistM)
            delete(mHistM);
            movefile([mHistM '_bak'],mHistM);
            out=true;
        end
        if Dir.isLink(mHistX)
            delete(mHistX);
            movefile([mHistX '_bak'],mHistX);
            out=true;
        end
        if Dir.isLink(mHistB)
            delete(mHistB);
            movefile([mHistB '_bak'],mHistB);
            out=true;
        end
    end
end
end
