#!/bin/bash

# ==============================================================================
# Environment Setup Script (A100/H100/ARM64)
# Features:
#   1. OS Detection: Ubuntu(x86), CentOS 8+(x86), openEuler 23(ARM)
#   2. Mirrors: Smart config (HUST/Tsinghua), skips if already set
#   3. Shell: Zsh + Oh-My-Zsh (Tsinghua Mirror) + 5 Plugins
#   4. Tools: git, clangd, uv, ssh-keygen(Ed25519)
#   5. AI Tools: NVIDIA Toolkit (Safety Check), HuggingFace CLI (Mirror)
# ==============================================================================

set -e

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- 全局变量 ---
CURRENT_USER=${SUDO_USER:-$(whoami)}
USER_HOME=$(eval echo ~$CURRENT_USER)
ARCH=$(uname -m)
OS_ID=""
OS_VERSION=""
CUDA_VERSION_REQ="12-5" # 对应 CUDA 12.5

log_info() { echo -e "${GREEN}[INFO] $1${NC}"; }
log_warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
log_err() { echo -e "${RED}[ERROR] $1${NC}"; }

# --- 1. 系统检测 ---
check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID=$ID
        OS_VERSION=$VERSION_ID
    else
        log_err "无法检测操作系统版本 (/etc/os-release missing)."
        exit 1
    fi

    log_info "Detected OS: $OS_ID $OS_VERSION ($ARCH)"
    log_info "Target User: $CURRENT_USER ($USER_HOME)"
    
    if [[ "$EUID" -ne 0 ]]; then
        log_err "请使用 root 权限或 sudo 运行此脚本。"
        exit 1
    fi
}

# --- 2. 配置系统镜像源 ---
configure_mirrors() {
    log_info "检查系统软件源配置..."
    
    # 智能跳过逻辑：如果已包含 .cn 或 edu.cn 则不修改
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
            log_info "系统源已包含国内镜像(.cn/edu.cn)，跳过修改。"
        else
            log_info "配置 CentOS Stream HUST 源..."
            sed -e 's|^mirrorlist=|#mirrorlist=|g' \
                -e 's|^#baseurl=http://mirror.centos.org/$contentdir|baseurl=https://mirrors.hust.edu.cn/centos-stream|g' \
                -i.bak /etc/yum.repos.d/CentOS-*.repo 2>/dev/null || true
            dnf makecache
        fi

    elif [[ "$OS_ID" == "openEuler" ]]; then
        if grep -rE "(\.cn|edu\.cn)" /etc/yum.repos.d/ &> /dev/null; then
            log_info "系统源已包含国内镜像(.cn/edu.cn)，跳过修改。"
        else
            log_info "配置 openEuler HUST 源..."
            cp /etc/yum.repos.d/openEuler.repo /etc/yum.repos.d/openEuler.repo.bak 2>/dev/null || true
            sed -i 's@repo.openeuler.org@mirrors.hust.edu.cn/openeuler@g' /etc/yum.repos.d/openEuler.repo
            dnf makecache
        fi
    fi
}

# --- 3. 安装基础软件 & Clangd ---
install_basics() {
    log_info "安装基础软件 (git, curl, zsh, clangd)..."
    if [[ "$OS_ID" == "ubuntu" ]]; then
        apt-get install -y git curl wget zsh clangd openssh-client
    else
        dnf install -y git curl wget zsh clang
    fi
}

# --- 4. 生成 SSH 密钥 (Ed25519) ---
generate_ssh_key() {
    local ssh_dir="$USER_HOME/.ssh"
    local key_file="$ssh_dir/id_ed25519"

    if [ ! -d "$ssh_dir" ]; then
        mkdir -p "$ssh_dir"
        chown "$CURRENT_USER:$CURRENT_USER" "$ssh_dir"
        chmod 700 "$ssh_dir"
    fi

    if [ -f "$key_file" ]; then
        log_warn "SSH Key (Ed25519) 已存在，跳过生成。"
    else
        log_info "正在为用户 $CURRENT_USER 生成 Ed25519 密钥..."
        sudo -u "$CURRENT_USER" ssh-keygen -t ed25519 -C "$CURRENT_USER@$(hostname)" -f "$key_file" -N "" -q
        log_info "密钥生成成功。公钥："
        cat "$key_file.pub"
    fi
}

