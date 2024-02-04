#!/bin/bash

# 1. check if g is installed and match the version, if not, install, else exit
# 2.  install the binary to /usr/local/bin [darwin] or /usr/bin [linux]
# 3. install man to /usr/local/share/man/man1
# 4. install completion to /usr/local/share/zsh/site-functions
#    if compinit is not in .zshrc or .zprofile, add it


# Get OS and architecture
os_type=$(uname -s | tr '[:upper:]' '[:lower:]')
os_arch=$(uname -m)
version="0.25.3"
man_url="https://github.com/Equationzhao/g/raw/v${version}/man/g.1.gz"

interrupt_handler() {
  exit 1
}

trap interrupt_handler SIGINT

# flag
# -v: print version
# -h: print help
# -d: download binary (default)

help(){
    echo "g: Yet another ls"
    echo "Usage: install.sh [-v|-h|-d]"
    echo "  -v: print version"
    echo "  -h: print help"
    echo "  -d: download binary (default)"
    echo "  -r: uninstall"
}

error() {
    printf '\033[1;31m%s\033[0m\n' "$1"
}

success() {
    printf '\033[1;32m%s\033[0m\n' "$1"
}

warn() {
    printf '\033[1;33m%s\033[0m\n' "$1"
}

# Download the file using curl or wget
download_url(){
  url_to_download=$1
  if command -v curl &> /dev/null; then
      echo "curl -fLO $url_to_download"
      curl -fLO "$url_to_download"
  elif command -v wget &> /dev/null; then
      echo "wget $url_to_download"
      wget "$url_to_download"
  else
      error "You need to install curl or wget to download the file."
      exit 1
  fi
}

download_completion(){
    shell_name=$1
    # v0.25.3 install from the master
    url="https://github.com/Equationzhao/g/raw/master/completions/${shell_name}/_g"
    # other version install from the release
    if [ "$version" != "0.25.3" ]; then
        url="https://github.com/Equationzhao/g/raw/v${version}/completions/${shell_name}/_g"
    fi
    download_url $url
    if [ $? -ne 0 ]; then
        error "Failed to download the file."
        exit 1
    fi
}

check_compinit(){
    if [ -f ~/.zshrc ]; then
        if ! grep -q "autoload -Uz compinit" ~/.zshrc; then
            echo "autoload -Uz compinit" >> ~/.zshrc
            echo "compinit" >> ~/.zshrc
            success "compinit has been added to ~/.zshrc"
        fi
    elif [ -f ~/.zprofile ]; then
        if ! grep -q "autoload -Uz compinit" ~/.zprofile; then
            echo "autoload -Uz compinit" >> ~/.zprofile
            echo "compinit" >> ~/.zprofile
            success "compinit has been added to ~/.zprofile"
        fi
    fi
}

uninstall_g(){
  case $os_type in
      darwin)
          installed_location="/usr/local/bin"
          echo "rm $installed_location/g"
          sudo rm $installed_location/g
          installed_location="/usr/local/share/man/man1"
          echo "rm $installed_location/g.1.gz"
          sudo rm $installed_location/g.1.gz
          completion_path="/usr/local/share/zsh/site-functions"
          echo "rm $completion_path/_g"
          sudo rm $completion_path/_g
          ;;
      linux)
          installed_location="/usr/bin"
          echo "rm $installed_location/g"
          sudo rm $installed_location/g
          installed_location="/usr/local/share/man/man1"
          echo "rm $installed_location/g.1.gz"
          sudo rm $installed_location/g.1.gz
          completion_path="/usr/local/share/zsh/site-functions"
          echo "rm $completion_path/_g"
          sudo rm $completion_path/_g
          ;;
  esac
}

# Parse flags
while getopts "vhdr" opt; do
    case $opt in
        v)
            echo "$version"
            exit 0
            ;;
        h)
            help
            exit 0
            ;;
        d)
            ;;
        r)
            uninstall_g
            success "g has been uninstalled"
            exit 0
            ;;
        \?)
            error "Invalid option: -$OPTARG"
            help
            exit 1
            ;;
    esac
done


compare_versions() {
    local A="$1"
    local B="$2"

    if [[ $A == $B ]]; then
        return 0
    fi

    IFS='.' read -ra A_parts <<< "$A"
    IFS='.' read -ra B_parts <<< "$B"

    for i in "${!A_parts[@]}"; do
        if (( ${A_parts[i]} > ${B_parts[i]} )); then
            return 0
        elif (( ${A_parts[i]} < ${B_parts[i]} )); then
            return 1
        fi
    done

}

# if already has g, and g --version >= version, exit
if command -v g &> /dev/null; then
    g_version=$(g --version | awk 'NR==2 {print $NF}')
    compare_versions "$g_version" "$version"
    result=$?
    if [ $result -eq 0 ]; then
        echo "g version $g_version already installed"
        exit 0
    fi
fi


# Determine file architecture based on OS architecture
case $os_arch in
    x86_64)
        file_arch="amd64"
        ;;
    arm64)
        file_arch="arm64"
        ;;
    i386)
        file_arch="386"
        ;;
    arm*)
        file_arch="arm"
        ;;
    *)
        error "Unsupported architecture: $os_arch"
        exit 1
        ;;
esac

# Determine file OS based on OS type
case $os_type in
    darwin)
        file_os="darwin"
        ;;
    linux)
        file_os="linux"
        ;;
#    msys)
#        file_os="windows"
#        ;;
    *)
        error "Unsupported OS type: $os_type"
        exit 1
        ;;
esac

file_name=g-${file_os}-${file_arch}

# Build download URL
url="https://github.com/Equationzhao/g/releases/download/v${version}/${file_name}"

## Add .exe extension for Windows
# if [ "$file_os" = "windows" ]; then
#     url="${url}.exe"
# fi

download_url $url

if [ $? -ne 0 ]; then
    error "Failed to download the file."
    exit 1
fi

# Make the file executable for Linux or Darwin
if [ "$file_os" = "linux" ] || [ "$file_os" = "darwin" ]; then
    chmod +x g-${file_os}-${file_arch}
fi

# executable
case $os_type in
    darwin)
        installed_location="/usr/local/bin"
        echo "mv ${file_name} $installed_location/g"
        sudo mv ${file_name} $installed_location/g
        ;;
    linux)
        installed_location="/usr/bin"
        echo "mv ${file_name} $installed_location/g"
        sudo mv ${file_name} $installed_location/g
        ;;
esac

success "g $version has been installed in $installed_location"

# man page
installed_location="/usr/local/share/man/man1"
sudo mkdir -p $installed_location
download_url $man_url
echo "mv g.1.gz $installed_location/g.1.gz"
sudo mv g.1.gz $installed_location/g.1.gz

success "man page has been installed in $installed_location"


# install completion
shell_type=$(echo $SHELL | awk -F'/' '{print $NF}')

completion_path="/usr/local/share/zsh/site-functions"
case $shell_type in
    zsh)
        download_completion "$shell_type"
        sudo mkdir -p $completion_path
        echo "mv _g $completion_path/_g"
        sudo mv _g "$completion_path/_g"
        check_compinit
        success "completion has been installed in $completion_path"
        ;;
    \?)
        error "Unsupported shell type: $shell_type"
        warn "skip completion installation"
        ;;
esac