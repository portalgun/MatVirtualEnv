classdef PxTbTb
methods
    function obj=read_tb(obj)
        % READ AND CONVERT
        %https://github.com/ToolboxHub/ToolboxToolbox/wiki/Toolbox-Records-and-Types
        fileread
        jsondecode

        name
        type % git svn web docker local installed
        url
        flavor % version/branch
        pathPlacement %append prepend appendrootonly prependrootonly

        update % never
           % point to commit or branch
        hook % thing to eval
        toolboxSubfolder % where to put project internally
        toolboxRoot % where to put project externally


        importance % optional
        extra % commentary
        printlocalhookoutput % 1 or 0
        subfolder % only include these
        localHookTemplate % place to templates
        requirementHook % function that check system requirements -> prehook
        java % add to java path


    end
end
