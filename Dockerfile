FROM rockylinux:9.2

# Install prerequistics
RUN yum groupinstall -y "Base" "Development Tools"
RUN yum install -y sudo git python3 openssl openssl-devel pam-devel numactl numactl-devel hwloc hwloc-devel lua lua-libs readline-devel rrdtool ncurses-devel libibmad libibumad perl-ExtUtils-MakeMaker mariadb mariadb-server libev libevent libevent-devel ucx ucx-devel
RUN dnf config-manager --enable crb
RUN dnf install -y munge munge-devel

# Install OpenPMIX
WORKDIR /tmp
RUN wget "https://github.com/openpmix/openpmix/releases/download/v4.2.6/pmix-4.2.6.tar.gz"
RUN tar xzvf pmix-4.2.6.tar.gz
WORKDIR /tmp/pmix-4.2.6
RUN ./configure --prefix=/usr/local/pmix --with-munge
RUN make -j`nproc`
RUN make install
ENV PATH="/usr/local/pmix/bin:${PATH}"

# Install SLURM
RUN useradd -m slurm
RUN usermod -aG wheel slurm
RUN sed -i 's/^%wheel.*$/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
USER slurm
WORKDIR /home/slurm
RUN git clone https://github.com/SchedMD/slurm.git
WORKDIR /home/slurm/slurm
RUN git checkout slurm-23.02
RUN ./configure --with-pmix=/usr/local/pmix --prefix=/usr/local --with-munge
RUN make -j`nproc`
USER root
RUN make install
RUN mkdir -p /usr/local/etc
COPY cgroup.conf /usr/local/etc/cgroup.conf
RUN mkdir -p /var/log/slurm /var/lib/slurm
RUN chown slurm:slurm /var/log/slurm /var/lib/slurm
ENV PATH="/usr/local/bin:${PATH}"

# Install OpenMPI
WORKDIR /tmp
RUN wget "https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.5.tar.gz"
RUN tar xzvf openmpi-4.1.5.tar.gz
WORKDIR /tmp/openmpi-4.1.5
RUN ./configure --prefix=/usr/local/ompi --with-slurm --with-pmix=/usr/local/pmix --with-libevent=/usr --enable-openib-rdmacm --with-verbs --disable-dependency-tracking --localstatedir=/var --sharedstatedir=/var/lib
RUN make -j`nproc`
RUN make install
ENV PATH="/usr/local/ompi/bin:${PATH}"

COPY entrypoint.sh /entrypoint.sh
USER slurm
WORKDIR /home/slurm
CMD [ "/entrypoint.sh" ]
