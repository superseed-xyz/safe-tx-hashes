FROM ghcr.io/foundry-rs/foundry:stable AS foundry

FROM debian:12-slim

RUN apt-get update && \
  apt-get install -y curl jq git xxd 

COPY --from=foundry /usr/local/bin/chisel /usr/local/bin/chisel
COPY --from=foundry /usr/local/bin/cast /usr/local/bin/cast

COPY safe_hashes.sh .
ENTRYPOINT ["bash", "./safe_hashes.sh"]