#FROM node:8.12.0-stretch AS build
FROM ubuntu:18.04 AS build

WORKDIR /tmp
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates wget curl git npm libhiredis-dev make gcc g++ 


RUN npm install -g yarn typescript serve  \
    && git clone https://github.com/thx/rap2-delos.git \
    && git clone https://github.com/thx/rap2-dolores.git 
RUN cd /tmp/rap2-dolores  && sed -i "s/serve.*,/serve: '' ,/g" src/config/config.prod.ts && npm install && npm run build 
RUN cd /tmp/rap2-delos    ;  sed -i -e 's/noImplicitThis".*,/noImplicitThis": false,/g' -e 's/noImplicitAny".*,/noImplicitAny": false,/g' tsconfig.json ; npm install; npm install; npm run build ;
RUN mkdir -p /app/rap2-dolores /app/rap2-delos && cp -rv /tmp/rap2-dolores/build /app/rap2-dolores \
    && cp -rv /tmp/rap2-delos /app


#FROM node:8.12.0-stretch
FROM ubuntu:18.04

ENV LANG=C.UTF-8 TZ='Asia/Shanghai'
    
COPY --from=build /app  /app/
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates libhiredis-dev npm nginx default-mysql-client runit cron \
    && mkdir -p /etc/service/nginx /etc/service/nodejs /etc/service/cron \
    && bash -c 'echo -e "#!/bin/bash\nexec /usr/sbin/nginx -g \"daemon off;\"" > /etc/service/nginx/run' \
    && bash -c 'echo -e "#!/bin/bash\nexec /usr/bin/node /app/rap2-delos/dist/dispatch.js " > /etc/service/nodejs/run' \
    && bash -c 'echo -e "#!/bin/bash\nexec /usr/sbin/cron -f" > /etc/service/cron/run' \
    && chmod 755 /etc/service/nginx/run /etc/service/nodejs/run /etc/service/cron/run \
    && sed -i '/session    required     pam_loginuid.so/c\#session    required   pam_loginuid.so' /etc/pam.d/cron \
    && bash -c 'echo "0 3 * * * /bin/bash /mysql_backup.sh >> /var/log/mysql_backup.log 2>&1" > /etc/cron.d/mysql_backup'
    
ADD default.conf /etc/nginx/sites-enabled/default

ADD mysql_backup.sh /

CMD ["runsvdir", "/etc/service"]


