FROM rust:slim
USER root

# Update apt source
RUN apt-get update && apt-get install -y wget gcc-riscv64-linux-gnu \
    gcc-aarch64-linux-gnu linux-libc-dev make python3 \
    xz-utils python3-venv ninja-build bzip2 meson \
    pkg-config libglib2.0-dev git libslirp-dev cmake dosfstools build-essential gdb-multiarch automake

RUN echo /etc/apt/sources.list << deb http://apt.llvm.org/bookworm/ llvm-toolchain-bookworm main
RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc

RUN apt-get update \
    && apt-get install -y --no-install-recommends libclang-19-dev \
    && rm -rf /var/lib/apt/lists/*

# Musl toolchain
WORKDIR /opt
COPY x86_64-linux-musl.tar.xz .
COPY riscv64-linux-musl.tar.xz .
COPY aarch64-linux-musl.tar.xz .
COPY loongarch64-linux-musl-cross.tgz .
RUN tar -xvf x86_64-linux-musl.tar.xz \
    && tar -xvf riscv64-linux-musl.tar.xz \
    && tar -xvf aarch64-linux-musl.tar.xz \
    && tar -xvf loongarch64-linux-musl-cross.tgz \
    && mv loongarch64-linux-musl-cross loongarch64-linux-musl \
    && rm *.tgz && rm *.tar.xz

ENV PATH=/opt/x86_64-linux-musl/bin:/opt/riscv64-linux-musl/bin:/opt/aarch64-linux-musl/bin:/opt/loongarch64-linux-musl/bin:$PATH

# Add gnu toolchain
# TODO: loongarch toolchain has benn supported in Ubuntu 24.10
COPY gcc-13.2.0-loongarch64-linux-gnu.tgz /usr/gcc-13.2.0-loongarch64-linux-gnu.tgz
RUN tar xavf /usr/gcc-13.2.0-loongarch64-linux-gnu.tgz -C /usr/ && rm /usr/gcc-13.2.0-loongarch64-linux-gnu.tgz && mv /usr/gcc-13.2.0-loongarch64-linux-gnu /usr/loongarch64-linux-gnu
# Unify the path of libc.so.6(speciall for loongarch64)
RUN cp /usr/loongarch64-linux-gnu/sysroot/usr/lib64/libc.so.6 /usr/loongarch64-linux-gnu/lib/libc.so.6
ENV PATH=/usr/loongarch64-linux-gnu/bin:$PATH

# QEMU 9.2.1
COPY qemu-9.2.1.tar.xz .
RUN tar xf qemu-9.2.1.tar.xz \
    && cd qemu-9.2.1 \
    && ./configure --prefix=/qemu-bin-9.2.1 \
    --target-list=loongarch64-softmmu,riscv64-softmmu,aarch64-softmmu,x86_64-softmmu \
    --enable-gcov --enable-debug --enable-slirp \
    && make -j$(nproc) \
    && make install \
    && rm -rf qemu-9.2.1.tar.xz

ENV PATH=/qemu-bin-9.2.1/bin:$PATH


# Add nightly toolchain
RUN rustup install nightly-2025-01-18
RUN rustup default nightly-2025-01-18
RUN rustup component add llvm-tools-preview
RUN rustup target add x86_64-unknown-none
RUN rustup target add riscv64imac-unknown-none-elf
RUN rustup target add riscv64gc-unknown-none-elf
RUN rustup target add aarch64-unknown-none
RUN rustup target add aarch64-unknown-none-softfloat
RUN rustup target add loongarch64-unknown-linux-gnu
RUN rustup target add loongarch64-unknown-none

RUN rustup target add x86_64-unknown-none --toolchain nightly-2025-01-18
RUN rustup target add riscv64imac-unknown-none-elf --toolchain nightly-2025-01-18
RUN rustup target add riscv64gc-unknown-none-elf --toolchain nightly-2025-01-18
RUN rustup target add aarch64-unknown-none --toolchain nightly-2025-01-18
RUN rustup target add aarch64-unknown-none-softfloat --toolchain nightly-2025-01-18
RUN rustup target add loongarch64-unknown-linux-gnu --toolchain nightly-2025-01-18
RUN rustup component add llvm-tools-preview --toolchain nightly-2025-01-18

RUN cargo +nightly-2025-01-18 install cargo-binutils

# When under offline environment, we need add necessary dependencies through proxy temporarily
COPY oscomp-dependencies-2023 /oscomp-dependencies-2023
# If it need proxy, then add https_proxy environment variable in the build args
# reference: https://docs.docker.com/engine/cli/proxy/#set-proxy-using-the-cli
RUN cd /oscomp-dependencies-2023 && cargo build