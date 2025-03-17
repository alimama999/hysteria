FROM golang:latest AS builder

# 设置工作目录
WORKDIR /app

# 下载 Hysteria 2 源码
RUN git clone --depth=1 https://github.com/apernet/hysteria /app/hysteria2

# 构建 Hysteria 2
WORKDIR /app/hysteria2
RUN go build -o /app/hysteria2-server ./cmd/server

# 生产环境镜像
FROM debian:latest
WORKDIR /root/
COPY --from=builder /app/hysteria2-server /usr/local/bin/hysteria2-server

# 生成 config.yaml
RUN echo 'listen: :"$HYSTERIA_PORT"' > /root/config.yaml && \
    echo 'protocol: "$HYSTERIA_PROTOCOL"' >> /root/config.yaml && \
    echo 'auth:\n  type: password\n  password: "$HYSTERIA_PASSWORD"' >> /root/config.yaml && \
    if [ "$HYSTERIA_GENERATE_CERT" = "true" ]; then \
        echo 'cert: "/root/selfsigned-cert.pem"' >> /root/config.yaml && \
        echo 'key: "/root/selfsigned-key.pem"' >> /root/config.yaml && \
        openssl req -x509 -newkey rsa:4096 -keyout /root/selfsigned-key.pem -out /root/selfsigned-cert.pem -days 365 -nodes -subj "/CN=localhost"; \
    fi && \
    echo 'masquerade:\n  type: proxy\n  proxy:\n    url: "$HYSTERIA_MASQUERADE"' >> /root/config.yaml

# 启动 Hysteria 2 服务器
CMD ["sh", "-c", "hysteria2-server -c /root/config.yaml"]
