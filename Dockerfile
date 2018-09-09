FROM ubuntu:18.04

WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates wget curl git npm libhiredis-dev make gcc g++ nginx

RUN mkdir -p ~/.pip && echo [global] > ~/.pip/pip.conf && echo "index-url = https://pypi.mirrors.ustc.edu.cn/simple" >> ~/.pip/pip.conf \
    && echo registry=http://npmreg.mirrors.ustc.edu.cn/ > ~/.npmrc \
    && sed -i 's@ .*.ubuntu.com@ https://mirrors.ustc.edu.cn@g' /etc/apt/sources.list \
    && npm install -g yarn typescript  \
    && yarn config set registry https://registry.npm.taobao.org --global \
    && git clone https://github.com/thx/rap2-delos.git \
    && git clone https://github.com/thx/rap2-dolores.git \
    && cd /app/rap2-dolores  && yarn install && yarn run build \
    && cd /app/rap2-delos    && yarn install && yarn run build 
