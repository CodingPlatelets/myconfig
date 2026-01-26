#!/bin/bash

# ==============================================================================
# All-in-One Environment Setup Script (Refined Update Logic)
# Support: Ubuntu(x86), CentOS 8+(x86), openEuler 23(ARM)
# Features:
#   - Safety: NO global system upgrades (apt upgrade/dnf update removed).
#   - Scope: "Update Mode" only updates Zsh/Plugins/UV/HF-CLI.
#   - Adapts to A100/H100 (CUDA 12.5 check)
#   - Installs: Zsh, OMZ, Plugins, Tmux, Clangd, UV, HF-CLI, Ed25519 Key
# ==============================================================================

set -e

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- 全局变量 ---
CURRENT_USER=${SUDO_USER:-$(whoami)}
USER_HOME=$(eval echo ~$CURRENT_USER)
ARCH=$(uname -m)
OS_ID=""
OS_VERSION=""
CUDA_VERSION_REQ="12-5"
SHOULD_UPDATE=false

log_info() { echo -e "${GREEN}[INFO] $1${NC}"; }
log_warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
log_err() { echo -e "${RED}[ERROR] $1${NC}"; }
log_ask()  { echo -e "${CYAN}[QUESTION] $1${NC}"; }

# --- 0. 初始化检查与更新询问 ---
init_check() {
    if [[ "$EUID" -ne 0 ]]; then
        log_err "请使用 root 权限或 sudo 运行此脚本。"
        exit 1
    fi

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID=$ID
        OS_VERSION=$VERSION_ID
    else
        log_err "无法检测操作系统版本。"
        exit 1
    fi
    
    log_info "Detected OS: $OS_ID $OS_VERSION ($ARCH)"
    log_info "Target User: $CURRENT_USER"

    # 检查标志性软件是否已存在
    if [ -d "$USER_HOME/.oh-my-zsh" ] || command -v uv &> /dev/null; then
        echo ""
        log_warn "检测到部分软件已安装。"
        log_ask "是否更新 [Oh-My-Zsh, 插件, UV, HF-CLI]? (不会更新系统软件如 git/gcc)"
        log_ask "输入 'y' 更新上述特定组件，输入其他键仅安装缺失项 (推荐):"
        read -r -p "您的选择: " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            SHOULD_UPDATE=true
            log_info ">> 已启用组件更新模式 (仅更新 Zsh插件/UV/HF)。"
        else
            SHOULD_UPDATE=false
            log_info ">> 保持现有版本。脚本将仅安装缺失的组件 (幂等模式)。"
        fi
        echo ""
    fi
}

# --- 1. 配置系统镜像源 ---
configure_mirrors() {
    log_info "检查系统软件源配置..."
    
    # 保护机制：如果已存在国内源，绝对不修改
    if [[ "$OS_ID" == "ubuntu" ]]; then
        if grep -qE "(\.cn|edu\.cn)" /etc/apt/sources.list; then
            log_info "系统源已包含国内镜像(.cn/edu.cn)，跳过修改。"
        else
            log_info "配置 Ubuntu 清华源..."
            cp /etc/apt/sources.list /etc/apt/sources.list.bak
            sed -i 's@^\(deb.*\)http://.*ubuntu.com/ubuntu/@\1https://mirrors.tuna.tsinghua.edu.cn/ubuntu/@g' /etc/apt/sources.list
            sed -i 's@^\(deb.*\)http://.*ubuntu.com/ubuntu@\1https://mirrors.tuna.tsinghua.edu.cn/ubuntu@g' /etc/apt/sources.list
            apt-get update
        fi
        
    elif [[ "$OS_ID" == "centos" || "$OS_ID" == "rocky" || "$OS_ID" == "almalinux" ]]; then
        if grep -rE "(\.cn|edu\.cn)" /etc/yum.repos.d/ &> /dev/null; then
            log_info "系统源已包含国内镜像，跳过修改。"
        else
            log_info "配置 CentOS Stream HUST 源..."
            sed -e 's|^mirrorlist=|#mirrorlist=|g' \
                -e 's|^#baseurl=http://mirror.centos.org/$contentdir|baseurl=https://mirrors.hust.edu.cn/centos-stream|g' \
                -i.bak /etc/yum.repos.d/CentOS-*.repo 2>/dev/null || true
            dnf makecache
        fi

    elif [[ "$OS_ID" == "openEuler" ]]; then
        if grep -rE "(\.cn|edu\.cn)" /etc/yum.repos.d/ &> /dev/null; then
            log_info "系统源已包含国内镜像，跳过修改。"
        else
            log_info "配置 openEuler HUST 源..."
            cp /etc/yum.repos.d/openEuler.repo /etc/yum.repos.d/openEuler.repo.bak 2>/dev/null || true
            sed -i 's@repo.openeuler.org@mirrors.hust.edu.cn/openeuler@g' /etc/yum.repos.d/openEuler.repo
            dnf makecache
        fi
    fi
}

