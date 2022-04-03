function VEInstaller(varargin)
% Valid argument keys
% 'installDir' - where you will install to
% 'prjDir'     - existing project directory to import
% 'libDir'     - existing libraries/dependency directory to import
% 'cfgDir'     - existing configuration directory to import

    args={'installDir', true;
         'libDir',     false;
         'prjDir',     false;
         'cfgDir',     false;
    };
    margs={'bReinstall',false;
           'bUninstall',false;
    };

    VE.warnOff();
    odire=cd('..');
    Oc=onCleanup(@() cd(odire));
    if ~ismember('installDir',varargin)
        if ~isempty(varargin) && ~ismember(varargin{1},args(2:end,1))
            if exist(varargin{1},'dir')
                out=yn(['Install to directory ''' varargin{1} '''']);
                if out
                    varargin=['installDir', varargin];
                else
                    disp('Exiting.')
                    return
                end
            end
        else
            out=yn(['Install to directory ''' pwd '''']);
            if out
                varargin=['installDir', pwd, varargin];
            else
                disp('Exiting.')
                return
            end
        end
    end
    delete(Oc);

    % ARGS
    inargs={};
    opts=struct();
    for i = 1:size(args,1)
        fld=args{i,1};
        ind=find(ismember(varargin,args{i,1}));
        if isempty(ind) && ~args{i,2};
            continue
        elseif isempty(ind) && args{i,2};
            disp(['Option ' args{i,1} ' is required'])
            disp('Exiting.');
        end
        dire=varargin{ind+1};
        if ismember(varargin{ind+2},{'0','1','2'})
            moveOpt=varargin{ind+2};
            f=fld(1:3);
            f(end)=upper(f(end));
            str=['moveOpt' f];
            opts.(str)=moveOpt;
        else
            moveOpt=[];
        end
        if ~isempty(varargin{ind+1})
            inargs{end+1}=fld;
            inargs{end+1}=varargin{ind+1};
        end
        varargin(ind:ind+1+~isempty(moveOpt))=[];

        if ~isempty(dire) && ~exist(dire,'dir')
            disp([args{1,1} ' directory ''' dire ''' does not exist']);
            disp('Exiting.');
        end
    end

    % MARGS
    for i = 1:size(margs,1)
        fld=margs{i,1};
        ind=find(ismember(varargin,fld));
        if isempty(ind)
            mopts.(fld)=margs{i,2};
        else
            mopts.(fld)=varargin{ind+1};
            varargin(ind:ind+1)=[];
        end
    end

    % MVE dire
    if endsWith(inargs{2},filesep)
        inargs{2}=inargs{2}(1:end-1);
    end
    if ~endsWith(inargs{2},'MVE')
        inargs{2}=[inargs{2} filesep 'MVE' filesep];
    else
        inargs{2}=[inargs{2} filesep];
    end

    if mopts.bReinstall
        VE.reInstallVE(inargs{:});
    elseif mopts.bUninstall
        VE.unInstallVE(inargs{:});
    else
        VE.installVE(inargs{:});
    end
    %VE.startup;
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
