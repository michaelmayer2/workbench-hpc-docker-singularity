ARG PWB_VERSION="2024.04.2"
ARG OS_VERSION="ubuntu2204"
FROM rstudio/rstudio-workbench:${OS_VERSION}-${PWB_VERSION}

ARG SLURM_VERSION="23.02.7" 
ARG SLURM_CONF_DIR="/opt/slurm/etc"
ARG PWB_SHARED_STORAGE="/opt/rstudio/pwb"

# Install and configure munge
RUN apt-get update && apt-get install -y munge libmunge-dev && rm -rf /var/cache/apt/*
COPY munge/munge.key /etc/munge

# Removing empty sssd conf as this seems to crash docker-compose
RUN rm -f /startup/user-provisioning/sssd.conf 

# Install SLURM
RUN groupadd -g 401 slurm && \
       useradd -u 401 -g 401 slurm

RUN tmpdir=`mktemp -d` && \
        cd $tmpdir && \
        # Note that the git branches on github do have a slightly different
        # naming scheme - firstly the dots are replaced by dashes and
        # secondly each SLURM version can have more than one release tag
        # Here, we simply append "-1" to use the first git tag of a given
        # SLURM version
        git clone --depth 1 -b slurm-${SLURM_VERSION//./-}-1 https://github.com/SchedMD/slurm.git && \
        cd slurm && \
        echo "SLURM: Configure step" && \
        ./configure --prefix /usr/local >& /var/log/slurm-configure.log && \
	echo "SLURM: Compile" && \
        make -j 4 >& /var/log/slurm-build.log && \
	echo "SLURM: Install" && \
	make install >& /var/log/slurm-install.log && \
        cd / && \
        rm -rf $tmpdir

RUN echo "export SLURM_CONF=$SLURM_CONF_DIR/slurm.conf" > /etc/profile.d/slurm-env.sh

# Upgrade Launcher to 2.17.0 to take benefit of SLURM_CONF environment variable passthrough
RUN curl -LO https://cdn.rstudio.com/launcher/releases/jammy/launcher-jammy-amd64-2.17.0-216.tar.gz && tar xvfz launcher-jammy-amd64-2.17.0-216.tar.gz -C /usr/lib/rstudio-server/bin/ --strip-components=1 && rm -f launcher-jammy-amd64-2.17.0-216.tar.gz 

# Integrate the start of sssd and munge into supervisord 
RUN echo -e '#!/bin/bash -l\nsssd -D -c /etc/sssd/sssd.conf\nmkdir /run/munge\nchown -R root:root /var/lib/munge/ /var/log/munge/ /etc/munge/\nmunged\nsleep 2\n/usr/lib/rstudio-server/bin/rstudio-launcher' > /startup/launcher/launcher.sh && chmod +x /startup/launcher/launcher.sh 
RUN sed -i 's#^command.*#command=/startup/launcher/launcher.sh#' /startup/launcher/rstudio-launcher.conf 

# prevent workbench from failing to start is human readable user name has a space in their name
RUN sed -i "s#.*getent passwd.*#if [ \"\$(getent passwd \$RSW_TESTUSER_UID)\" ] ; then#" /usr/local/bin/startup.sh

# Configure Workbench to use a different folder for Workbench metadata. 
RUN sed -i '1a export RSTUDIO_DATA_HOME=\\\$HOME/.local/share/rstudio-\${LAUNCHER_NAME}' /usr/local/bin/startup.sh 
RUN sed -i '1a export RSTUDIO_DATA_HOME=\\\$HOME/.local/share/rstudio-\${LAUNCHER_NAME}' /startup/launcher/launcher.sh

# # Configure Workbench to use a different folder for the configs
# RUN sed -i "1a export RSTUDIO_CONFIG_DIR=${PWB_SHARED_STORAGE}" /usr/local/bin/startup.sh 
# RUN sed -i "1a export RSTUDIO_CONFIG_DIR=${PWB_SHARED_STORAGE}" /startup/launcher/launcher.sh

# Make sure that session-callback address is set appropriately
RUN x="sed -i 's#^launcher-sessions-callback-address.*#launcher-sessions-callback-address=http://\`curl ifconfig.me\`:8788#' /etc/rstudio/rserver.conf" ; sed -i "1a $x" /usr/local/bin/startup.sh 

# Nice to have for debugging 
RUN apt-get install vim strace curl wget -y 

# Configure R versions with Java, setup appropriate repos and preinstall any R package needed for the RStudio integration 
COPY scripts/run.R /
COPY conf/bioc.txt /
RUN for R_VERSION in `ls /opt/R | grep -v default | cut -d "/" -f 3`; \
    do \
        # Reconfigure R for Java (optional) 
        export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 && \
        /opt/R/${R_VERSION}/bin/R CMD javareconf && \
            echo $JAVA_HOME/lib/server > /etc/ld.so.conf.d/java.conf && \
        # Need to make sure R is in PATH so that pak can run R as a subprocess
        PATH=/opt/R/${R_VERSION}/bin:$PATH /opt/R/${R_VERSION}/bin/Rscript /run.R ${PWB_SHARED_STORAGE}; \
    done && \
    rm -f /run.R /bioc.txt 

