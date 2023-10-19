FROM swr.cn-central-221.ovaijisuan.com/wuh-aicc_dxy/mindspore_2_0_0:mindspore2.0.0-cann6.3rc1-py_3.9-euler_2.8
RUN git clone -b dev https://gitee.com/mindspore/mindformers.git && \
    cd mindformers && \
    bash build.sh 

COPY entrypoint.sh .
