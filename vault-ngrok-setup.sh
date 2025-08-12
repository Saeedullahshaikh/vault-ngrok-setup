#!/usr/bin/env bash
set -euo pipefail

# vault-ngrok-setup.sh
# Description: Install Vault (dev mode) and ngrok in Google Cloud Shell,
# Usage:
# Without ngrok: ./vault-ngrok-setup.sh
# With ngrok token in env: NGROK_AUTHTOKEN=yourtoken ./vault-ngrok-setup.sh

WORKDIR="$HOME/vault-ngrok-demo"
VAULT_ROOT_TOKEN="${VAULT_ROOT_TOKEN:-root}"
NGROK_AUTHTOKEN="${NGROK_AUTHTOKEN:-}"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

info(){ printf "[INFO] %s\n" "$*"; }
error(){ printf "[ERROR] %s\n" "$*" >&2; }

install_packages(){
  info "Updating apt and installing required packages (wget, unzip, curl)."
  sudo apt update -y
  sudo apt install -y wget unzip curl || sudo apt install -y wget unzip
}

_get_latest_vault(){
  # try jq parsing, fallback to grep/cut
  if command -v jq >/dev/null 2>&1; then
    curl -s https://api.github.com/repos/hashicorp/vault/releases/latest | jq -r .tag_name | sed 's/^v//'
  else
    curl -s https://api.github.com/repos/hashicorp/vault/releases/latest | grep '"tag_name"' | head -n1 | cut -d '"' -f4 | sed 's/^v//'
  fi
}

install_vault(){
  if command -v vault >/dev/null 2>&1; then
    info "vault already installed at $(command -v vault)"
    vault version || true
    return
  fi

  info "Detecting latest Vault version..."
  VAULT_VER=$(_get_latest_vault)
  info "Latest Vault: ${VAULT_VER}"

  ZIP="/tmp/vault_${VAULT_VER}_linux_amd64.zip"
  URL="https://releases.hashicorp.com/vault/${VAULT_VER}/vault_${VAULT_VER}_linux_amd64.zip"

  info "Downloading Vault ${VAULT_VER}..."
  wget -q --show-progress "$URL" -O "$ZIP"
  info "Unpacking Vault..."
  unzip -o "$ZIP" -d /tmp
  sudo mv -f /tmp/vault /usr/local/bin/
  sudo chmod +x /usr/local/bin/vault
  info "Vault installed: $(vault version)"
}

install_ngrok(){
  if command -v ngrok >/dev/null 2>&1; then
    info "ngrok already installed at $(command -v ngrok)"
    ngrok version || true
    return
  fi

  info "Downloading ngrok..."
  NG_ZIP="/tmp/ngrok.zip"
  wget -q --show-progress https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-stable-linux-amd64.zip -O "$NG_ZIP"
  unzip -o "$NG_ZIP" -d /tmp
  sudo mv -f /tmp/ngrok /usr/local/bin/
  sudo chmod +x /usr/local/bin/ngrok
  info "ngrok installed: $(ngrok version)"
}

start_vault(){
  info "Starting Vault dev server (background). Logs: $WORKDIR/vault.log"
  nohup vault server -dev -dev-root-token-id="$VAULT_ROOT_TOKEN" -dev-listen-address="0.0.0.0:8200" > "$WORKDIR/vault.log" 2>&1 &
  echo $! > "$WORKDIR/vault.pid"
  sleep 2
  tail -n 30 "$WORKDIR/vault.log" || true
  info "Vault started (dev). Root token: $VAULT_ROOT_TOKEN"
  info "Vault UI (when reachable): http://<cloud-shell-preview>/ui  or use ngrok public URL /ui"
}

start_ngrok_if_token(){
  if [ -z "${NGROK_AUTHTOKEN}" ]; then
    info "NGROK_AUTHTOKEN not provided. The script will NOT start ngrok automatically."
    info "To expose Vault publicly, run in a NEW Cloud Shell tab: ngrok http 8200"
    return
  fi

  info "Configuring ngrok auth token..."
  ngrok config add-authtoken "$NGROK_AUTHTOKEN" || true

  info "Starting ngrok tunnel in background. Logs: $WORKDIR/ngrok.log"
  nohup ngrok http 8200 > "$WORKDIR/ngrok.log" 2>&1 &
  echo $! > "$WORKDIR/ngrok.pid"
  sleep 3

  # try to get the public URL from ngrok's local API
  if command -v curl >/dev/null 2>&1; then
    sleep 1
    if command -v jq >/dev/null 2>&1; then
      public_url=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[0].public_url') || true
    else
      public_url=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -oE 'https://[a-zA-Z0-9._-]+' | head -n1) || true
    fi
  fi

  if [ -n "${public_url:-}" ]; then
    info "ngrok tunnel created: ${public_url}"
    info "Open ${public_url}/ui and login with token: $VAULT_ROOT_TOKEN"
  else
    info "ngrok started but could not read public URL from local API. Check $WORKDIR/ngrok.log"
    info "You can run: tail -f $WORKDIR/ngrok.log"
  fi
}

print_summary(){
  echo
  info "==== SUMMARY ===="
  info "Vault dev mode root token: $VAULT_ROOT_TOKEN"
  info "Vault is listening on: 0.0.0.0:8200 (inside Cloud Shell)"
  if [ -f "$WORKDIR/ngrok.pid" ]; then
    info "ngrok started (check $WORKDIR/ngrok.log)"
  else
    info "ngrok not started. To start manually in another Cloud Shell tab run: ngrok http 8200"
  fi
  info "To stop: pkill -f 'vault server' || true; pkill -f ngrok || true"
  echo
}

# Run steps

install_packages
install_vault
install_ngrok
start_vault
start_ngrok_if_token
print_summary


