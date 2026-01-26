#!/bin/bash

# ==============================================================================
# All-in-One Environment Setup Script (Ubuntu/CentOS/openEuler)
# Features:
#   - Adapts to A100/H100 (CUDA 12.5 check)
#   - Installs Zsh, Oh-My-Zsh, Plugins, Tmux, Clangd, UV, HF-CLI
#   - Smart Mirror Configuration (Tsinghua/HUST)
#   - Idempotent: Can be run multiple times; asks to update if installed.
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

    # 检查标志性软件是否已存在，如果存在则询问是否更新
    if [ -d "$USER_HOME/.oh-my-zsh" ] || command -v uv &> /dev/null; then
        echo ""
        log_warn "检测到环境中已安装部分软件 (Zsh/UV等)。"
        log_ask "是否要更新已安装的软件和插件？(输入 y 更新，输入其他键仅安装缺失项)"
        read -r -p "您的选择: " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            SHOULD_UPDATE=true
            log_info "已启用更新模式。将尝试更新系统包、插件和工具。"
        else
            SHOULD_UPDATE=false
            log_info "保持现有版本。脚本将仅安装缺失的组件 (幂等模式)。"
        fi
        echo ""
    fi
}

# --- 1. 配置系统镜像源 ---
configure_mirrors() {
    log_info "检查系统软件源配置..."
    
    # 无论是否更新，如果已经配置了国内源，为了保护用户自定义配置，通常不建议强制覆盖
    # 除非用户明确要求（这里保持“智能跳过”策略，因为换源风险较高）
    
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

# --- 2. 安装/更新 基础软件 (含 tmux) ---
install_basics() {
    local pkgs="git curl wget zsh tmux"
    
    # 根据系统不同追加包名
    if [[ "$OS_ID" == "ubuntu" ]]; then
        pkgs="$pkgs clangd openssh-client"
        if [ "$SHOULD_UPDATE" = true ]; then
            log_info "正在更新系统软件包 (apt upgrade)..."
            apt-get update && apt-get upgrade -y
        fi
        log_info "安装基础软件: $pkgs"
        apt-get install -y $pkgs

    else
        # RHEL/CentOS/openEuler
        pkgs="$pkgs clang" # clang 包通常包含 clangd
        if [ "$SHOULD_UPDATE" = true ]; then
            log_info "正在更新系统软件包 (dnf update)..."
            dnf update -y
        fi
        log_info "安装基础软件: $pkgs"
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
        # 即使更新模式，通常也不重置 SSH Key，防止断连
        log_info "SSH Key (Ed25519) 已存在，跳过生成。"
    else
        log_info "正在为用户 $CURRENT_USER 生成 Ed25519 密钥..."
        sudo -u "$CURRENT_USER" ssh-keygen -t ed25519 -C "$CURRENT_USER@$(hostname)" -f "$key_file" -N "" -q
        log_info "密钥生成成功。公钥："
        cat "$key_file.pub"
    fi
}

# --- 4. 配置 Oh-My-Zsh 及插件 (支持更新) ---
install_ohmyzsh() {
    log_info "检查 Oh-My-Zsh 配置..."

    # 1. 安装 OMZ
    if [ -d "$USER_HOME/.oh-my-zsh" ]; then
        if [ "$SHOULD_UPDATE" = true ]; then
            log_info "更新 Oh-My-Zsh 核心..."
            # 以用户身份执行 git pull
            sudo -u "$CURRENT_USER" git -C "$USER_HOME/.oh-my-zsh" pull || log_warn "OMZ 更新失败，跳过"
        else
            log_info "Oh-My-Zsh 已安装，跳过。"
        fi
    else
        log_info "Clone Oh-My-Zsh (Tsinghua Mirror)..."
        sudo -u "$CURRENT_USER" git clone https://mirrors.tuna.tsinghua.edu.cn/git/ohmyzsh.git "$USER_HOME/.oh-my-zsh"
        if [ ! -f "$USER_HOME/.zshrc" ]; then
            sudo -u "$CURRENT_USER" cp "$USER_HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$USER_HOME/.zshrc"
        fi
    fi

    # 确保 shell 切换
    if [[ "$SHELL" != */zsh ]]; then
        usermod -s $(which zsh) $CURRENT_USER
        log_info "默认 Shell 已修改为 Zsh"
    fi

    # 2. 安装/更新 插件
    ZSH_CUSTOM="$USER_HOME/.oh-my-zsh/custom"
    PLUGIN_DIR="$ZSH_CUSTOM/plugins"
    
    install_or_update_plugin() {
        local name=$1
        local repo=$2
        local target="$PLUGIN_DIR/$name"
        
        if [ -d "$target" ]; then
            if [ "$SHOULD_UPDATE" = true ]; then
                log_info "更新插件 $name..."
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

    # 3. 修改 .zshrc (幂等：每次都强制确保 plugins 行正确)
    log_info "配置 .zshrc 插件列表..."
    sed -i 's/^plugins=(.*)/plugins=(git z zsh-autosuggestions zsh-syntax-highlighting zsh-autocomplete)/' "$USER_HOME/.zshrc"
}

# --- 5. 安装/更新 UV ---
install_uv() {
    log_info "检查 uv (Python 包管理器)..."
    if command -v uv &> /dev/null; then
        if [ "$SHOULD_UPDATE" = true ]; then
            log_info "更新 uv..."
            uv self update || log_warn "uv self update 失败，可能需要 root 或非安装方式"
        else
            log_info "uv 已安装，跳过。"
        fi
    else
        # 安装到全局路径
        curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/bin" sh
    fi
}

# --- 6. 安装/更新 HuggingFace CLI ---
install_hf_cli() {
    log_info "检查 HuggingFace CLI..."
    local zshrc="$USER_HOME/.zshrc"

    # 1. 安装/更新 CLI
    if sudo -u "$CURRENT_USER" uv tool list | grep -q "huggingface-hub"; then
        if [ "$SHOULD_UPDATE" = true ]; then
            log_info "升级 huggingface-hub..."
            sudo -u "$CURRENT_USER" uv tool upgrade huggingface_hub
        else
            log_info "huggingface-hub 已安装，跳过。"
        fi
    else
        log_info "安装 huggingface-hub..."
        sudo -u "$CURRENT_USER" uv tool install huggingface_hub
    fi

    # 2. 幂等配置 PATH
    if ! grep -q "export PATH=\$HOME/.local/bin:\$PATH" "$zshrc"; then
        echo '' >> "$zshrc"
        echo '# User Local Bin (for uv tools)' >> "$zshrc"
        echo 'export PATH=$HOME/.local/bin:$PATH' >> "$zshrc"
    fi

    # 3. 幂等配置 镜像
    if ! grep -q "HF_ENDPOINT" "$zshrc"; then
        echo '' >> "$zshrc"
        echo '# Hugging Face Mirror' >> "$zshrc"
        echo 'export HF_ENDPOINT=https://hf-mirror.com' >> "$zshrc"
    fi
}

# --- 7. 安装 NVIDIA Toolkit (保守策略) ---
install_nvidia_toolkit() {
    log_info "检查 NVIDIA 环境..."
    
    if ! command -v nvidia-smi &> /dev/null; then
        log_err "未检测到 NVIDIA 驱动。跳过 Toolkit 安装。"
        return
    fi

    # 检查 nvcc 是否已存在
    if command -v nvcc &> /dev/null; then
        log_info "检测到已安装 CUDA Toolkit (`nvcc --version` 检测通过)。"
        # 即使在更新模式，也不建议自动覆盖 CUDA 版本，容易导致环境崩溃
        log_warn "为保证环境稳定性，脚本不会自动覆盖或升级现有的 CUDA Toolkit。"
        return
    fi

    DRIVER_VER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1)
    DRIVER_MAJOR=$(echo $DRIVER_VER | cut -d. -f1)
    
    if [ "$DRIVER_MAJOR" -lt 555 ]; then
        log_warn "驱动版本 $DRIVER_VER 低于 555，不支持 CUDA 12.5。跳过安装。"
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
    
    # 环境变量 (幂等添加)
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
log_info "所有任务执行完毕。"
log_info "请执行 'source ~/.zshrc' 或重新登录以应用更改。"
log_info "========================================================"
