#!/bin/bash
#/ Usage: bin/install-cli.sh [--debug]
#/ Install development dependencies on macOS.
set -e

BLUE='\e[;34m'
ORANGE='\e[1;31m'
printf "${BLUE}██▄▄                   ███                 ███                          ███   ███\n"
printf "${BLUE}▀▀█████▄▄              ███                 ███                 ▄▄▄▄▄    ███      \n"
printf "${BLUE}     ▀▀████▄▄          ███   ▀██    ▐██▀   ███               ▄███▀▀██   ███   ███\n"
printf "${BLUE}       ▄▄████▀▀        ███    ███   ██▌    ███              ▐██▀        ███   ███\n"
printf "${BLUE}  ▄▄▄████▀▀            ███     ███ ███     ███              ▐██▄        ███   ███\n"
printf "${BLUE}████▀▀▀    ${ORANGE}▄▄▄▄▄▄▄▄▄▄${BLUE}  ███      █████      ███   ${ORANGE}▄▄▄▄▄▄▄▄${BLUE}    ▀███▄▄██   ███   ███\n"
printf "${BLUE}▀▀      ${ORANGE}▀▀▀▀▀▀▀▀▀▀▀▀▀${BLUE}  ▀▀▀       ▀▀▀       ▀▀▀   ${ORANGE}▀▀▀▀▀▀▀▀▀▀${BLUE}    ▀▀▀▀▀    ▀▀▀   ▀▀▀\e[0m\n"

[[ "$1" = "--debug" || -o xtrace ]] && CLI_DEBUG="1"
CLI_SUCCESS=""

if [ -n "$CLI_DEBUG" ]; then
  set -x
else
  CLI_QUIET_FLAG="-q"
  Q="$CLI_QUIET_FLAG"
fi

STDIN_FILE_DESCRIPTOR="0"
[ -t "$STDIN_FILE_DESCRIPTOR" ] && CLI_INTERACTIVE="1"

# Set by web/app.rb
# CLI_GIT_NAME=
# CLI_GIT_EMAIL=
# CLI_GITHUB_USER=
# CLI_GITHUB_TOKEN=
# CLI_LOG_TOKEN=
CLI_ISSUES_URL='https://github.com/GetLevvel/lvl_cli/issues/new'

# functions for turning off debug for use when handling the user password
clear_debug() {
  set +x
}

reset_debug() {
  if [ -n "$CLI_DEBUG" ]; then
    set -x
  fi
}

abort() { CLI_STEP="";   echo "!!! $*" >&2; exit 1; }
log()   { CLI_STEP="$*"; echo "--> $*"; }
logn()  { CLI_STEP="$*"; printf -- "--> %s " "$*"; }
logk()  { CLI_STEP="";   echo "OK"; }
escape() {
  printf '%s' "${1//\'/\'}"
}

#set release channel
release="beta"

#Gather OS and Arch
os=$(uname | tr '[A-Z]' '[a-z]')
arch=$(uname -m)
if [[ "$arch" = "x86_64" ]]
then
   arch=$(echo $arch | sed -e 's/86_//')
fi    

if [ "$os" != "linux" ] && [ "$os" != "darwin" ]
then
  echo "This is an unsupported enviroment. Please contact us at https://github.com/GetLevvel/lvl_cli/issues or in slack #lvl_cli"
fi

# Check for git 
if ! git --version
then 
  echo "Installer cannot use git command. Please verify git is installed!"
fi
  
#Set lvl_cli dir
dir="$HOME/.lvl_cli"

#check for previous installation  
if [ -d "$dir" -a ! -h "$dir" ]
then
   npm unlink $dir --silent
fi

#Install lvl-cli
mkdir -p $HOME/.lvl_cli
cd $HOME/.lvl_cli
curl -s http://lvl-cli.s3.amazonaws.com/channels/$release/lvl-$os-$arch.tar.gz --output $dir/lvl-$os-$arch.tar.gz
tar -zxf lvl-$os-$arch.tar.gz 
if [[ ! -z $(grep "lvl_cli" "$HOME/.bash_profile") ]]
then
    :
else
    echo export PATH="\$PATH:$dir/lvl/bin/" >> $HOME/.bash_profile
fi

source $HOME/.bash_profile

#login to github
lvl login $CLI_GITHUB_TOKEN
lvl log:set-token $CLI_LOG_TOKEN
echo "lvl_cli has been successfully installed! Run lvl -h to get started."