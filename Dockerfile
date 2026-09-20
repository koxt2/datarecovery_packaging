FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    devscripts \
    debhelper \
    build-essential \
    dput \
    gnupg \
    gnupg-agent \
    pinentry-curses \
    lintian \
    python3 \
    meson \
    ninja-build \
    gettext \
    pkg-config \
    libgtk-4-dev \
    libadwaita-1-dev \
    libglib2.0-dev \
    desktop-file-utils \
    && rm -rf /var/lib/apt/lists/*

# Allow dput to find the Launchpad PPA config
RUN echo "[DEFAULT]\ndefault_host_main = notspecified\n\n[ppa]\nfqdn = ppa.launchpad.net\nmethod = ftp\nincoming = ~%(name)s/ubuntu/\nlogin = anonymous\nallow_unsigned_uploads = 0\n" > /etc/dput.cf

RUN mkdir -p /work/DataRecovery
WORKDIR /work/DataRecovery

CMD ["/bin/bash"]
