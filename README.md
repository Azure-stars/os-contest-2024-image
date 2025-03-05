# OS-Contest-image

本仓库为 OS 比赛使用的参考镜像仓库，根目录下的 Dockerfile 描述了镜像的构建方式。

## 镜像用途

- 构建 OS 比赛测例：OS 比赛测例源码详见 [testsuit-for-multiarch](https://github.com/oscomp/testsuits-for-oskernel/tree/2025_multiarch)。在本仓库生成的镜像所构建的容器下进入该源码仓库，按照 README.md 中的指引即可构建测例。

- 运行 OS 比赛 demo：OS 比赛的一个 demo 为 [starry-next](https://github.com/oscomp/starry-next)。它支持 x86_64/riscv64/aarch64/loongarch64 四种指令架构，对比赛的测例的支持正在不断完善中。在本仓库所构建的容器下进入该源码仓库，按照 README.md 中的指引即可构建 demo 内核并运行比赛测例。关于 demo 内核运行比赛测例的更多信息详见[Starry-Tutorial-Book](https://azure-stars.github.io/Starry-Tutorial-Book/ch01-04.html)。

- 评测比赛内核：当选手在 OS 比赛上提交了自己的内核之后，平台会在该镜像所构建的容器中对选手的内核进行编译、运行，并按照其输出的结果进行评测。**需要注意的是，比赛评测的过程中可以认为几乎不联网，因此需要选手将内核依赖但容器本身未提供的第三方库打包一同上传**。

## 镜像构建方式

本仓库提供了两个 Dockerfile。Dockerfile.online 适用于网络环境良好（可以使用代理）的情况。Dockerfile 用于网络环境较差（无代理或者网络较慢）的情况，它所使用的本地依赖是从 Dockerfile.online 所指定的资源中预下载后直接拷贝到本仓库中的，因此两者实际构建的镜像是一致的。

构建方式和正常的 Docker 镜像构建方式一致，只是需要指定 Dockerfile 的路径。

例如：

```bash
docker build -t os-contest-image -f Dockerfile .

docker build -t os-contest-image-online -f Dockerfile.online .
```

如果想在构建 Docker 镜像时使用代理，请参考[Set proxy using the CLI](https://docs.docker.com/engine/cli/proxy/#set-proxy-using-the-cli)。

## 镜像使用方式
我们以构建 OS 比赛测例进行示范。可以执行如下操作：

```bash
$ git clone https://github.com/oscomp/testsuits-for-oskernel -b 2025_multiarch
$ cd testsuits-for-oskernel
$ docker create --name os-contest-image os-contest-image --privileged -v .:/code -w /code os-contest-image sleep inf
$ docker start os-contest-image
$ docker exec -it os-contest-image /bin/bash

# In the container
$ make all
```

当执行了如上操作，可以完成 RISCV 架构的测例构建。其他架构的测例构建方式类似，只需要将 `make all` 替换为 `make ARCH=aarch64 all` 或者 `make ARCH=loongarch64 all` 即可。注意上述操作需要在镜像内执行。

生成的测例会位于 `testsuits-for-oskernel/sdcard` 目录下。因为容器和宿主机共享了 `testsuits-for-oskernel` 目录，所以可以在宿主机上直接查看生成的测例。

## 镜像工具链说明
关于 Docker 镜像中的工具链版本说明如下：

- x86_64-linux-musl-gcc: (GCC) 11.2.1 20211120
- riscv64-linux-musl-gcc: (GCC) 11.2.1 20211120
- aarch64-linux-musl-gcc: (GCC) 11.2.1 20211120
- loongarch64-linx-musl-gcc: (GCC) 13.2.0
- x86_64-linux-gnu-gcc: (Debian 12.2.0-14) 12.2.0
- riscv64-linux-gnu-gcc: (Debian 12.2.0-13) 12.2.0
- aarch64-linux-gnu-gcc: (Debian 12.2.0-14) 12.2.0
- loongarch64-linux-gnu-gcc: (GCC) 13.2.0

- qemu: 9.2.1
- rust: 1.86.0-nightly (6067b3631 2025-01-17)
- rustup toolchain: 2025-01-18 nightly


由于 loongarch64-gnu-gcc 仅在 Ubuntu 24.10 及以后才在 apt 源中提供，因此目前我们使用的是自行编译的版本。等 apt 源支持进一步稳定之后，我们会考虑使用 apt 源中的版本。

当该镜像用于比赛评测时，也提供了一些自带的 Rust 第三方库：
- rustsbi="0.3.2"
- futures-lite="1.12.0"
- crossbeam-queue="0.3.8"
- heapless="0.7.16"
- async-task="4.4.0"
- bitflags="2.0.2"
- log = "0.4"
- num_enum = { version = "0.5.11", default-features = false }

当选手使用这些第三方库时，无需自行打包上传。

以上依赖的工具链来源均可参照 [Dockerfile.online](./Dockerfile.online)。