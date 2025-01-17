#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/nodejs_22/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/nodejs_22/LICENSE
# Source: https://www.usememos.com/

# App Default Values
APP="Memos"
var_tags="notes"
var_cpu="2"
var_ram="2048"
var_disk="7"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/memos ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  
  if [[ "$(node -v | cut -d 'v' -f 2)" != "22."* ]]; then
        msg_info "Updating NodeJS"
        rm -f /etc/apt/sources.list.d/nodesource.list || true
        rm -f /etc/apt/keyrings/nodesource.gpg || true
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list

        apt-get update &>/dev/null
        apt-get install -y nodejs &>/dev/null
        msg_info "Updated NodeJS"
    fi

    if command -v npm >/dev/null 2>&1; then
        if [[ "$(npm -v)" != "11."* ]]; then
            echo "Updating npm"
            npm install -g npm@latest &>/dev/null
        fi
    fi
    if command -v pnpm >/dev/null 2>&1; then
        echo "Updating pnpm"
        if [[ "$(pnpm -v)" != "10."* ]]; then
            npm install --global pnpm &>/dev/null
        fi
    fi
    if command -v yarn >/dev/null 2>&1; then
        echo "Updating yarn"
        if [[ "$(yarn -v)" != "1.22"* ]]; then
            npm install --global yarn &>/dev/null
        fi
    fi


  msg_info "Updating $APP (Patience)"
  cd /opt/memos
  git reset --hard HEAD
  output=$(git pull --no-rebase)
  if echo "$output" | grep -q "Already up to date."; then
    msg_ok "$APP is already up to date."
    exit
  fi
  systemctl stop memos
  cd /opt/memos/web
  pnpm i --frozen-lockfile &>/dev/null
  pnpm build &>/dev/null
  cd /opt/memos
  mkdir -p /opt/memos/server/dist
  cp -r web/dist/* /opt/memos/server/dist/
  cp -r web/dist/* /opt/memos/server/router/frontend/dist/
  go build -o /opt/memos/memos -tags=embed bin/memos/main.go &>/dev/null
  systemctl start memos
  msg_ok "Updated $APP"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9030${CL}"
