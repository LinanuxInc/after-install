#!/bin/bash

################################################################################
# ULTIMATE UBUNTU AFTER INSTALL SETUP SCRIPT
# ============================================================================
# Author: LinanuxInc Combined Repository Setup
# Version: 1.0
# Description: Ultimate master setup script combining all LinanuxInc 
#              after-install repositories for comprehensive Ubuntu setup
# 
# Usage: sudo bash ubuntu-ultimate-setup.sh
#
# This script includes:
# - System updates and upgrades
# - Essential libraries and codecs
# - Development tools
# - System utilities and optimization
# - Security tools
# - Desktop environment customization
# - Package managers and build tools
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/ubuntu-setup-$(date +%Y%m%d_%H%M%S).log"
DEBUG_MODE=${1:-""}
AUTO_MODE=false
VERBOSE_MODE=true

################################################################################
# UTILITY FUNCTIONS
################################################################################

log_message() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        INFO)
            echo -e "${BLUE}[INFO]${NC} ${message}" | tee -a "$LOG_FILE"
            ;;
        SUCCESS)
            echo -e "${GREEN}[✓]${NC} ${message}" | tee -a "$LOG_FILE"
            ;;
        WARNING)
            echo -e "${YELLOW}[WARNING]${NC} ${message}" | tee -a "$LOG_FILE"
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} ${message}" | tee -a "$LOG_FILE"
            ;;
    esac
}

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo -e "\n${BLUE}▶▶▶${NC} $1"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_message ERROR "This script must be run as root"
        echo "Please run with: sudo bash $0"
        exit 1
    fi
}

ask_permission() {
    local prompt="$1"
    local default="${2:-y}"
    local response
    
    if [ "$AUTO_MODE" = true ]; then
        log_message INFO "$prompt (auto-accepting)"
        return 0
    fi
    
    while true; do
        if [ "$default" = "y" ]; then
            read -p "$(echo -e ${YELLOW}$prompt${NC}) [Y/n] " -n 1 -r response
        else
            read -p "$(echo -e ${YELLOW}$prompt${NC}) [y/N] " -n 1 -r response
        fi
        echo ""
        
        case "$response" in
            [Yy])
                return 0
                ;;
            [Nn])
                return 1
                ;;
            "")
                if [ "$default" = "y" ]; then
                    return 0
                else
                    return 1
                fi
                ;;
            *)
                echo "Please answer y or n"
                ;;
        esac
    done
}