# --- 2. 安装基础软件 (仅安装不升级) ---
install_basics() {
    local pkgs="git curl wget zsh tmux"
    
    if [[ "$OS_ID" == "ubuntu" ]]; then
        pkgs="$pkgs clangd openssh-client"
        log_info "检查基础软件: $pkgs"
        # 使用 --no-upgrade 确保不意外升级现有系统包
        apt-get install -y --no-upgrade $pkgs 2>/dev/null || apt-get install -y $pkgs

    else
        # RHEL/CentOS/openEuler
        pkgs="$pkgs clang"
        log_info "检查基础软件: $pkgs"
        # dnf install 默认如果已安装则跳过 (除非指定版本)
        dnf install -y $pkgs
    fi
}

# --- 3. 生成 SSH 密钥 (幂等) ---
generate_ssh_key() {
    local ssh_dir="$USER_HOME/.ssh"
    local key_file="$ssh_dir/id_ed25519"

    if [ ! -d "$ssh_dir" ]; then
        mkdir -p "$ssh_dir"
        chown "$CURRENT_USER:$CURRENT_USER" "$ssh_dir"
        chmod 700 "$ssh_dir"
    fi

    if [ -f "$key_file" ]; then
        log_info "SSH Key (Ed25519) 已存在，跳过生成。"
    else
        log_info "正在为用户 $CURRENT_USER 生成 Ed25519 密钥..."
        sudo -u "$CURRENT_USER" ssh-keygen -t ed25519 -C "$CURRENT_USER@$(hostname)" -f "$key_file" -N "" -q
        log_info "密钥生成成功。公钥："
        cat "$key_file.pub"
    fi
}

# --- 4. 配置 Oh-My-Zsh 及插件 (精细化更新) ---
install_ohmyzsh() {
    log_info "配置 Oh-My-Zsh 环境..."

    # 1. OMZ 核心
    if [ -d "$USER_HOME/.oh-my-zsh" ]; then
        if [ "$SHOULD_UPDATE" = true ]; then
            log_info "正在更新 Oh-My-Zsh (git pull)..."
            sudo -u "$CURRENT_USER" git -C "$USER_HOME/.oh-my-zsh" pull || log_warn "OMZ 更新失败，跳过"
        else
            log_info "Oh-My-Zsh 已存在，跳过。"
        fi
    else
        log_info "Clone Oh-My-Zsh (Tsinghua Mirror)..."
        sudo -u "$CURRENT_USER" git clone https://mirrors.tuna.tsinghua.edu.cn/git/ohmyzsh.git "$USER_HOME/.oh-my-zsh"
        if [ ! -f "$USER_HOME/.zshrc" ]; then
            sudo -u "$CURRENT_USER" cp "$USER_HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$USER_HOME/.zshrc"
        fi
    fi

    if [[ "$SHELL" != */zsh ]]; then
        usermod -s $(which zsh) $CURRENT_USER
        log_info "默认 Shell 已修改为 Zsh"
    fi

    # 2. 插件
    ZSH_CUSTOM="$USER_HOME/.oh-my-zsh/custom"
    PLUGIN_DIR="$ZSH_CUSTOM/plugins"
    
    install_or_update_plugin() {
        local name=$1
        local repo=$2
        local target="$PLUGIN_DIR/$name"
        
        if [ -d "$target" ]; then
            if [ "$SHOULD_UPDATE" = true ]; then
                log_info "正在更新插件 $name..."
                sudo -u "$CURRENT_USER" git -C "$target" pull || true
            else
                log_info "插件 $name 已存在，跳过。"
            fi
        else
            log_info "安装插件: $name..."
            sudo -u "$CURRENT_USER" git clone $repo "$target"
        fi
    }

    install_or_update_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
    install_or_update_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
    install_or_update_plugin "zsh-autocomplete" "https://github.com/marlonrichert/zsh-autocomplete.git"

    sed -i 's/^plugins=(.*)/plugins=(git z zsh-autosuggestions zsh-syntax-highlighting zsh-autocomplete)/' "$USER_HOME/.zshrc"
}

# --- 5. 安装/更新 UV (精细化更新) ---
install_uv() {
    log_info "检查 uv (Python 包管理器)..."
    if command -v uv &> /dev/null; then
        if [ "$SHOULD_UPDATE" = true ]; then
            log_info "正在更新 uv (self update)..."
            # 注意：如果之前是 root 安装的，普通用户可能无权 update，这里假设 script 用 sudo 运行
            uv self update || log_warn "uv self update 失败，可能需要手动更新"
        else
            log_info "uv 已安装，跳过。"
        fi
    else
        curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/bin" sh
    fi
}

