FROM ghcr.io/xe/devcontainer-base/pre/node

WORKDIR /opt/setup/scripts
COPY .devcontainer/scripts .
RUN for script in /opt/setup/scripts/*; do bash $script; done

CMD ["/usr/bin/sleep", "infinity"]