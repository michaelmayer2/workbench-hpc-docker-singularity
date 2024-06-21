ARG PWB_VERSION="2024.04.2"
ARG OS_VERSION="ubuntu2204"
FROM rstudio/r-session-complete:${OS_VERSION}-${PWB_VERSION}

ARG SLURM_VERSION="23.02.7" 
ARG SLURM_CONF_DIR="/opt/slurm/etc"
ARG PWB_SHARED_STORAGE="/opt/rstudio/pwb"

# Install and configure munge
RUN apt-get update && apt-get install -y munge libmunge-dev && rm -rf /var/cache/apt/*
COPY munge/munge.key /etc/munge

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

# Nice to have
RUN apt-get install vim -y 

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

