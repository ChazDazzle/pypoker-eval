FROM --platform=linux/arm64 ubuntu:20.04


ENV DEBIAN_FRONTEND=noninteractive
RUN ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    echo "Etc/UTC" > /etc/timezone


RUN apt-get update && apt-get install -y software-properties-common wget
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update && apt-get install -y \
    build-essential \
    python3.11 \
    python3.11-dev \
    python3-pip


RUN wget https://github.com/Kitware/CMake/releases/download/v3.22.3/cmake-3.22.3-linux-aarch64.sh
RUN chmod +x cmake-3.22.3-linux-aarch64.sh
RUN ./cmake-3.22.3-linux-aarch64.sh --skip-license --prefix=/usr/local


ENV Python3_ROOT_DIR=/usr/bin/python3.11
ENV Python3_INCLUDE_DIR=/usr/include/python3.11
ENV Python3_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.11.so


COPY . /workspace
WORKDIR /workspace


RUN mkdir build && cd build && cmake -DPython3_ROOT_DIR=$Python3_ROOT_DIR -DPython3_INCLUDE_DIR=$Python3_INCLUDE_DIR -DPython3_LIBRARY=$Python3_LIBRARY .. && cmake --build .


CMD ["/bin/bash"]