# --- 6. 安装/更新 HuggingFace CLI (精细化更新) ---
install_hf_cli() {
    log_info "检查 HuggingFace CLI..."
    local zshrc="$USER_HOME/.zshrc"

    if sudo -u "$CURRENT_USER" uv tool list | grep -q "huggingface-hub"; then
        if [ "$SHOULD_UPDATE" = true ]; then
            log_info "正在更新 huggingface-hub..."
            sudo -u "$CURRENT_USER" uv tool upgrade huggingface_hub
        else
            log_info "huggingface-hub 已安装，跳过。"
        fi
    else
        log_info "安装 huggingface-hub..."
        sudo -u "$CURRENT_USER" uv tool install huggingface_hub
    fi

    # 配置 PATH (如果之前没配过)
    if ! grep -q "export PATH=\$HOME/.local/bin:\$PATH" "$zshrc"; then
        echo '' >> "$zshrc"
        echo '# User Local Bin (for uv tools)' >> "$zshrc"
        echo 'export PATH=$HOME/.local/bin:$PATH' >> "$zshrc"
    fi

    # 配置 镜像 (如果之前没配过)
    if ! grep -q "HF_ENDPOINT" "$zshrc"; then
        echo '' >> "$zshrc"
        echo '# Hugging Face Mirror' >> "$zshrc"
        echo 'export HF_ENDPOINT=https://hf-mirror.com' >> "$zshrc"
    fi
}

# --- 7. 安装 NVIDIA Toolkit (安全检查，永不自动升级) ---
install_nvidia_toolkit() {
    log_info "检查 NVIDIA 环境..."
    
    if ! command -v nvidia-smi &> /dev/null; then
        log_err "未检测到 NVIDIA 驱动。跳过 Toolkit 安装。"
        return
    fi

    # 如果 nvcc 存在，绝对不碰它，防止版本冲突
    if command -v nvcc &> /dev/null; then
        log_info "检测到已安装 CUDA Toolkit (`nvcc --version` 检测通过)。"
        log_info "为保证计算环境稳定，脚本将**跳过** CUDA 的任何安装或更新。"
        return
    fi

    DRIVER_VER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1)
    DRIVER_MAJOR=$(echo $DRIVER_VER | cut -d. -f1)
    
    if [ "$DRIVER_MAJOR" -lt 555 ]; then
        log_warn "驱动版本 $DRIVER_VER 低于 555，不支持 CUDA 12.5。跳过安装。"
        return
    fi

    log_info "正在安装 CUDA Toolkit $CUDA_VERSION_REQ..."
    
    # 安装过程...
    if [[ "$OS_ID" == "ubuntu" ]]; then
        wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${OS_VERSION//./}/x86_64/cuda-keyring_1.1-1_all.deb
        dpkg -i cuda-keyring_1.1-1_all.deb
        apt-get update
        apt-get install -y cuda-toolkit-${CUDA_VERSION_REQ}
    elif [[ "$OS_ID" == "centos" || "$OS_ID" == "openEuler" ]]; then
        local cuda_arch="x86_64"
        local repo_path="rhel9"
        if [[ "$OS_ID" == "openEuler" ]]; then repo_path="rhel9"; 
        elif [[ "$OS_VERSION" == "8" ]]; then repo_path="rhel8"; fi
        if [[ "$ARCH" == "aarch64" ]]; then cuda_arch="sbsa"; fi

        yum-config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/${repo_path}/${cuda_arch}/cuda-${repo_path}.repo
        yum install -y cuda-toolkit-${CUDA_VERSION_REQ}
    fi
    
    # 环境变量
    if [ -d "/usr/local/cuda" ]; then
        if ! grep -q "export PATH=/usr/local/cuda/bin" "$USER_HOME/.zshrc"; then
            echo '' >> "$USER_HOME/.zshrc"
            echo '# CUDA Paths' >> "$USER_HOME/.zshrc"
            echo 'export PATH=/usr/local/cuda/bin:$PATH' >> "$USER_HOME/.zshrc"
            echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> "$USER_HOME/.zshrc"
        fi
    fi
}

# --- 执行主流程 ---
init_check
configure_mirrors
install_basics
generate_ssh_key
install_ohmyzsh
install_uv
install_hf_cli
install_nvidia_toolkit

log_info "========================================================"
log_info "任务完成。"
log_info "请执行 'source ~/.zshrc' 生效环境变量。"
log_info "========================================================"
