FROM nobidev/buildkit

RUN apt-get -qq update && \
    apt-get -qq install -y libpcre3-dev libssl-dev perl make build-essential curl && \
    apt-get -qq install -y perl dos2unix mercurial

WORKDIR /src/
COPY ./ ./

RUN make

RUN cat $(find -maxdepth 1 -type f -name "openresty-*.tar.gz" | head -n 1) | tar -xz --strip-components=1 -C /build/
WORKDIR /build/

RUN ./configure -j$(nproc) --prefix=/opt/openresty --conf-path=/etc/nginx/nginx.conf --with-pcre-jit --with-ipv6
RUN make && \
    make install

RUN mv /etc/nginx/ /opt/openresty/nginx/conf/

FROM ubuntu

COPY --from=0 /opt/openresty/ /opt/openresty/

RUN ln -sf /opt/openresty/bin/openresty /usr/local/bin/nginx && \
    ln -sf /opt/openresty/nginx/conf /etc/nginx

WORKDIR /etc/nginx
RUN rm *.default

RUN ln -sf /dev/stderr /opt/openresty/nginx/logs/error.log && \
    ln -sf /dev/stdout /opt/openresty/nginx/logs/access.log

RUN nginx -V && \
    nginx -T >>/dev/null

CMD [ "nginx", "-g", "daemon off;" ]
