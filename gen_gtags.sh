#!/bin/bash
cd ../prj
root=$(pwd)
for i in */; do
    cd $i
    if [[ ! -f GTAGS ]]; then
        gtags
    fi
    #if [[ ! -d .git ]]; then
    #    git init
    #fi
    cd $root
done

#cd $root
#for i in */; do
#    cd $i
#    if [[ $(uname -o) == GNU/Linux ]]; then
#        emacsclient  --alternate-editor="" -e "(projectile-add-known-project \"$(pwd)\")" -s "MAIN" &
#    else
#        emacs  --alternate-editor="" -e "(projectile-add-known-project $(pwd))" &
#    fi
#    cd $root
#done
