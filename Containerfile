# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Base Image
FROM quay.io/fedora-ostree-desktops/silverblue:44

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

LABEL org.opencontainers.image.description="EasySpeak-OS: a derivative of Fedora® with EasySpeak voice control. Not Fedora, and not provided or supported by the Fedora Project. Official Fedora: https://fedoraproject.org/ Fedora® is a registered trademark of Red Hat, Inc., or its subsidiaries in the United States and other countries."
LABEL org.opencontainers.image.source="https://github.com/ctsdownloads/easyspeak-os"

RUN bootc container lint
