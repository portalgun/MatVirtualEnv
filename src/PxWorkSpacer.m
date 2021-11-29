classdef PxWorkSpacer < handle
properties(Access=private)
    PX
end
methods
    function PxWorkSpacer(PX)
        obj.PX=px;
    end
    function prompt_load(obj,prj)
        file=obj.PX.ve.lastSavedWrk;
        if isempty(prj) || ~Fil.exist(file)
            return
        end

        out=Input.yn(['Restore saved workspace (' prj ')?']);
        rmLastHistory;
        if out
            evalin('base','clear');
            Px.loadLast();
        end
        delete(file);
    end
    function obj=prompt_save(obj,prj)
        if isempty(prj)
            return
        end
        bHist=obj.rootOpts.bHistory;

        vars=evalin('base','who');
        vars(ismember(vars,'ans'))=[];
        if isempty(vars)
            return
        end

        out=Input.yn(['Save workspace (' cur ')?']);
        Mat.rmLastHistory;

        if out
            fil=ve.lastSavedWrk;
            Fil.touch(fil);
            obj.save_workspace();
        end
        if bHist
            Mat.saveHistory();
        end

    end
    function []=save_workspace(obj)
        wsName='Wrk_' VE.getName() '_' Date.timeFilStr();
        fil=[getenv('PX_VAR')  ];
        evalin('base',['save(''' fil ''');']);
        if ~isempty(getenv('Px_BHIST'))
            Mat.saveHistory();
        end
    end
    function []=workspace_fun(mode,bLast,bAll)
        if ~exist('bLast','var') || isempty(bLast)
            bLast=false;
        end
        if ~exist('bAll','var') || isempty(bAll)
            bAll=false;
        end
        if bAll
            prj='';
        else
            prj=VE.getName();
        end
        dire=getenv('PX_VAR');
        fils=Fil.find(dire,['Wrk_' prj '.*']);
        nums=cell(length(fils),1);
        if isempty(fils)
            disp('No saved workspaces')
            return
        end
        if bLast
            ind=length(fils);
        else
            for i = 1:length(fils)
                spl=strsplit(fils{i},'_');
                spl=spl(2:end);
                if length(spl)> 2
                    name=['    ' spl{2}];
                else
                    name='';
                end
                % datetime
                [~,fname]=Fil.parts(spl{end});
                spl=strsplit(fname,'-');
                date=strjoin(spl(1:3),'-');
                time=strjoin(spl(4:end),':');

                nums{i}=[date '    ' time name];
            end
            [~,ind]=Input.select(nums);
            Mat.rmLastHistory();
        end
        fil=[dire fils{ind}];
        if strcmp(mode,'load')
            evalin('base',['load(''' fil ''');']);
        elseif strcmp(mode,'delete')
            delete(fil);
        end
    end
end
