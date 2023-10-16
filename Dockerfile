FROM xiaoql/pytorch-modelzoo:23.0.RC2-1.8.1
RUN pip install --no-cache-dir notebook -i https://pypi.tuna.tsinghua.edu.cn/simple

EXPOSE 8888
CMD ["jupyter", "notebook" ,"--allow-root", "--ip='0.0.0.0'" ,"--no-browser"]
