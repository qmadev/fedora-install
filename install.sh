#!/bin/bash

set -eo pipefail

echo "[*] Checking operating system"

if ! grep -qi "fedora" /etc/os-release; then
    echo "[!] This script only supports Fedora."
    exit 1
fi

echo "[*] Updating system"
sudo dnf upgrade -y

echo "[*] Installing packages"
sudo dnf install -y \
    git \
    ripgrep \
    wget \
    curl \
    vim \
    tmux \
    wireshark \
    wireshark-cli \
    zsh \
    nmap \
    make \
    terminator \
    pypy3.11 \
    7zip

if ! command -v nvim; then
    echo "[*] Installing neovim"
    NVIM_URL=$(curl https://api.github.com/repos/neovim/neovim/releases/latest | jq -r '.assets | .[] | select(.name=="nvim-linux-x86_64.tar.gz") | .browser_download_url')
    mkdir -p "$HOME/Tools/nvim"
    wget -P "$HOME/Tools/nvim" "$NVIM_URL"
    tar -C "$HOME/Tools/nvim" -zxvf "$HOME/Tools/nvim/nvim-linux-x86_64.tar.gz"
    mkdir -p "$HOME/.local/bin"
    ln -s "$HOME/Tools/nvim/nvim-linux-x86_64/bin/nvim" "$HOME/.local/bin" 
fi

echo "[*] Installing Brave"
sudo dnf install dnf-plugins-core -y
sudo dnf config-manager addrepo -y --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo dnf install brave-browser -y

sudo usermod -aG wireshark "$USER"
echo "[+] Added current user to wireshark group"

if ! command -v rustup; then
    echo "[*] Installing Rust"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Load cargo environment
source "$HOME/.cargo/env"
rustup component add rust-analyzer-x86_64-unknown-linux-gnu

echo "[*] Installing Oh My Zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
if ! [[ -d "$HOME/.oh-my-zsh/custom/zsh-autosuggestions" ]]; then
    echo "[*] Downloading zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

echo "[*] Setting Oh My Zsh stuff"
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="clean"/' "$HOME/.zshrc"
sed -i 's/^plugins=(git)/plugins=(git zsh-autosuggestions)/' "$HOME/.zshrc"

if ! [[ -f "$HOME/.config/nvim/README.md" ]]; then
    echo "[*] Installing AstroNvim"
    git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
    rm -rf ~/.config/nvim/.git
fi

echo "[*] Setting astrocommunity stuff"
cat > "$HOME/.config/nvim/lua/community.lua" << 'EOF'
---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.rust" },
  { import = "astrocommunity.pack.python" },
}
EOF

sed -i 's/^if true then return {} end.*/-- if true then return {} end/' "$HOME/.config/nvim/lua/plugins/astrolsp.lua"
sed -i 's/enabled = true, -- enable or disable format on save globally/enabled = false, -- enable or disable format on save globally/' "$HOME/.config/nvim/lua/plugins/astrolsp.lua"

echo "[*] Setting up python and pipx"
sudo python3 -m ensurepip
sudo python3 -m pip install pipx
pipx ensurepath
pipx install pew

echo "[*] Installing Nerdfont"
mkdir "$HOME/Tools/Nerdfont"
wget -P "$HOME/Tools/Nerdfont" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/0xProto.zip"
mkdir -p  "$HOME/.fonts"
unzip "$HOME/Tools/Nerdfont/0xProto.zip" -d "$HOME/.fonts"
fc-cache -fv

echo 'export SHELL=$(which zsh)' >> ~/.zshrc
echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.zshrc

sudo chsh -s "$(which zsh)" "$USER"
gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'terminator.desktop', 'brave-browser.desktop']"
