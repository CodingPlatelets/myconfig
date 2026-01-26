#!/bin/bash

# ==============================================================================
# All-in-One Environment Setup Script (uv.toml Fixed)
# Support: Ubuntu(x86), CentOS 8+(x86), openEuler 23(ARM)
# Features:
#   - UV Config: Uses ~/.config/uv/uv.toml (Best Practice)
#   - CUDA: Interactive .run file (Safety First)
#   - Mirrors: Tsinghua (Ubuntu) / HUST (RPM)
#   - Tools: Zsh, OMZ, Plugins, Tmux, Clangd, UV, HF-CLI, Ed25519 Key
# ==============================================================================

set -e

# --- 用户配置区 ---
CUDA_VERSION_MAJOR="12.6.3"
CUDA_DRIVER_SUFFIX="560.35.05" 

# --- 全局变量 ---
CURRENT_USER=${SUDO_USER:-$(whoami)}
USER_HOME=$(eval echo ~$CURRENT_USER)
ARCH=$(uname -m)
OS_ID=""
OS_VERSION=""
SHOULD_UPDATE=false

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO] $1${NC}"; }
log_warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
log_err() { echo -e "${RED}[ERROR] $1${NC}"; }
log_ask()  { echo -e "${CYAN}[QUESTION] $1${NC}"; }

# --- 0. 初始化检查 ---
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
    
    if [ -d "$USER_HOME/.oh-my-zsh" ] || command -v uv &> /dev/null; then
        echo ""
        log_warn "检测到部分软件已安装。"
        log_ask "是否更新 [Oh-My-Zsh, 插件, UV, HF-CLI]? (不会更新系统软件)"
        log_ask "输入 'y' 更新，输入其他键仅安装缺失项 (推荐):"
        read -r -p "您的选择: " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            SHOULD_UPDATE=true
            log_info ">> 已启用组件更新模式。"
        else
            SHOULD_UPDATE=false
            log_info ">> 保持现有版本 (幂等模式)。"
        fi
        echo ""
    fi
}

# --- 1. 配置系统镜像源 ---
configure_mirrors() {
    log_info "检查系统软件源配置..."
    
    if [[ "$OS_ID" == "ubuntu" ]]; then
        if grep -qE "(\.cn|edu\.cn)" /etc/apt/sources.list; then
            log_info "系统源已包含国内镜像，跳过修改。"
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

# --- 2. 安装基础软件 ---
install_basics() {
    local pkgs="git curl wget zsh tmux"
    
    if [[ "$OS_ID" == "ubuntu" ]]; then
        pkgs="$pkgs clangd openssh-client"
        log_info "检查基础软件: $pkgs"
        apt-get install -y --no-upgrade $pkgs 2>/dev/null || apt-get install -y $pkgs
    else
        pkgs="$pkgs clang"
        log_info "检查基础软件: $pkgs"
        dnf install -y $pkgs
    fi
}

# --- 3. 生成 SSH 密钥 ---
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
        cat "$key_file.pub"
    fi
}

# --- 4. 配置 Oh-My-Zsh ---
install_ohmyzsh() {
    log_info "配置 Oh-My-Zsh..."
    if [ -d "$USER_HOME/.oh-my-zsh" ]; then
        if [ "$SHOULD_UPDATE" = true ]; then
            log_info "更新 Oh-My-Zsh..."
            sudo -u "$CURRENT_USER" git -C "$USER_HOME/.oh-my-zsh" pull || true
        fi
    else
        log_info "Clone OMZ..."
        sudo -u "$CURRENT_USER" git clone https://mirrors.tuna.tsinghua.edu.cn/git/ohmyzsh.git "$USER_HOME/.oh-my-zsh"
        if [ ! -f "$USER_HOME/.zshrc" ]; then
            sudo -u "$CURRENT_USER" cp "$USER_HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$USER_HOME/.zshrc"
        fi
    fi

    if [[ "$SHELL" != */zsh ]]; then
        usermod -s $(which zsh) $CURRENT_USER
    fi

    ZSH_CUSTOM="$USER_HOME/.oh-my-zsh/custom"
    PLUGIN_DIR="$ZSH_CUSTOM/plugins"
    
    install_plugin() {
        local name=$1
        local repo=$2
        local target="$PLUGIN_DIR/$name"
        if [ -d "$target" ]; then
            if [ "$SHOULD_UPDATE" = true ]; then
                sudo -u "$CURRENT_USER" git -C "$target" pull || true
            fi
        else
            log_info "安装插件: $name..."
            sudo -u "$CURRENT_USER" git clone $repo "$target"
        fi
    }

    install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
    install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
    install_plugin "zsh-autocomplete" "https://github.com/marlonrichert/zsh-autocomplete.git"

    sed -i 's/^plugins=(.*)/plugins=(git z zsh-autosuggestions zsh-syntax-highlighting zsh-autocomplete)/' "$USER_HOME/.zshrc"
}

