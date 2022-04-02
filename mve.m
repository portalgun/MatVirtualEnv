function mve(cmd,varargin)
%
% mve
%   MatVirtualEnv command prompt interface
%   (See VE for developer integragtion [>> help VE])
%
% Usage:
%   mve [command] [arguments]
%
% Main commands:
%   mve help           - see full list of commands
%   mve help [cmd]     - get help for a command
%   mve cd             - change to a project via prompt
%   mve cd [prj]       - change project to project given name
%   mve ls [arg]       - list details about a project, depndencies, env. variables, or MVE
%   mve pwd            - list current project
%   mve reload         - reload current project
%   mve config [type]  - configure projects and MVE
%   mve new [prj]      - create and switch to new project
%
    if nargin < 1
        cmd='help';
        out=help('mve');
        hlp=VE.(cmd)(varargin);
        disp(out(1:end-1));
        return
    elseif ~ismethod('VE',cmd)
        VE.help(cmd);
    else
        VE.(cmd)(varargin{:});
    end

end
