FROM swr.cn-central-221.ovaijisuan.com/wuh-aicc_dxy/mindspore_2_0_0:mindspore2.0.0-cann6.3rc1-py_3.9-euler_2.8
USER root
RUN git clone -b dev https://gitee.com/mindspore/mindformers.git && \
    cd mindformers && \
    bash build.sh && \
    pip install --no-cache-dir notebook ipywidgets
WORKDIR  /home/ma-user
COPY --chown=ma-user jupyter_server_config.json .jupyter/jupyter_server_config.json
COPY --chown=ma-user docker-entrypoint.sh docker-entrypoint.sh
EXPOSE 8888 8000 6379
RUN chmod +x docker-entrypoint.sh
CMD ["./docker-entrypoint.sh"]