run_command() {
    local description="$1"
    local command="$2"
    
    log_message INFO "Running: $description"
    
    if [ -n "$DEBUG_MODE" ]; then
        eval "$command"
    else
        if eval "$command" >> "$LOG_FILE" 2>&1; then
            log_message SUCCESS "$description completed"
            return 0
        else
            log_message ERROR "$description failed (check log: $LOG_FILE)"
            return 1
        fi
    fi
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

################################################################################
# CORE SETUP FUNCTIONS
################################################################################

initial_setup() {
    print_header "INITIAL SYSTEM SETUP"
    
    log_message INFO "Creating log file: $LOG_FILE"
    touch "$LOG_FILE"
    
    ask_permission "Enable automatic mode (skip all prompts)?" "n" && AUTO_MODE=true
    
    if [ "$AUTO_MODE" = true ]; then
        log_message WARNING "Running in AUTO MODE - will install all components"
    fi
}

update_system() {
    print_section "System Update & Upgrade"
    
    if ! ask_permission "Update and upgrade system packages?"; then
        log_message WARNING "Skipping system update"
        return
    fi
    
    run_command "Update package lists" "apt-get update"
    run_command "Upgrade packages" "apt-get upgrade -y"
    run_command "Upgrade distribution" "apt-get dist-upgrade -y"
    run_command "Autoremove unused packages" "apt-get autoremove -y"
}

enable_repositories() {
    print_section "Enable Additional Repositories"
    
    if ! ask_permission "Enable additional Ubuntu repositories (universe, restricted, multiverse)?"; then
        log_message WARNING "Skipping repository setup"
        return
    fi
    
    for repo in universe restricted multiverse; do
        run_command "Enable $repo repository" "add-apt-repository -y $repo"
    done
    
    run_command "Update package lists" "apt-get update"
}

install_essential_packages() {
    print_section "Essential Packages Installation"
    
    if ! ask_permission "Install essential packages and libraries?"; then
        log_message WARNING "Skipping essential packages"
        return
    fi
    
    local packages=(
        "build-essential"
        "gcc"
        "g++"
        "make"
        "cmake"
        "git"
        "curl"
        "wget"
        "vim"
        "nano"
        "htop"
        "net-tools"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "xclip"
        "xsel"
        "unzip"
        "zip"
        "p7zip-full"
        "tar"
        "gzip"
        "openssh-client"
        "openssh-server"
    )
    
    log_message INFO "Installing essential packages: ${packages[@]}"
    run_command "Install essential packages" "apt-get install -y ${packages[*]}"
}

install_media_codecs() {
    print_section "Media Codecs & Libraries"
    
    if ! ask_permission "Install essential media codecs?"; then
        log_message WARNING "Skipping media codecs"
        return
    fi
    
    run_command "Install ubuntu-restricted-extras" "apt-get install -y ubuntu-restricted-extras"
    
    local media_packages=(
        "ffmpeg"
        "libavcodec-extra"
        "vlc"
        "gstreamer1.0-plugins-good"
        "gstreamer1.0-plugins-bad"
        "gstreamer1.0-plugins-ugly"
        "gstreamer1.0-libav"
    )
    
    run_command "Install media packages" "apt-get install -y ${media_packages[*]}"
}

install_development_tools() {
    print_section "Development Tools"
    
    if ! ask_permission "Install development tools?"; then
        log_message WARNING "Skipping development tools"
        return
    fi
    
    # Python
    if ask_permission "Install Python 3 development tools?"; then
        local python_packages=(
            "python3"
            "python3-pip"
            "python3-venv"
            "python3-dev"
            "ipython3"
        )
        run_command "Install Python packages" "apt-get install -y ${python_packages[*]}"
        run_command "Upgrade pip" "pip3 install --upgrade pip"
    fi
    
    # Node.js & npm
    if ask_permission "Install Node.js and npm?"; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - >> "$LOG_FILE" 2>&1
        run_command "Install Node.js" "apt-get install -y nodejs"
    fi
    
    # Git configuration
    if ask_permission "Configure Git?"; then
        read -p "Enter your Git email: " git_email
        read -p "Enter your Git name: " git_name
        
        git config --global user.email "$git_email"
        git config --global user.name "$git_name"
        git config --global color.branch auto
        git config --global color.diff auto
        git config --global color.status auto
        
        log_message SUCCESS "Git configured"
    fi
}

install_system_tools() {
    print_section "System Tools & Utilities"
    
    if ! ask_permission "Install system utilities?"; then
        log_message WARNING "Skipping system tools"
        return
    fi
    
    local tools=(
        "neofetch"
        "btop"
        "iotop"
        "iftop"
        "nethogs"
        "dconf-editor"
        "gparted"
        "baobab"
        "file-roller"
        "gdebi"
        "synaptic"
        "gnome-tweaks"
    )
    
    run_command "Install system tools" "apt-get install -y ${tools[*]}"
}

install_gnome_extensions() {
    print_section "GNOME Desktop Customization"
    
    if ! ask_permission "Install GNOME extensions and manager?"; then
        log_message WARNING "Skipping GNOME extensions"
        return
    fi
    
    local gnome_packages=(
        "gnome-shell-extensions"
        "gnome-shell-extension-manager"
        "gnome-weather"
        "gnome-calendar"
        "gnome-maps"
    )
    
    run_command "Install GNOME packages" "apt-get install -y ${gnome_packages[*]}"
}

setup_firewall() {
    print_section "Firewall Setup"
    
    if ! ask_permission "Setup and enable UFW firewall?"; then
        log_message WARNING "Skipping firewall setup"
        return
    fi
    
    run_command "Enable UFW" "ufw --force enable"
    run_command "Set UFW default policies" "ufw default deny incoming && ufw default allow outgoing"
    run_command "Allow SSH" "ufw allow 22/tcp"
    
    log_message SUCCESS "Firewall configured"
}

optimize_system() {
    print_section "System Optimization"
    
    if ! ask_permission "Optimize system performance?"; then
        log_message WARNING "Skipping system optimization"
        return
    fi
    
    # Swappiness (for better performance on systems with adequate RAM)
    if ask_permission "Adjust swap usage (swappiness=30 for better responsiveness)?"; then
        echo "vm.swappiness=30" >> /etc/sysctl.conf
        sysctl -p >> "$LOG_FILE" 2>&1
        log_message SUCCESS "Swappiness adjusted to 30"
    fi
    
    # Enable 32-bit architecture support
    if ask_permission "Enable 32-bit architecture support?"; then
        run_command "Add 32-bit architecture" "dpkg --add-architecture i386"
        run_command "Install 32-bit libraries" "apt-get install -y libc6:i386 libstdc++6:i386 libncurses5:i386 zlib1g:i386"
    fi
    
    # Preload (speeds up application startup)
    if ask_permission "Install preload (speeds up application startup)?"; then
        run_command "Install preload" "apt-get install -y preload"
        run_command "Enable preload" "systemctl enable preload"
    fi
}

install_additional_software() {
    print_section "Additional Software"
    
    if ! ask_permission "Install additional software?"; then
        log_message WARNING "Skipping additional software"
        return
    fi
    
    # Code editors
    if ask_permission "Install Visual Studio Code?"; then
        curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
        install -D -o root -g root -m 644 /tmp/microsoft.gpg /etc/apt/keyrings/microsoft-archive-keyring.gpg
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/vscode stable main" | tee /etc/apt/sources.list.d/vscode.list >> "$LOG_FILE" 2>&1
        run_command "Install VS Code" "apt-get update && apt-get install -y code"
    fi
    
    # Productivity tools
    if ask_permission "Install productivity tools (keepassxc, calibre, etc)?"; then
        local productivity=(
            "keepassxc"
            "libreoffice"
            "thunderbird"
            "gpg"
        )
        run_command "Install productivity tools" "apt-get install -y ${productivity[*]}"
    fi
    
    # Multimedia tools
    if ask_permission "Install multimedia tools (gimp, kdenlive, etc)?"; then
        local multimedia=(
            "gimp"
            "kdenlive"
            "audacity"
            "blender"
        )
        # Some packages might not be available, so we handle errors gracefully
        apt-get install -y ${multimedia[*]} 2>> "$LOG_FILE" || log_message WARNING "Some multimedia packages failed to install"
    fi
}

cleanup_system() {
    print_section "System Cleanup"
    
    if ! ask_permission "Clean and optimize system?"; then
        log_message WARNING "Skipping system cleanup"
        return
    fi
    
    run_command "Clean package cache" "apt-get clean"
    run_command "Clean package lists" "apt-get autoclean"
    run_command "Remove unused dependencies" "apt-get autoremove -y"
    
    log_message SUCCESS "System cleanup completed"
}

generate_ssh_key() {
    print_section "SSH Key Generation"
    
    if ! ask_permission "Generate SSH key?"; then
        log_message WARNING "Skipping SSH key generation"
        return
    fi
    
    read -p "Enter your email for SSH key: " email
    
    if [ -z "$email" ]; then
        log_message ERROR "Email cannot be empty"
        return
    fi
    
    run_command "Generate SSH key" "ssh-keygen -t rsa -b 4096 -C '$email' -f ~/.ssh/id_rsa -N ''"
    
    if check_command xclip; then
        cat ~/.ssh/id_rsa.pub | xclip -selection clipboard
        log_message SUCCESS "SSH public key copied to clipboard"
    else
        log_message INFO "SSH public key saved at ~/.ssh/id_rsa.pub"
    fi
}

final_steps() {
    print_section "Final Steps"
    
    log_message INFO "System setup is nearly complete!"
    log_message INFO "Setup log saved at: $LOG_FILE"
    
    if ask_permission "Would you like to reboot the system now?"; then
        log_message INFO "Rebooting in 10 seconds..."
        sleep 10
        reboot
    else
        log_message INFO "Please restart your system manually to complete the setup"
    fi
}

show_summary() {
    print_header "SETUP SUMMARY"
    
    echo -e "${GREEN}Installation and configuration completed!${NC}"
    echo ""
    echo "Setup Log: $LOG_FILE"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your system (if not done)"
    echo "  2. Configure GNOME settings via Settings app"
    echo "  3. Install GNOME extensions as needed"
    echo "  4. Configure applications preferences"
    echo "  5. Set up any development environments"
    echo ""
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    clear
    
    print_header "UBUNTU ULTIMATE SETUP SCRIPT v1.0"
    
    echo "This script will:"
    echo "  • Update and upgrade your system"
    echo "  • Install essential development tools"
    echo "  • Configure system optimizations"
    echo "  • Install additional software"
    echo "  • Configure security and firewall"
    echo ""
    
    check_root
    initial_setup
    
    # Execute setup functions
    update_system
    enable_repositories
    install_essential_packages
    install_media_codecs
    install_development_tools
    install_system_tools
    install_gnome_extensions
    setup_firewall
    optimize_system
    install_additional_software
    cleanup_system
    generate_ssh_key
    show_summary
    final_steps
}

# Execute main function
main "$@"
