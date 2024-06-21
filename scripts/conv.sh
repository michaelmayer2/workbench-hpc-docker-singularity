#!/bin/bash

templating () {
eval "cat <<EOF
$(<$1)
EOF
" 2> /dev/null > $2
}

mkdir -p ${PWB_SHARED_STORAGE}/${LAUNCHER_NAME}/{etc/rstudio,shared-data,containers}

target_folder=${PWB_SHARED_STORAGE}/${LAUNCHER_NAME}/etc/rstudio

cp conf/{database.conf,jupyter.conf,logging.conf,notifications.conf,r-versions,rserver.conf,rsession.conf,vscode*} $target_folder

templating conf/launcher-env $target_folder/launcher-env
templating conf/launcher.conf $target_folder/launcher.conf
templating conf/launcher.tmpl.conf $target_folder/launcher.${LAUNCHER_NAME}.conf
templating conf/launcher.tmpl.resources.conf $target_folder/launcher.${LAUNCHER_NAME}.resources.conf
templating conf/launcher.tmpl.profiles.conf $target_folder/launcher.${LAUNCHER_NAME}.profiles.conf