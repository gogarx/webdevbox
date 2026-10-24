FROM docker.io/library/archlinux as update-mirrors
ARG PACMAN_PARALLELDOWNLOADS=5
RUN pacman-key --init \
    && pacman-key --populate archlinux \
    && sed 's/ParallelDownloads = \d+/ParallelDownloads = ${PACMAN_PARALLELDOWNLOADS}/g' -i /etc/pacman.conf \
    && sed 's/NoProgressBar/#NoProgressBar/g' -i /etc/pacman.conf

# update mirrorlist
RUN sed -i 's/^Server = https:\/\/.*/Server = https:\/\/archlinux.c3sl.ufpr.br\/$repo\/os\/$arch/' /etc/pacman.d/mirrorlist

RUN pacman -Syyu --needed --noconfirm \
        aardvark-dns \
        apparmor \
        atuin \
        base-devel \
        bat \
        chromium \
        chezmoi \
        cifs-utils \
        curl \
        dust \
        elixir \
        exa \
        fd \
        ffmpeg \
        fish \
        fzf \
        fuse-overlayfs \
        gitlab-runner \
        git \
        git-lfs \
        go \
        helm \
        htop \
        imagemagick \
        links \
        lsof \
        jdk11-openjdk \
        jdk8-openjdk \
        java-runtime-common \
        fakeroot \
        debugedit \
        jq \
        mariadb-clients \
        memcached \
        opencv \
        openssh \
        pgcli \
        php \
        podman \
        podman-compose \
        podman-docker \
        postgresql-libs \
        procs \
        redis \
        ripgrep \
        rust \
        starship \
        strace \
        sqlite3 \
        sudo \
        terraform \
        tmux \
        tmuxp \
        unzip \
        wget \
        wl-clipboard \
        xsel \
        xclip \
        yarn \
        zellij \
        zsh-autosuggestions \
        zsh-completions \
        zsh-history-substring-search \
        zsh-syntax-highlighting \
    && archlinux-java set java-8-openjdk \
    && { pacman -Rns --noconfirm $(pacman -Qtdq) || echo "Nothing to remove"; } \
    && pacman -Scc --noconfirm \
    && rm -Rf /var/cache/pacman/pkg/*

# optional directory to mount the host's home directory
RUN mkdir -p /mnt/host

# Install Yay and continue with it
FROM update-mirrors as build-helper-img
ARG AUR_USER=builduser
ARG HELPER=yay
ARG LUNARVIM_VERSION=1.3
ARG NEOVIM_VERSION=0.9.5

ADD helpers/add-aur.sh /root
RUN bash /root/add-aur.sh ${AUR_USER} ${HELPER}

# azure and google packages, each are more than 600 MB, uncompressed
# insomnia and postman, are also each larger than 300 MB
# dunno if they're worth having built-in. leaving just insomnia
RUN aur-install \
        asdf-vm \
        aws-cli \
        # azure-cli-bin \ 
        fselect-bin \
        # google-cloud-sdk \ heroku-cli-bin \
        insomnia-bin \
        kubectl-bin \
        kustomize-bin \
        openshift-client-bin \
        # postman-bin \
        skaffold-bin \
        terragrunt \
        tldr \
        urlview \
        wrk \
        zsh-git-prompt \
        zsh-vi-mode \
    ; pacman -D --asexplicit asdf-vm \
    ; pacman -Rns $(pacman -Qtdq) || echo "Nothing to remove" \
    ; pacman -Scc --noconfirm \
    ; rm -Rf .cache/yay/* \
    ; rm -Rf /var/cache/foreign-pkg/*

# STEP 9 em diante: Sintaxe atualizada para o ASDF v0.20+ (sem hifens)
RUN asdf plugin add crystal \
    && asdf plugin add dotnet-core \
    && asdf plugin add elixir \
    && asdf plugin add erlang \
    && asdf plugin add golang \
    && asdf plugin add haskell \
    && asdf plugin add java \
    && asdf plugin add julia \
    && asdf plugin add kotlin \
    && asdf plugin add lua \
    && asdf plugin add nim \
    && asdf plugin add nodejs \
    && asdf plugin add php \
    && asdf plugin add python \
    && asdf plugin add ruby \
    && asdf plugin add rust \
    && asdf plugin add scala \
    && asdf plugin add zig

# STEP 10/28 corrigido: Usando a nova sintaxe 'asdf set -u' para definir as versões globais
RUN asdf install python latest \
    && asdf install nodejs latest \
    && asdf set -u python latest \
    && asdf set -u nodejs latest

# Configuração global do Git ANTES do instalador do LunarVim: o repositório
# jose-elias-alvarez/null-ls.nvim foi removido do GitHub (o 404 faz o git pedir
# credenciais e o lazy.nvim aborta com "terminal prompts disabled"), então o
# insteadOf redireciona para o fork vivo nvimtools/none-ls.nvim, que preserva o
# módulo lua/null-ls (drop-in). A segunda linha normaliza URLs SSH para HTTPS.
RUN git config --global url."https://github.com/nvimtools/none-ls.nvim".insteadOf "https://github.com/jose-elias-alvarez/null-ls.nvim" \
    && git config --global url."https://github.com/".insteadOf "git@github.com:"

# STEP 11/28: Neovim fixado em 0.9.5 via tarball oficial do GitHub (em /opt/nvim-linux64),
# pois o pacote do Arch instala sempre a versão mais recente, que quebra o LunarVim com
# erro de tree-sitter (query_predicates). O LunarVim também é fixado no branch estável
# release-1.3/neovim-0.9 (via LV_BRANCH), pois o master exige Neovim 0.10+. O python-pip
# e o env PIP_BREAK_SYSTEM_PACKAGES=1 viabilizam o pynvim do instalador apesar do PEP 668
# do Arch, sem o qual o script morre silenciosamente sob set -e. O nodejs e o npm explícitos
# suprem o Mason, pois o Arch separou o npm do nodejs (agora é só optdepends).
RUN curl -fsSL https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux64.tar.gz -o /tmp/nvim-linux64.tar.gz \
    && tar -xzf /tmp/nvim-linux64.tar.gz -C /opt \
    && rm -f /tmp/nvim-linux64.tar.gz \
    && ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim \
    && pacman -S --needed --noconfirm git make gcc cliphist python-pip nodejs npm \
    && PIP_BREAK_SYSTEM_PACKAGES=1 LV_BRANCH="release-${LUNARVIM_VERSION}/neovim-0.9" bash <(curl -s "https://raw.githubusercontent.com/lunarvim/lunarvim/release-${LUNARVIM_VERSION}/neovim-0.9/utils/installer/install.sh") -y

# STEP 12: Esqueleto LEVE em /etc/skel — o distrobox-init percorre /etc/skel arquivo a
# arquivo a cada boot do contêiner, então árvores pesadas lá custam MINUTOS de inicialização
# (677 MB de .asdf + 89 MB de lunarvim afogavam o init). As árvores pesadas passam a ser
# fonte de resgate em /opt/webdevbox-defaults, para cópia manual à home persistida (padrão
# da Terceira Batalha). No skel ficam só os arquivos pequenos: shim lvim e configs.
RUN mkdir -p /etc/skel/.local/bin \
    && mkdir -p /etc/skel/.config/lvim \
    && mkdir -p /opt/webdevbox-defaults/.local/share \
    && mv /root/.local/share/lunarvim /opt/webdevbox-defaults/.local/share/lunarvim \
    && mv /root/.asdf /opt/webdevbox-defaults/asdf \
    && mv /root/.local/bin/lvim /etc/skel/.local/bin/lvim \
    && cp /etc/skel/.local/bin/lvim /usr/local/bin/lvim \
    && sed 's/\/root/$HOME/g' -i /etc/skel/.local/bin/lvim

COPY helpers/config.lua /etc/skel/.config/lvim
COPY helpers/webdevbox.zsh /etc/skel/.config/zsh/webdevbox.zsh
COPY helpers/initial_setup.zsh /etc/skel/.zshrc

USER root
RUN touch /var/tmp/first-time.lock

# configure podman for rootless
RUN groupadd --system podman \
    && useradd --system --shell /usr/bin/nologin --create-home --home-dir /home/podman podman -g podman \
    && echo podman:10000:65536 > /etc/subuid \
    && echo podman:10000:65536 > /etc/subgid

VOLUME /var/lib/containers
VOLUME /home/podman/.local/share/containers

ADD helpers/containers.conf /etc/containers/containers.conf
ADD helpers/podman-containers.conf /home/podman/.config/containers/containers.conf

RUN chown podman:podman -R /home/podman

# chmod containers.conf and adjust storage.conf to enable Fuse storage.
RUN chmod 644 /etc/containers/containers.conf \
    ; test -f /etc/containers/storage.conf || cp /usr/share/containers/storage.conf /etc/containers/storage.conf \
    ; sed -i -e 's|^#mount_program = .*|mount_program = "/usr/bin/fuse-overlayfs"|' \
    -e 's|^# additionalimagestores = .*|additionalimagestores = ["/var/lib/shared"]|' \
    -e 's|^mountopt = .*|mountopt = "nodev,fsync=0"|' \
    -e 's|^#ignore_chown_errors = .*|ignore_chown_errors = "true"|' \
    /etc/containers/storage.conf

RUN mkdir -p /var/lib/shared/overlay-images \
    /var/lib/shared/overlay-layers \
    /var/lib/shared/vfs-images \
    /var/lib/shared/vfs-layers \
    ; touch /var/lib/shared/overlay-images/images.lock \
    ; touch /var/lib/shared/overlay-layers/layers.lock \
    ; touch /var/lib/shared/vfs-images/images.lock \
    ; touch /var/lib/shared/vfs-layers/layers.lock

ENV _CONTAINERS_USERNS_CONFIGURED=""

# STEP 27/28: adiciona ~/.local/bin ao PATH de login de forma limpa, inserindo a chamada
# de append_path ANTES do 'unset -f append_path' que o perfil moderno do Arch executa no
# final. (O antigo sed 's/PATH=/.../' mutilava a função e colava o caminho sem separador;
# o source de /opt/asdf-vm/asdf.sh foi removido: o asdf novo é binário Go em /usr/bin/asdf.)
RUN sed -i '/^unset -f append_path$/i append_path "$HOME/.local/bin"' /etc/profile

CMD ["/bin/zsh"]
