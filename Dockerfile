# 容器镜像构建主机需要连通公网
FROM arm64v8/ubuntu:18.04 AS builder

# 基础容器镜像的默认用户已经是 root
# USER root

# 安装 OS 依赖（使用华为开源镜像站）
# COPY Ubuntu-Ports-bionic.list /tmp
RUN wget -O /tmp/sources.list https://repo.huaweicloud.com/repository/conf/Ubuntu-Ports-bionic.list && \
    cp -a /etc/apt/sources.list /etc/apt/sources.list.bak && \
    mv /tmp/Ubuntu-Ports-bionic.list /etc/apt/sources.list && \
    echo > /etc/apt/apt.conf.d/00skip-verify-peer.conf "Acquire { https::Verify-Peer false }" && \
    apt-get update && \
    apt-get install -y \
    # utils
    ca-certificates vim curl wget\
    # CANN 6.3.RC2
    gcc-7 g++ make cmake zlib1g zlib1g-dev openssl libsqlite3-dev libssl-dev libffi-dev unzip pciutils net-tools libblas-dev gfortran libblas3 && \
    apt-get clean && \
    mv /etc/apt/sources.list.bak /etc/apt/sources.list && \
    # 修改 CANN 6.3.RC2 安装目录的父目录权限，使得 ma-user 可以写入
    chmod o+w /usr/local

RUN useradd -m -d /home/ma-user -s /bin/bash -g 100 -u 1000 ma-user

# 设置容器镜像默认用户与工作目录
USER ma-user
WORKDIR /home/ma-user

# 使用华为开源镜像站提供的 pypi 配置
RUN mkdir -p /home/ma-user/.pip/
COPY --chown=ma-user:100 pip.conf /home/ma-user/.pip/pip.conf

# 拷贝待安装文件到基础容器镜像中的 /tmp 目录
# COPY --chown=ma-user:100 Miniconda3-py37_4.10.3-Linux-aarch64.sh /tmp
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py39_23.5.2-0-Linux-aarch64.sh -O /tmp/Miniconda3-py39_23.5.2-0-Linux-aarch64.sh && \
chown ma-user:100 /tmp/Miniconda3-py39_23.5.2-0-Linux-aarch64.sh


# https://conda.io/projects/conda/en/latest/user-guide/install/linux.html#installing-on-linux
# 安装 Miniconda3 到基础容器镜像的 /home/ma-user/miniconda3 目录中
RUN bash /tmp/Miniconda3-py39_23.5.2-0-Linux-aarch64.sh -b -p /home/ma-user/miniconda3

ENV PATH=$PATH:/home/ma-user/miniconda3/bin

# 安装 CANN 6.3.RC2 Python Package 依赖
RUN pip install numpy~=1.14.3 decorator~=4.4.0 sympy~=1.4 cffi~=1.12.3 protobuf~=3.11.3 \
    attrs pyyaml pathlib2 scipy requests psutil absl-py

# 安装 CANN 6.3.RC2 至 /usr/local/Ascend 目录
# COPY --chown=ma-user:100 Ascend-cann-nnae_6.3.RC2_linux-aarch64.run /tmp
# RUN chmod +x /tmp/Ascend-cann-nnae_6.3.RC2_linux-aarch64.run && \
#     /tmp/Ascend-cann-nnae_6.3.RC2_linux-aarch64.run --install --install-path=/usr/local/Ascend

# 安装 MindSpore 2.1.1
# COPY --chown=ma-user:100 mindspore-2.1.1-cp37-cp37m-linux_aarch64.whl /tmp
# RUN chmod +x /tmp/mindspore-2.1.1-cp37-cp37m-linux_aarch64.whl && \
#     pip install /tmp/mindspore-2.1.1-cp37-cp37m-linux_aarch64.whl

# 安装pytorch
RUN wget https://gitee.com/ascend/pytorch/releases/download/v5.0.rc2.2-pytorch1.11.0/torch_npu-1.11.0.post3-cp39-cp39-linux_aarch64.whl -O /tmp/torch_npu-1.11.0.post3-cp39-cp39-linux_aarch64.whl && \
    chown ma-user:100 /tmp/torch_npu-1.11.0.post3-cp39-cp39-linux_aarch64.whl && \
    pip install torch==1.11.0 && \
    pip install /tmp/torch_npu-1.11.0.post3-cp39-cp39-linux_aarch64.whl 
# 构建最终容器镜像
FROM arm64v8/ubuntu:18.04

# 安装 OS 依赖（使用华为开源镜像站）
COPY Ubuntu-Ports-bionic.list /tmp
RUN cp -a /etc/apt/sources.list /etc/apt/sources.list.bak && \
    mv /tmp/Ubuntu-Ports-bionic.list /etc/apt/sources.list && \
    echo > /etc/apt/apt.conf.d/00skip-verify-peer.conf "Acquire { https::Verify-Peer false }" && \
    apt-get update && \
    apt-get install -y \
    # utils
    ca-certificates vim curl \
    # CANN 6.3.RC2
    gcc-7 g++ make cmake zlib1g zlib1g-dev openssl libsqlite3-dev libssl-dev libffi-dev unzip pciutils net-tools libblas-dev gfortran libblas3 && \
    apt-get clean && \
    mv /etc/apt/sources.list.bak /etc/apt/sources.list

RUN useradd -m -d /home/ma-user -s /bin/bash -g 100 -u 1000 ma-user

# 从上述 builder stage 中拷贝目录到当前容器镜像的同名目录
COPY --chown=ma-user:100 --from=builder /home/ma-user/miniconda3 /home/ma-user/miniconda3
COPY --chown=ma-user:100 --from=builder /home/ma-user/Ascend /home/ma-user/Ascend
COPY --chown=ma-user:100 --from=builder /home/ma-user/var /home/ma-user/var
COPY --chown=ma-user:100 --from=builder /usr/local/Ascend /usr/local/Ascend

# 设置容器镜像预置环境变量
# 请务必设置 CANN 相关环境变量
# 请务必设置 Ascend Driver 相关环境变量
# 请务必设置 PYTHONUNBUFFERED=1, 以免日志丢失
ENV PATH=$PATH:/usr/local/Ascend/nnae/latest/bin:/usr/local/Ascend/nnae/latest/compiler/ccec_compiler/bin:/home/ma-user/miniconda3/bin \
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/Ascend/driver/lib64:/usr/local/Ascend/driver/lib64/common:/usr/local/Ascend/driver/lib64/driver:/usr/local/Ascend/nnae/latest/lib64:/usr/local/Ascend/nnae/latest/lib64/plugin/opskernel:/usr/local/Ascend/nnae/latest/lib64/plugin/nnengine \
    PYTHONPATH=$PYTHONPATH:/usr/local/Ascend/nnae/latest/python/site-packages:/usr/local/Ascend/nnae/latest/opp/built-in/op_impl/ai_core/tbe \
    ASCEND_AICPU_PATH=/usr/local/Ascend/nnae/latest \
    ASCEND_OPP_PATH=/usr/local/Ascend/nnae/latest/opp \
    ASCEND_HOME_PATH=/usr/local/Ascend/nnae/latest \
    PYTHONUNBUFFERED=1

# 设置容器镜像默认用户与工作目录
USER ma-user
WORKDIR /home/ma-user