# --- 5. 配置 Oh-My-Zsh ---
install_ohmyzsh() {
    log_info "配置 Oh-My-Zsh..."

    if [ -d "$USER_HOME/.oh-my-zsh" ]; then
        log_warn "Oh-My-Zsh 目录已存在，跳过 clone。"
    else
        sudo -u "$CURRENT_USER" git clone https://mirrors.tuna.tsinghua.edu.cn/git/ohmyzsh.git "$USER_HOME/.oh-my-zsh"
        if [ ! -f "$USER_HOME/.zshrc" ]; then
            sudo -u "$CURRENT_USER" cp "$USER_HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$USER_HOME/.zshrc"
        fi
    fi

    # 切换默认 Shell
    if [[ "$SHELL" != */zsh ]]; then
        usermod -s $(which zsh) $CURRENT_USER
        log_info "默认 Shell 已修改为 Zsh"
    fi

    # --- 安装插件 ---
    ZSH_CUSTOM="$USER_HOME/.oh-my-zsh/custom"
    PLUGIN_DIR="$ZSH_CUSTOM/plugins"
    
    install_plugin() {
        local name=$1
        local repo=$2
        if [ ! -d "$PLUGIN_DIR/$name" ]; then
            log_info "安装 Zsh 插件: $name..."
            sudo -u "$CURRENT_USER" git clone $repo "$PLUGIN_DIR/$name"
        fi
    }

    install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
    install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
    install_plugin "zsh-autocomplete" "https://github.com/marlonrichert/zsh-autocomplete.git"

    # --- 修改 .zshrc ---
    local zshrc="$USER_HOME/.zshrc"
    sed -i 's/^plugins=(.*)/plugins=(git z zsh-autosuggestions zsh-syntax-highlighting zsh-autocomplete)/' "$zshrc"
}

# --- 6. 安装 UV ---
install_uv() {
    log_info "安装 uv (Python 包管理器)..."
    if ! command -v uv &> /dev/null; then
        # 安装到全局路径
        curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/bin" sh
    else
        log_info "uv 已安装。"
    fi
}

# --- 7. 安装 HuggingFace CLI (新增) ---
install_hf_cli() {
    log_info "使用 uv 安装 HuggingFace CLI 并配置镜像..."
    local zshrc="$USER_HOME/.zshrc"

    # 1. 使用 uv tool 安装 huggingface_hub
    # 注意：uv tool 默认安装到 ~/.local/bin，需要以目标用户身份运行
    if ! sudo -u "$CURRENT_USER" uv tool list | grep -q "huggingface-hub"; then
        sudo -u "$CURRENT_USER" uv tool install huggingface_hub
        log_info "HuggingFace CLI 安装完成。"
    else
        log_info "HuggingFace CLI 已安装。"
    fi

    # 2. 确保 ~/.local/bin 在 PATH 中 (uv tool 的安装路径)
    if ! grep -q "export PATH=\$HOME/.local/bin:\$PATH" "$zshrc"; then
        echo '' >> "$zshrc"
        echo '# User Local Bin (for uv tools)' >> "$zshrc"
        echo 'export PATH=$HOME/.local/bin:$PATH' >> "$zshrc"
    fi

    # 3. 配置 HF_ENDPOINT 镜像
    if ! grep -q "HF_ENDPOINT" "$zshrc"; then
        echo '' >> "$zshrc"
        echo '# Hugging Face Mirror' >> "$zshrc"
        echo 'export HF_ENDPOINT=https://hf-mirror.com' >> "$zshrc"
        log_info "已配置 HF_ENDPOINT 为 hf-mirror.com"
    fi
}

# --- 8. 安装 NVIDIA Toolkit ---
install_nvidia_toolkit() {
    log_info "检查 NVIDIA 环境..."
    
    if ! command -v nvidia-smi &> /dev/null; then
        log_err "未检测到 NVIDIA 驱动。跳过 Toolkit 安装。"
        return
    fi

    DRIVER_VER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1)
    DRIVER_MAJOR=$(echo $DRIVER_VER | cut -d. -f1)
    
    if [ "$DRIVER_MAJOR" -lt 555 ]; then
        log_warn "驱动版本 $DRIVER_VER 低于 555，不支持 CUDA 12.5。跳过安装。"
        return
    fi

    if command -v nvcc &> /dev/null; then
        log_info "检测到已安装 nvcc，跳过安装。"
        return
    fi

    log_info "正在安装 CUDA Toolkit $CUDA_VERSION_REQ..."
    
    # 架构与Repo选择
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
check_os
configure_mirrors
install_basics
generate_ssh_key
install_ohmyzsh
install_uv
install_hf_cli      # 新增步骤
install_nvidia_toolkit

log_info "========================================================"
log_info "配置完成！请执行 'source ~/.zshrc' 生效环境变量。"
log_info "HuggingFace 测试: source ~/.zshrc && huggingface-cli env"
log_info "========================================================"
