FROM jeessy/ddns-go:v6.12.2

ENV DDNS_TEMPLATE_PATH=/etc/ddns-go/config.tmpl \
    DDNS_CONFIG_PATH=/root/.ddns_go_config.yaml \
    TZ=Etc/UTC

# 安装 envsubst（在 gettext 包里）
RUN set -eux; apk add --no-cache ca-certificates tzdata gettext; update-ca-certificates

COPY config.tmpl /etc/ddns-go/config.tmpl
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && test -s /etc/ddns-go/config.tmpl

ENTRYPOINT ["/entrypoint.sh"]
CMD ["-l", ":9876", "-f", "300"]
