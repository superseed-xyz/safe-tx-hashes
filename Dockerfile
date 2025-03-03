# Base image
FROM mcr.microsoft.com/vscode/devcontainers/base:debian AS base

# Update packages and install Node.js and dependencies
RUN apt-get update && \
    apt-get install -y curl jq git xxd && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package.json and install dependencies first (for better caching)
COPY package.json .
RUN npm install

# Install Express and Zod specifically
RUN npm install express zod

# Copy foundry tools
COPY --from=ghcr.io/foundry-rs/foundry:stable /usr/local/bin/chisel /usr/local/bin/chisel
COPY --from=ghcr.io/foundry-rs/foundry:stable /usr/local/bin/cast /usr/local/bin/cast

# Copy your scripts and app files
COPY safe_hashes.sh .
COPY index.js .

# Make sure the bash script is executable
RUN chmod +x ./safe_hashes.sh

# Set the default shell to zsh
ENV SHELL=/usr/bin/zsh
SHELL ["/usr/bin/zsh", "-c"]

# Expose the port your Express app will run on
EXPOSE 3000

# Start the Express application
CMD ["node", "index.js"]
