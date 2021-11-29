classdef PxUtil < handle
methods(Static)
    function out=parent(dire)
        if iscell(dire)
            out=cellfun(@PxUtil.parent,dire,'UniformOutput',false);
            return
        end
        dire=PxUtil.dirParse(dire);
        if strcmp(dire,filesep)
            out='';
            return
        elseif endsWith(dire,filesep)
            dire=dire(1:end-1);
        end
        if ~ismember(dire,filesep)
            out='./';
            return
        end
        spl=strsplit(dire,filesep);
        out=strjoin(spl(1:end-1),filesep);
        if ~endsWith(out,filesep)
            out=[out filesep];
        end
    end
    function out=dirParse(dire)
        out=dire;
        if isempty(dire)
            return
        end
        if ispc
            out=strrep(out,'/',filesep);
            sep=[filesep filesep];
        else
            out=strrep(out,'\',filesep);
            out=regexprep(out,'^[a-zA-Z]{1}:','');
            sep=filesep;
        end
        out=regexprep(out,[sep '{2,}'],filesep);
        if out(end) ~= filesep
            out=[out filesep];
        end
    end
    function obj=touch(fname)
        if Fil.is(fname)
            fclose(fopen(fname,'a'));
        else
            fclose(fopen(fname,'w'));
        end
    end
    function status=git_clone(site,direName)
        out=BaseInstaller.git_local_state(direName);
        if out==1
            'out equals 1'
            % TODO
        elseif out==2
            disp(['Warning: Cannot find repo at ' site])
            % TODO
        elseif out==3
            origin=Px.git_get_origin(direName);
            if ~strcmp(origin,site)
               % TODO
               'origin does not match site'
            end
        end

        if out==0 && isunix
            cmd=['git clone -q ' site ' ' direName ];
            [status,msg]=unix(cmd);
        elseif out==0
            cmd=['git clone ' site ' ' direName ];
            [status,msg]=system(cmd);
        end
    end

    function status=git_checkout(dire,version)
        %checkout -> into lib
        %dire stable -> lib
        oldDir=cd(dire);
        if isunix
            [~,msg]=unix(['git checkout ' version ' --quiet']);
        else
            [~,msg]=system(['git checkout ' version ' --quiet']);
        end
        cd(oldDir);
    end
    function [out]=git_local_state(direName)
        % 0 dire doesn't exist
        % 1 empty
        % 2 not empty with files, no .git
        % 3 has git
        if ~exist(direName,'dir')
            out=0;
        elseif ~exist([direName '.git'],'dir') && length(dir(dirName)) == 2
            out=1;
        elseif ~exist([direName '.git'],'dir') && length(dir(dirName)) > 2
            out=2;
        else
            out=3;
        end
    end

end
end
