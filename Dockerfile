FROM debian:12-slim

RUN apt-get update && apt-get install -y \
    qemu-system-x86 qemu-utils cloud-image-utils \
    iproute2 iptables curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /vm

# Download Debian 12 Generic Cloud Image
RUN curl -fsSL -o debian12.qcow2 https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

# Resize disk image ke 10GB
RUN qemu-img resize debian12.qcow2 10G

COPY user-data network-config start.sh ./
RUN chmod +x start.sh

CMD ["./start.sh"]