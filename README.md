# jetson-orin-agx-builder

Um ambiente de build baseado em Docker para gerar imagens de flash reproduzíveis da Jetson Linux (L4T) para a **Jetson Orin AGX 64GB**, sem a necessidade de um host Ubuntu nativo.

## Como funciona

A geração da imagem e o processo de gravação (*flash*) são divididos em duas etapas separadas:
1. **Build** — executado dentro do Docker, sem necessidade de uma Jetson conectada. Gera um arquivo tarball da imagem de flash.
2. **Flash** — executado com a Jetson conectada em modo de recuperação (*recovery mode*). Consome o tarball gerado na etapa 1.

Isso permite gerar uma imagem validada uma única vez e gravá-la no dispositivo sempre que necessário.

## Requisitos

* Docker (com acesso de root)
* Host Linux (necessário para o repasse de USB durante o flash)
* Jetson Orin AGX 64GB DevKit

## Estrutura do repositório

```text
.
├── Dockerfile
├── README.md
└── output/          # imagens de flash geradas são salvas aqui (ignorado pelo Git)
```

## Uso

### 1. Configurar o suporte a binários aarch64 no host

O processo de build faz `chroot` no rootfs da Jetson (que é aarch64) para instalar pacotes via `dpkg`. Como o host é x86_64, o kernel precisa saber como executar binários aarch64 — isso é feito via `binfmt_misc` com QEMU.

Execute **uma vez** no host (precisa ser refeito após reinicialização):

```bash
sudo apt install qemu-user-static
sudo systemctl restart systemd-binfmt
```

Ou, alternativamente, via Docker:

```bash
sudo docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

> **Por que isso é necessário?** O script `apply_binaries.sh` da NVIDIA faz `chroot` no rootfs aarch64 e executa binários como `dpkg` para instalar pacotes. Sem o QEMU registrado como handler no kernel, o sistema não sabe como executar esses binários e retorna `Exec format error`.

### 2. Construir a imagem Docker

```bash
sudo docker build -t jetson-agx-orin-builder .
```

Este comando baixa o BSP do L4T e o sistema de arquivos raiz (*sample root filesystem*) da NVIDIA, aplica os binários necessários e empacota tudo dentro da imagem Docker. A primeira execução pode demorar um pouco.

### 3. Gerar a imagem de flash

A Jetson não é necessária nesta etapa.

```bash
sudo docker run --rm \
  --privileged \
  -v $(pwd)/output:/workspace/output \
  jetson-agx-orin-builder \
  bash -c "cd Linux_for_Tegra && \
    ./tools/kernel_flash/l4t_initrd_flash.sh --no-flash \
    jetson-agx-orin-devkit internal && \
    cp tools/kernel_flash/images/internal/*.tar.gz /workspace/output/"
```

O arquivo tarball da imagem de flash será salvo no diretório `output/` do host.

### 4. Gravar (flashar) a Jetson

Primeiro, coloque a Jetson em modo de recuperação:
1. Desligue o dispositivo.
2. Pressione e mantenha pressionado o botão **Recovery**.
3. Pressione e solte o botão **Power**.
4. Aguarde 2 segundos e solte o botão **Recovery**.
5. Conecte o cabo USB-C (a porta ao lado do conector de 40 pinos) ao host.

Verifique se o dispositivo está visível:

```bash
lsusb | grep NVIDIA # deve exibir: NVIDIA Corp. APX 
```

Em seguida, execute o flash:

```bash
sudo docker run --rm \
  --privileged \
  -v /dev/bus/usb:/dev/bus/usb \
  -v $(pwd)/output:/workspace/output \
  jetson-agx-orin-builder \
  bash -c "cd Linux_for_Tegra && \
    ./tools/kernel_flash/l4t_initrd_flash.sh --flash-only \
    jetson-agx-orin-devkit internal"
```

## Personalizando o sistema de arquivos raiz (root filesystem)

Para pré-instalar pacotes ou adicionar arquivos de configuração antes de gerar a imagem, inclua etapas adicionais no `Dockerfile` após a execução de `apply_binaries.sh`. O rootfs está localizado em `Linux_for_Tegra/rootfs/` dentro do contêiner.

Exemplo — pré-instalar um pacote no rootfs:

```dockerfile
RUN cd Linux_for_Tegra && \
    chroot rootfs apt-get install -y <seu-pacote>
```

## Versão do L4T

Este builder utiliza o **L4T r36.4.4** (JetPack 6.1), baseado no Ubuntu 22.04.
Para atualizar a versão, substitua as URLs de download do BSP e do rootfs no `Dockerfile` e atualize a tag de versão correspondente.

## Observações

* `--privileged` é necessário para acesso aos dispositivos `loop` durante a geração da imagem.
* O diretório `output/` é montado via *bind mount* para que a imagem permaneça disponível após o encerramento do contêiner.
* O processo de flash requer um host Linux; o dispositivo USB precisa ser repassado corretamente ao contêiner.
* Se o flash falhar no meio do processo, coloque a Jetson novamente em modo de recuperação e tente outra vez.
* O registro do `binfmt_misc` não persiste após reinicialização do host — execute o passo 1 novamente se necessário.

