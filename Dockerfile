# Base image
FROM mcr.microsoft.com/vscode/devcontainers/base:debian AS base

# Update packages
RUN apt-get update && \
  apt-get install -y curl jq git xxd

# Set the default shell to zsh
ENV SHELL=/usr/bin/zsh
SHELL ["/usr/bin/zsh", "-c"]

# Copy foundry tools
COPY --from=ghcr.io/foundry-rs/foundry:stable /usr/local/bin/chisel /usr/local/bin/chisel
COPY --from=ghcr.io/foundry-rs/foundry:stable /usr/local/bin/cast /usr/local/bin/cast

# Copy your script
COPY safe_hashes.sh .
ENTRYPOINT ["bash", "./safe_hashes.sh"]