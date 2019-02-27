FROM nvidia/opengl:1.0-glvnd-runtime-ubuntu16.04

################################## JUPYTERLAB ##################################

ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt-get update && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
	locales python-pip cmake \
	python3-pip python3-setuptools git build-essential \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN pip3 install jupyterlab bash_kernel \
 && python3 -m bash_kernel.install

ENV SHELL=/bin/bash \
	NB_USER=jovyan \
	NB_UID=1000 \
	LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8

ENV HOME=/home/${NB_USER}

RUN adduser --disabled-password \
	--gecos "Default user" \
	--uid ${NB_UID} \
	${NB_USER}

EXPOSE 8888

CMD ["jupyter", "lab", "--no-browser", "--ip=0.0.0.0", "--NotebookApp.token=''"]

################################# CMAKE_UPDATE #################################

RUN apt remove -y --purge --auto-remove cmake

RUN apt-get update \
 && apt-get install -yq --no-install-recommends wget libcurl4-openssl-dev zlib1g-dev\
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir /temp_cmake && cd /temp_cmake \
 && wget https://cmake.org/files/v3.7/cmake-3.7.2.tar.gz \
 && tar -xzvf cmake-3.7.2.tar.gz \
 && cd cmake-3.7.2 \
 && ./bootstrap --system-curl && make -j4 && make install \
 && rm -fr /temp_cmake

##################################### APT ######################################

RUN apt-get -o Acquire::ForceIPv4=true update \
 && apt-get -o Acquire::ForceIPv4=true install -yq --no-install-recommends \
    python3-tk \
    python3-dev \
    python3-numpy \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

##################################### PIP3 #####################################

RUN pip3 install  \
    tensorflow==1.4 \
    pillow \
    matplotlib \
    Cython

################################### SOURCE #####################################

RUN apt-get -o Acquire::ForceIPv4=true update \
 && apt-get -o Acquire::ForceIPv4=true install -yq --no-install-recommends \
    freeglut3-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --branch v7.1.1 git://vtk.org/VTK.git /vtk \
 && cd /vtk \
 && mkdir build \
 && cd build \
 && cmake -DVTK_WRAP_PYTHON:BOOL=ON ../ \
 && make -j4 install \
 && rm -fr /vtk

##################################### COPY #####################################

RUN mkdir ${HOME}/demon

COPY . ${HOME}/demon

################################### CUSTOM #####################################

RUN rm /usr/bin/python \
 && ln -s /usr/bin/python3.5 /usr/bin/python \
 && mkdir $HOME/demon/lmbspecialops/build \
 && cd $HOME/demon/lmbspecialops/build \
 && cmake -DBUILD_WITH_CUDA=OFF .. \
 && make -j2

##################################### TAIL #####################################

RUN chown -R ${NB_UID} ${HOME}

USER ${NB_USER}

WORKDIR ${HOME}/demon
