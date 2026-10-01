# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Build libfprint-TOD from source on the same base image, so it matches its libraries
FROM ghcr.io/ublue-os/bluefin:stable AS tod-build
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build-tod.sh

# Base Image
FROM ghcr.io/ublue-os/bluefin:stable

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=tod-build,source=/out,target=/tod \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

RUN bootc container lint
