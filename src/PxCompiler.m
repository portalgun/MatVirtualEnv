classdef PxCompiler < handle
properties
    prjs
    prjdirs
    errorFlag=false
    errors=cell(0,2)
    bForce
end
properties(Access=private)
    PX
    Opts
    re
    bFirst=true
end
methods
    function obj=PxCompiler(PX)
        obj.PX=PX;
        obj.Opts=PX.Opts;

        if ismac
            obj.re='.*\.c[p]*$';
        else
            obj.re='.*\.c[p]*$';
        end
        obj.bForce=obj.PX.rootOpts{'bForceCompile'};
    end
    function obj=compile_all(obj)

        osflds={'mac','linux','win'};
        errorFlag=false;

        old=pwd;
        cl=onCleanup(@() cd(old));
        for i = 1:length(obj.Opts.I)
            obj.compile_prj(obj.Opts.I(i));
        end
    end
    function obj=link_to_prj(obj)
        [dires,ind]=unique(obj.prjdirs);
        prjs=obj.prjs(ind);
        for i = 1:length(prjs)
            src=[obj.PX.dirs.root.bin prjs{i} filesep];
            if Dir.exist(src)
                FilDir.ln(src,[obj.PX.dirs.lnk.bin prjs{i}]);
            end
        end
    end
    function OPTS=parse_prj_Opts(obj,OPTS)
        Opts=copy(OPTS.mex);
        flds=fieldnames(Opts);


        if ismember('unix',flds)
            unixfld=copy(Opts{'unix'});
            Opts{'unix'}=[];
            if obj.PX.sys.isunix
                Opts=unixfld.mergePref(Opts,false,true);
            end
        end

        if ismember(obj.PX.sys.os,flds)
            osfld=copy(Opts{obj.PX.sys.os});
            Opts(obj.PX.sys.os)=[];
            Opts=osfld.mergePref(Opts,false,true);

            flds=fieldnames(Opts);
        end
        if ismember('win',flds)
            Opts('win')=[];
        end
        if ismember('mac',flds)
            Opts('mac')=[];
        end
        OPTS.mex=Opts;
    end
    function [fDires,fFnames]=find_prj_mex_files(obj,prjdire)
        [foundFnames]=Fil.find(prjdire,obj.re);
        if ~iscell(foundFnames)
            foundFnames={foundFnames};
        end
        n=length(foundFnames);
        fDires=cell(n,1);
        fFnames=cell(n,1);
        for j = 1:n
            [fDires{j},f,ext]=Fil.parts(foundFnames{j});
            fFnames{j}=[f ext];
        end
        fDires=strrep(fDires,prjdire,'');
    end
    function obj=compile_prj(obj,Opts)
        if isempty(Opts.mex) || ~Opts.bAdd
            return
        end
        name=Opts.name;
        prjdire=Opts.dire;
        Opts=obj.parse_prj_Opts(Opts);
        [fDires,fFnames]=obj.find_prj_mex_files(prjdire);

        optFiles=fieldnames(Opts.mex);
        ind=find(Str.RE.ismatch(optFiles,obj.re));
        bSuccess=false;
        for j = ind
            oFname=optFiles{j};
            fInd=ismember(fFnames,oFname);
            opts=Opts.mex{optFiles{j}};

            if ~isempty(opts) && ~isa(opts,'dict') && isnumeric(opts) && opts==0
                continue
            elseif sum(fInd) == 0
                error(['File not found:' oFname]);
            elseif sum(fInd) > 1
                error(['Too many matches for file ''' oFname '''']);
            end

            fname=fFnames{fInd};
            dire=[prjdire fDires{fInd}];
            if ~bSuccess
                bSuccess=true;
                obj.prjs{end+1}=name;
                obj.prjdirs{end+1}=prjdire;
            end

            cd(dire);
            [bRan,ME,cmd,obj.bFirst]=PxCompiler.mex_compile(fname, obj.PX.dirs.prj.bin,obj.bForce,obj.bFirst);
            if ~bRan
                obj.errorFlag=true;
                obj.errors{end+1,1}=ME;
                obj.errors{end  ,2}=cmd;
                Error.warnSoft('Compilation errors:',ME);
            end
        end
    end
    function obj=compile_files(obj,Opts)
        files=obj.args.compileFiles;
        [fDires,fFnames]=obj.find_prj_mex_files(prjdire);
        for i = 1:length(files)
            ind=find(Str.RE.ismatch(optFiles,obj.re));
        end
    end
end
methods(Static)
    function [bSuccess,ME,cmd,bFirst]=mex_compile(fname,outdir,bForce,bFirst)
        bSuccess=false;
        ME=[];
        cmd=[];
        cmd=[];
        %TODO run mex outside of matlab? can output logs
        if ~exist('bForce','var') || isempty(bForce)
            bForce=0;
        end

        %[dire,file,ext]=Fil.parts(fname);
        if ismac()
            han='.mexmaci64';
        elseif ispc()
            han='.mexw64';
        else
            han='.mexa64';
        end
        [~,name]=fileparts(fname);

        outfile=[outdir name han];
        if exist(outfile,'file') && ~bForce
            %ME=MException('MATLAB:open:fileNotFound',outfile);
            return
        end
        flags='';
        if strcmp(name,'hostname_cpp') && ispc()
            flags=' -lws2_32';
        end

        if bFirst;
            bFirst=false;
            disp('Compiling...')
        end
        %cmd=['mex -outdir ' outdir ' ' fname flags];
        cmd=['mex -silent -outdir ' outdir ' ' fname flags];
        try
            eval(cmd);
            bSuccess=true;
        catch ME
            cmd
            ME.message
            if contains(ME.message,'mexa64'' is not a MEX file. ')
                bSuccess=true;
            end
        end
    end
end
end
