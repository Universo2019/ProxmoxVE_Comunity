#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/michelroegl-brunner/ProxmoxVE/refs/heads/DEV/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://actualbudget.org/

# App Default Values
APP="Actual Budget"
var_tags="finance"
var_cpu="2"
var_ram="2048"
var_disk="4"
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
    if [[ ! -d /opt/actualbudget ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Stopping Service"
    systemctl stop actualbudget.service
    msg_ok "Stopped Service"

    
    if [[ "$(node -v | cut -d 'v' -f 2)" != "22."* ]]; then
        msg_info "Updating NodeJS"
        rm -f /etc/apt/sources.list.d/nodesource.list
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list

        apt-get update &>/dev/null
        apt-get install -y nodejs &>/dev/null
        
        if command -v npm >/dev/null 2>&1; then
            if [[ "$(npm -v)" != "11."* ]]; then
                echi "Updating npm"
                npm install -g npm@latest &>/dev/null
            fi
        fi

        if command -v pnpm >/dev/null 2>&1; then
            echi "Updating pnpm"
            if [[ "$(pnpm -v)" != "10."* ]]; then
                npm install --global pnpm &>/dev/null
            fi
        fi

        if command -v yarn >/dev/null 2>&1; then
            echi "Updating yarn"
            if [[ "$(yarn -v)" != "1.22"* ]]; then
                npm install --global yarn &>/dev/null
            fi
        fi
        msg_ok "NodeJS is already up to date"
    fi

    msg_info "Updating ${APP}"
    cd /opt/actualbudget
    git pull &>/dev/null
    yarn install &>/dev/null
    systemctl start actualbudget.service
    msg_ok "Successfully Updated ${APP}"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5006${CL}"
