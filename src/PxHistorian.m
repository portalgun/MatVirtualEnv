classdef PxHistorian < handle
properties
    bHistFile
    matDir
end
properties(Access=private)
    PX
end
properties(Constant)
    names={'history.m','History.xml','History.bak'};
end
methods
    function obj=PxHistorian(PX,bHistory)
        obj.PX=PX;
        obj.bHistFile=[obj.PX.ve.intDir 'hist_installed'];
        obj.matDir=Dir.parse(prefdir);
        if bHistory && ~Fil.exist(obj.bHistFile)
            obj.install();
        elseif ~bHistory && Fil.exist(obj.bHistFile)
            obj.uninstall();
        end
    end
    function clearVEHist()
        % TODO
    end
    function obj=install(obj)
        names=PxHistorian.names;
        for i = 1:length(names)
            matHist=[obj.matDir names{i}];
            pxHist=[obj.PX.dirs.root.var names{i}];

            bSym=FilDir.isLink(matHist);

            if ~Fil.exist(pxHist) && ~Fil.exist(matHist)
                Fil.touch(pxHist);
            elseif Fil.exist(pxHist) && ~Fil.exist(matHist)
               ;
            elseif bSym && strcmp(FilDir.readLink(matHist),pxHist);
                continue
            elseif bSym
                delete(matHist);
            else
                movefile(matHist,pxHist);
            end
            FilDir.easyln(pxHist,matHist,false,obj.PX.sys.home);
        end
        if ~Fil.exist(obj.bHistFile)
            Fil.touch(obj.bHistFile);
        end
    end
    function out=uninstall(obj);
        names=PxHistorian.names;
        for i = 1:length(names)
            matHist=[obj.matDir names{i}];
            pxHist=[obj.PX.dirs.root.var names{i}];

            bSym=FilDir.isLink(matHist);
            if ~bSym
                continue
            elseif bSym
                delete(matHist);
                movefile(pxHist,matHist);
            end
        end
        if ~Fil.exist(obj.bHistFile)
            delete(obj.bHistFile);
        end
    end
    function obj=prjLink(obj)
        %/home/dambam/.matlab/java/jar/mlservices.jar
        %% MAKE history files

        % History.xml = desktop command history

        names=PxHistorian.names;
        bSave=false;

        if exist([obj.matDir 'History.xml'])
            Mat.saveHistory();
        end

        for i = 1:length(names)
            realFile=[obj.PX.dirs.prj.var names{i}];
            lnFile=[obj.matDir names{i}];

            if ~Fil.exist(realFile)
                Fil.touch(realFile);
            end

            bSym=FilDir.isLink(lnFile);
            if isempty(bSym)
                ;
            elseif bSym && strcmp(FilDir.readLink(lnFile),realFile);
                continue
            elseif bSym
                delete(lnFile);
            end

            try
                FilDir.easyln(realFile,lnFile,false,obj.PX.sys.home); % XXX SLOW 4
            end



        end
        Mat.historyReload();
    end
end
end
