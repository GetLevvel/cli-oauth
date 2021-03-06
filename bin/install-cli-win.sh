#/ Usage: bash install-cli-win.sh [--debug]
#/ Install development dependencies on Windows.
set -e

BLUE='\e[;34m'
ORANGE='\e[1;31m'
printf ""
printf "${BLUE}██▄▄                   ███                 ███                          ███   ███\n"
printf "${BLUE}▀▀█████▄▄              ███                 ███                 ▄▄▄▄▄    ███      \n"
printf "${BLUE}     ▀▀████▄▄          ███   ▀██    ▐██▀   ███               ▄███▀▀██   ███   ███\n"
printf "${BLUE}       ▄▄████▀▀        ███    ███   ██▌    ███              ▐██▀        ███   ███\n"
printf "${BLUE}  ▄▄▄████▀▀            ███     ███ ███     ███              ▐██▄        ███   ███\n"
printf "${BLUE}████▀▀▀    ${ORANGE}▄▄▄▄▄▄▄▄▄▄${BLUE}  ███      █████      ███   ${ORANGE}▄▄▄▄▄▄▄▄${BLUE}    ▀███▄▄██   ███   ███\n"
printf "${BLUE}▀▀      ${ORANGE}▀▀▀▀▀▀▀▀▀▀▀▀▀${BLUE}  ▀▀▀       ▀▀▀       ▀▀▀   ${ORANGE}▀▀▀▀▀▀▀▀▀▀${BLUE}    ▀▀▀▀▀    ▀▀▀   ▀▀▀\e[0m\n"

# Turn on emojis
chcp.com 65001

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
if ! [[ $os =~ "mingw64" ]]
then
  echo "This is an unsupported enviroment. Please contact us at https://github.com/GetLevvel/lvl_cli/issues or in slack #lvl_cli"
  exit 1
fi

# Check for git 
if ! git --version
then 
  echo "Installer cannot use the git command. Please verify git is installed!"
  exit 1
fi

# Check for node
if ! npm -v
then 
  echo "Installer cannot use the npm command. Please verify npm is installed!"
  exit 1
fi

# Check for yarn
if ! yarn -v
then 
  echo "Installer cannot use the yarn command. Please verify yarn is installed!"
  exit 1
fi

#Set lvl_cli dir
dir="$(eval echo ~)/.lvl_cli"

#check for previous installation  
if [ -d "$dir" -a ! -h "$dir" ]
then
   npm unlink $dir --silent
   rm -rf $dir
fi

#Install lvl-cli
mkdir -p $dir
cd $dir
curl -s http://lvl-cli.s3.amazonaws.com/channels/$release/lvl-win32-x64.tar.gz --output $dir/lvl-$os-$arch.tar.gz
tar -zxf lvl-$os-$arch.tar.gz

echo >>~/.bash_profile
echo export PATH="\$PATH:$dir/lvl/bin/" >>~/.bash_profile
echo "PATH updated in "~/.bash_profile
source ~/.bash_profile

#login to github
lvl login $CLI_GITHUB_TOKEN
lvl log:set-token $CLI_LOG_TOKEN
echo "lvl_cli has been successfully installed! Run lvl -h to get started."
