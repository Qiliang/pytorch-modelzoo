FROM swr.cn-central-221.ovaijisuan.com/mindformers/mindformers_dev_mindspore_2_0
RUN git clone -b dev https://gitee.com/mindspore/mindformers.git && \
    cd mindformers && \
    bash build.sh 

COPY entrypoint.sh .
