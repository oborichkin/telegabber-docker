FROM ubuntu:20.04
LABEL maintainer="justinas@eofnet.lt"
WORKDIR /root/


RUN apt-get update && ln -fs /usr/share/zoneinfo/Europe/Vilnius /etc/localtime && \
   DEBIAN_FRONTEND=noninteractive apt-get install -y prosody nginx supervisor

# copy init
COPY files/init.sh /init.sh
# copy supervisor conf
COPY files/supervisor-telegabber.conf /etc/supervisor/conf.d//supervisor-telegabber.conf
# copy libs and files from libs image
COPY --from=telegabber-libs:latest /usr/local/lib/libtd* /usr/local/lib/
COPY --from=telegabber-libs:latest /usr/local/lib/pkgconfig/td* /usr/local/lib/pkgconfig/
COPY --from=telegabber-libs:latest /usr/local/lib/cmake/Td /usr/local/lib/cmake/
COPY --from=telegabber-libs:latest /usr/local/include/td/ /usr/local/include/
# copy telegabber
COPY --from=telegabber-libs:latest /telegabber /root/telegabber

RUN mkdir -p /var/www/telegabber/content/ && sed -i -e '/\[::\]:80/d' /etc/nginx/sites-enabled/default && \
    sed -i -e 's/allow_registration = false/allow_registration = true/' /etc/prosody/prosody.cfg.lua && \
    sed -i -e 's/"tls/--"tls/' /etc/prosody/prosody.cfg.lua && \
    sed -i -e 's/--"legacyauth/"legacyauth/' /etc/prosody/prosody.cfg.lua && \
    sed -i -e 's/c2s_require_encryption = true/c2s_require_encryption = false/' /etc/prosody/prosody.cfg.lua && \
    sed -i -e 's/authentication = "internal_hashed"/authentication = "internal_plain"/' /etc/prosody/prosody.cfg.lua

# copy telegabber config
COPY files/config.yml /root/telegabber/config.yml
# copy prosody configs
COPY files/component.cfg.lua /etc/prosody/conf.d/component.cfg.lua
COPY files/settings.cfg.lua /etc/prosody/conf.d/settings.cfg.lua
# copy nginx config
COPY files/nginx_host.conf /etc/nginx/sites-enabled/nginx_host.conf

VOLUME ["/var/lib/prosody", "/sessions"]

# Configure Services and Port
ENTRYPOINT ["/init.sh"]
 
EXPOSE 5222
EXPOSE 5223
EXPOSE 5269
EXPOSE 80
