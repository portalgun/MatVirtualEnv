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
        if exist(fname,'file') && ~exist(fname,'dir')
            fclose(fopen(fname,'a'));
        else
            fclose(fopen(fname,'w'));
        end
    end
    function status=git_clone(site,direName)
        out=PxUtil.git_local_state(direName);
        if out==3
            error('.git directory exists')
            % TODO
        elseif out==2
            error(['Warning: Cannot find repo at ' site])
            % TODO
        elseif out==1
            oDir=cd(direName);
            oC=onCleanup(@() cd(oDir));
            cmd=['git clone -q ' site ];
        elseif out==0
            cmd=['git clone -q ' site ' ' direName ];
        end

        % TODO
        %origin=Px.git_get_origin(direName);
        %if ~strcmp(origin,site)
        %   % TODO
        %   error('origin does not match site')
        %end

        if isunix
            [status,msg]=unix(cmd);
            if status==1
                error(msg);
            end
        else
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
    function [out]=git_local_state(dirName)
        % 0 dire doesn't exist
        % 1 empty
        % 2 not empty with files, no .git
        % 3 has git
        if ~exist(dirName,'dir')
            out=0;
        elseif ~exist([dirName '.git'],'dir') && length(dir(dirName)) == 2
            out=1;
        elseif ~exist([dirName '.git'],'dir') && length(dir(dirName)) > 2
            out=2;
        else
            out=3;
        end
    end
    function warnSoft(varargin)
        bME=false;
        bID=false;
        bMsg=false;
        % ARG 1
        if isa(varargin{1},'MException')
            bME=true;
            ME=varargin{1};
        elseif nargin == 1 && ischar(varargin{1})
            bMsg=true;
            msg=varargin{1};
        end
        % ARG 2
        if nargin > 1
            if isa(varargin{2},'MException')
                bME=true;
                ME=varargin{2};
            elseif bME && ischar(varargin{2})
                bMsg=true;
                msg=varargn{2};
            elseif bMsg && ischar(varargin{2})
                bID=true;
                warID=varargin{2};
            end
            if nargin > 2
                if isa(varargin{3},'MException')
                    bME=true;
                    ME=varargin{3};
                else
                    bID=true;
                    warID=varargin{3};
                end
            end
        end

        out=warning('query');
        if strcmp(out(1).state,'off');
            return
        end
        out=warning('query','verbose');
        vState=out.state;
        out=warning('query','backtrace');
        bState=out.state;

        cl=onCleanup(@() PxUtil.cleanup_fun(vState,bState));
        warning('off','verbose');
        warning('off','backtrace');

        if bME && bID && bMsg
            msg=[msg newline '    ' ME.message];
            warning(warnID,msg);
        elseif bME && bMsg
            msg=[msg newline '    ' ME.message];
            warning(ME.identifier,ME.message);
        elseif bME
            warning(ME.identifier,ME.message);
        elseif bID && bMsg
            warning(warnID,msg);
        elseif bMsg
            warning(msg);
        end
    end

    function cleanup_fun(vState,bState)
        warning(vState,'verbose');
        warning(bState,'backtrace');
    end

    function out=yn(in)
        ostr=[in ' (y/n)?: '];
        str=ostr;
        n=length(ostr);
        fprintf([str]);
        r=input('','s');
        while true
            switch r
                case {'0','n','N','no','No','NO'}
                    out=false;
                    return
                case {'1','y','Y','yes','Yes','YES'}
                    out=true;
                    return
                otherwise
                    fprintf(repmat(char(8),1,n+length(r)+1));
                    str=['Invalid responds ''' r '''.' newline ostr ];
                    n=length(str);
                    fprintf(str);
                    r=input('','s');
            end
        end
    end



end
end
