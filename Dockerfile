# Base debian build (latest).
FROM mcr.microsoft.com/vscode/devcontainers/base:debian

# Update packages.
RUN apt-get update

# Set the default shell to zsh
ENV SHELL=/usr/bin/zsh

# Running everything under zsh
SHELL ["/usr/bin/zsh", "-c"]

# Dropping privileges
USER vscode

FROM ghcr.io/foundry-rs/foundry:stable AS foundry

RUN apt-get update && \
  apt-get install -y curl jq git xxd 

COPY --from=foundry /usr/local/bin/chisel /usr/local/bin/chisel
COPY --from=foundry /usr/local/bin/cast /usr/local/bin/cast

COPY safe_hashes.sh .
ENTRYPOINT ["bash", "./safe_hashes.sh"]