FROM ghcr.io/vmware-tanzu-labs/educates-jdk17-environment:2.6.16

USER root

# Tanzu CLI
RUN echo $' \n\
[tanzu-cli] \n\
name=Tanzu CLI \n\
baseurl=https://storage.googleapis.com/tanzu-cli-os-packages/rpm/tanzu-cli \n\
enabled=1 \n\
gpgcheck=1 \n\
repo_gpgcheck=1 \n\
gpgkey=https://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub ' >> /etc/yum.repos.d/tanzu-cli.repo
RUN yum install -y tanzu-cli
RUN yes | tanzu plugin install --group vmware-tap/default:v1.6.4


# Install Tanzu Dev Tools
ADD tanzu-vscode-extension.vsix /tmp
ADD tanzu-app-accelerator.vsix /tmp
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=4.17.1
RUN mkdir -p /opt/code-server/ && cp -rf /usr/lib/code-server/* /opt/code-server/
RUN rm -rf /usr/lib/code-server /usr/bin/code-server

RUN code-server --install-extension /tmp/tanzu-vscode-extension.vsix
RUN code-server --install-extension /tmp/tanzu-app-accelerator.vsix

RUN curl -fsSL https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.sh | bash 
RUN chown -R eduk8s:users /home/eduk8s/.tilt-dev

RUN chown -R eduk8s:users /home/eduk8s/.cache
RUN chown -R eduk8s:users /home/eduk8s/.local
RUN chown -R eduk8s:users /home/eduk8s/.config


RUN curl -L -o /usr/local/bin/hey https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64 && \
    chmod 755 /usr/local/bin/hey

# TBS
RUN curl -L -o /usr/local/bin/kp https://github.com/buildpacks-community/kpack-cli/releases/download/v0.12.0/kp-linux-amd64-0.12.0 && \
  chmod 755 /usr/local/bin/kp

# Install krew
RUN \
( \
  set -x; cd "$(mktemp -d)" && \
  OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
  KREW="krew-${OS}_${ARCH}" && \
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
  tar zxvf "${KREW}.tar.gz" && \
  ./"${KREW}" install krew \
)
RUN echo "export PATH=\"${KREW_ROOT:-$HOME/.krew}/bin:$PATH\"" >> ${HOME}/.bashrc
ENV PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
ENV KUBECTL_VERSION=1.25
RUN kubectl krew install tree
RUN kubectl krew install eksporter
RUN chmod 775 -R $HOME/.krew

# Utilities
RUN yum install moreutils wget ruby -y

RUN chown -R eduk8s:users /home/eduk8s/.config

RUN rm -rf /tmp/*

USER 1001

RUN fix-permissions /home/eduk8s