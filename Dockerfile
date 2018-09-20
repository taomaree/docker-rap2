FROM node:8.12.0-stretch AS build

WORKDIR /tmp
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates wget curl git npm libhiredis-dev make gcc g++ nginx mysql-client

ADD default.conf /etc/nginx/sites-enabled/default

RUN npm install -g yarn typescript serve  \
    && git clone https://github.com/thx/rap2-delos.git \
    && git clone https://github.com/thx/rap2-dolores.git \
    && cd /tmp/rap2-dolores  && sed -i "s/serve.*,/serve: '' ,/g" src/config/config.prod.js && npm install && npm run build \
    && cd /tmp/rap2-delos    && npm install && npm run build \
    && mkdir -p /app/rap2-dolores /app/rap2-delos && cp -rv /tmp/rap2-dolores/build /app/rap2-dolores \
    && cp -rv /tmp/rap2-delos/dist /app/rap2-delos


FROM node:8.12.0-stretch
COPY --from=build /app  /app/
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates libhiredis-dev nginx-light mysql-client runit \
    && bash -c 'echo -e "#!/bin/bash\nexec /usr/sbin/nginx -g \"daemon off;\"" > /etc/service/nginx/run' \
    && bash -c 'echo -e "#!/bin/bash\nexec /usr/bin/node /app/rap2-delos/dist/dispatch.js " > /etc/service/delos/run' \
    && chmod 755 /etc/service/delos/run /etc/service/nginx/run && \
ADD default.conf /etc/nginx/sites-enabled/default

CMD ["runsvdir", "/etc/service"]