# --- 5. 安装并配置 UV (使用 uv.toml) ---
install_uv() {
    log_info "检查 uv..."
    
    # 1. 安装或更新 uv
    if command -v uv &> /dev/null; then
        if [ "$SHOULD_UPDATE" = true ]; then
             uv self update || true
        fi
    else
        curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/bin" sh
    fi

    # 2. 配置 uv.toml (根据您的图片要求)
    local config_dir="$USER_HOME/.config/uv"
    local config_file="$config_dir/uv.toml"
    local mirror_url=""
    
    # 区分镜像源
    if [[ "$OS_ID" == "ubuntu" ]]; then
        mirror_url="https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple/"
    else
        mirror_url="https://mirrors.hust.edu.cn/pypi/web/simple/"
    fi

    # 创建目录
    if [ ! -d "$config_dir" ]; then
        log_info "创建配置目录: $config_dir"
        mkdir -p "$config_dir"
        chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config" "$config_dir"
    fi

    # 写入配置文件 (覆盖或新建)
    # 如果是更新模式，或者文件不存在，则写入
    if [ ! -f "$config_file" ] || [ "$SHOULD_UPDATE" = true ]; then
        log_info "写入 uv.toml 配置 ($mirror_url)..."
        cat > "$config_file" <<EOF
[[index]]
url = "$mirror_url"
default = true
EOF
        # 修正权限，确保用户可读写
        chown "$CURRENT_USER:$CURRENT_USER" "$config_file"
    else
        log_info "uv.toml 已存在，跳过修改。"
    fi
}

# --- 6. 安装 HuggingFace CLI ---
install_hf_cli() {
    log_info "检查 HuggingFace CLI..."
    local zshrc="$USER_HOME/.zshrc"

    # 1. 配置 HF 镜像环境变量
    if ! grep -q "HF_ENDPOINT" "$zshrc"; then
        echo '' >> "$zshrc"
        echo '# Hugging Face Mirror' >> "$zshrc"
        echo 'export HF_ENDPOINT=https://hf-mirror.com' >> "$zshrc"
    fi
    
    # 2. 安装/更新 CLI
    # 由于已经有了 uv.toml，uv 命令会自动读取镜像，不需要再传环境变量
    if sudo -u "$CURRENT_USER" uv tool list | grep -q "huggingface-hub"; then
        if [ "$SHOULD_UPDATE" = true ]; then
            log_info "升级 huggingface-hub..."
            sudo -u "$CURRENT_USER" uv tool upgrade huggingface_hub
        fi
    else
        log_info "安装 huggingface-hub..."
        sudo -u "$CURRENT_USER" uv tool install huggingface_hub
    fi

    # 3. 配置 PATH
    if ! grep -q "export PATH=\$HOME/.local/bin:\$PATH" "$zshrc"; then
        echo '' >> "$zshrc"
        echo '# User Local Bin (for uv tools)' >> "$zshrc"
        echo 'export PATH=$HOME/.local/bin:$PATH' >> "$zshrc"
    fi
}

# --- 7. 安装 NVIDIA Toolkit (交互模式) ---
install_nvidia_toolkit() {
    log_info "检查 NVIDIA 环境..."
    
    if ! command -v nvidia-smi &> /dev/null; then
        log_err "未检测到 NVIDIA 驱动。跳过 Toolkit 安装。"
        return
    fi

    if command -v nvcc &> /dev/null; then
        log_info "nvcc 已存在 ($(nvcc --version | grep release | awk '{print $5,$6}'))。跳过安装。"
        return
    fi
    if [ -d "/usr/local/cuda" ]; then
        log_info "/usr/local/cuda 目录已存在，跳过安装以防止覆盖。"
        return
    fi

    DRIVER_VER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1)
    DRIVER_MAJOR=$(echo $DRIVER_VER | cut -d. -f1)
    
    if [ "$DRIVER_MAJOR" -lt 555 ]; then
        log_warn "当前驱动版本 $DRIVER_VER 低于 555，可能不支持 CUDA 12.6+。"
        log_ask "是否仍要继续下载并尝试安装？(y/n)"
        read -r -p "您的选择: " cont_choice
        if [[ ! "$cont_choice" =~ ^[Yy]$ ]]; then
            return
        fi
    fi

    log_info "准备下载 CUDA Toolkit ${CUDA_VERSION_MAJOR} (.run file)..."
    
    local BASE_URL="https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION_MAJOR}/local_installers"
    local INSTALLER_FILE=""

    if [[ "$ARCH" == "aarch64" ]]; then
        INSTALLER_FILE="cuda_${CUDA_VERSION_MAJOR}_${CUDA_DRIVER_SUFFIX}_linux_sbsa.run"
    else
        INSTALLER_FILE="cuda_${CUDA_VERSION_MAJOR}_${CUDA_DRIVER_SUFFIX}_linux.run"
    fi

    local DOWNLOAD_URL="${BASE_URL}/${INSTALLER_FILE}"

    log_info "正在下载: $INSTALLER_FILE"
    if [ ! -f "$INSTALLER_FILE" ]; then
        wget -c "$DOWNLOAD_URL" -O "$INSTALLER_FILE"
    else
        log_info "安装包已存在，跳过下载。"
    fi

    log_warn "=================================================================="
    log_warn " !!! 即将启动 NVIDIA 交互式安装界面 !!! "
    log_warn " 1. [关键] 取消勾选 Driver (显卡驱动)！！！"
    log_warn " 2. 勾选 CUDA Toolkit 12.x"
    log_warn "=================================================================="
    log_ask "按回车键开始安装..."
    read -r

    sh "$INSTALLER_FILE" --override

    if [ -d "/usr/local/cuda" ]; then
        log_info "配置 CUDA 环境变量..."
        local zshrc="$USER_HOME/.zshrc"
        if ! grep -q "export PATH=/usr/local/cuda/bin" "$zshrc"; then
            echo '' >> "$zshrc"
            echo '# CUDA Paths' >> "$zshrc"
            echo 'export PATH=/usr/local/cuda/bin:$PATH' >> "$zshrc"
            echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> "$zshrc"
        fi
    else
        log_warn "未检测到 /usr/local/cuda 目录。"
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
log_info "配置流程结束。"
log_info "请手动执行 'source ~/.zshrc' 使环境变量生效。"
log_info "========================================================"
