#!/bin/bash

templating () {
eval "cat <<EOF
$(<$1)
EOF
" 2> /dev/null > $2
}

target_folder=${PWB_SHARED_STORAGE}/etc/rstudio
mkdir -p $target_folder
cp conf/{database.conf,jupyter.conf,logging.conf,notifications.conf,r-versions,rserver.conf,rsession.conf,vscode*} $target_folder

templating conf/launcher-env $target_folder/launcher-env
templating conf/launcher.conf $target_folder/launcher.conf
templating conf/launcher.tmpl.conf $target_folder/launcher.${LAUNCHER_NAME}.conf
templating conf/launcher.tmpl.resources.conf $target_folder/launcher.${LAUNCHER_NAME}.resources.conf
templating conf/launcher.tmpl.profiles.conf $target_folder/launcher.${LAUNCHER_NAME}.profiles.conf