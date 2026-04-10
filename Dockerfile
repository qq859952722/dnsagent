FROM debian:bullseye-slim

# 复制rootfs到镜像根目录
COPY rootfs/ /

# 确保init.sh可执行
RUN chmod +x /bin/init.sh

# 执行initialize_system方法
RUN /bin/init.sh initialize_system

# 设置启动时执行start_services方法
CMD ["/bin/init.sh", "start_services"]