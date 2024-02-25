#!/bin/bash - 
#===============================================================================
#
#          FILE: setup.sh
# 
#         USAGE: ./setup.sh 
# 
#   DESCRIPTION: Setup Fedora 35 for Mobile Penetration Testing and Bug Bounty.
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Amit Agarwal (aka)
#  ORGANIZATION: 
#       CREATED: 01/23/2022 15:18
#      REVISION:  ---
#===============================================================================

BDIR=~/mobilehacking/
DDIR="$BDIR/downloads"
GDIR="$BDIR/git"


mkdir -p $BDIR $DDIR $GDIR
cp git-urls  $BDIR
cd $BDIR

# echo "Forward 5555 to your host :) ssh -Nf -L 5555:localhost:5555 amitag@172.16.70.1"

## Check for the OS
if [[ "$(cat /etc/redhat-release)" =~ Fedora.release* ]]
then
    echo "Found Fedora"
else
    echo "Cannot continue on other than Fedora"
    exit
fi

alias pip2='python2.7 -m pip'

git_clone()
{
    cd $GDIR
    if [[ -d $(basename $1) ]]
    then
	( cd $(basename $1); git reset --hard; git pull)
    else
	git clone $1
    fi
}

download_file()
{
    cd $DDIR/
    wget -c "$1"
}

setup_npm_local()
{
    NPM_PACKAGES="$HOME/.npm-packages"
    mkdir -p "$NPM_PACKAGES"
    echo "prefix = $NPM_PACKAGES" >> ~/.npmrc

    cat <<EOF >> ~/.bashrc_npm
# NPM packages in homedir
NPM_PACKAGES="$HOME/.npm-packages"

# Tell our environment about user-installed node tools
PATH="$NPM_PACKAGES/bin:$PATH"
# Unset manpath so we can inherit from /etc/manpath via the `manpath` command
unset MANPATH  # delete if you already modified MANPATH elsewhere in your configuration
MANPATH="$NPM_PACKAGES/share/man:$(manpath)"

# Tell Node about these packages
NODE_PATH="$NPM_PACKAGES/lib/node_modules:$NODE_PATH"
EOF
if [[ $(grep -c bashrc_npm ~/.bashrc) == 0 ]]
then
    echo 'source ~/.bashrc_npm' >> ~/.bashrc
fi
}


## Install some packages with dnf and sudo
sudo dnf install -y vim python2.7 android-tools adb-enhanced npm java-11-openjdk-devel wkhtmltopdf python3-gunicorn lynx

cat <<'EOF' | tee -a $BDIR/README.txt
# Readme for Mobile Hacking Setup

## Install with dnf on Fedora 35

Although this script was developed with Fedora 35 but hopefully it should work with any recent version of Fedora, feel free to try on any version of Fedora and provide feedback :)

Installed the following
- vim
- drozer
- adb
- androguard
- andriller
- androwarn
- npm
- jarsigner

## Drozer

```bash
adb devices
adb forward tcp:31415 tcp:31415
## start drozer agent on mobile
drozer console connect

```

EOF

## git repos
cat <<'EOF' | tee -a $BDIR/README.txt

## Git repos

We will clone some useful git repos.

EOF
while read line
do

    git_clone "$line" 
    echo "- $(basename $line)" >> $BDIR/README.txt

done < $BDIR/git-urls

## Install frida
pip install --user frida-tools
frida_ver=$(lynx -dump https://github.com/frida/frida/releases/|grep server|sed -E '2,$d;s/.*frida-server-([0-9\.]*)-.*/\1/')
download_file "https://github.com/frida/frida/releases/download/15.1.14/frida-server-$ver-android-arm.xz"
download_file "https://github.com/frida/frida/releases/download/15.1.14/frida-server-$ver-android-arm64.xz"
download_file "https://github.com/frida/frida/releases/download/15.1.14/frida-server-$ver-android-x86.xz"
download_file "https://github.com/frida/frida/releases/download/15.1.14/frida-server-$ver-android-x86_64.xz"

cat <<'EOF' | tee -a $BDIR/README.txt


## Frida
Installed friday tools with pip3.

EOF

## Download and install get-pip for python 2.7
download_file "https://bootstrap.pypa.io/pip/2.7/get-pip.py"
python2.7 -m get-pip.py
cat <<'EOF'  | tee -a $BDIR/README.txt

## python2.7 pip

Python 2.7 and pip are requirement for some of the tools. Although it is end of life but still useful for some tools.

pip for pyhton 2.7
Install pip for pyhton 2.7.
EOF

## Install some python2 modules for drozer and other tools
for modules in twisted protobuf service_identity
do
    pip2 install $modules
done

## Get Drozer files
download_file "https://github.com/mwrlabs/drozer/releases/download/2.4.4/drozer_2.4.4.deb"
download_file "https://github.com/mwrlabs/drozer/releases/download/2.4.4/drozer-2.4.4-1.noarch.rpm"
download_file "https://github.com/mwrlabs/drozer/releases/download/2.3.4/drozer-agent-2.3.4.apk"
download_file "https://github.com/mwrlabs/drozer/releases/download/2.4.4/drozer-2.4.4.win32.msi"
pip2 install drozer



## Install rms

setup_npm_local
npm install -g rms-runtime-mobile-security
cat <<'EOF' | tee -a $BDIR/README.txt
## Setup RMS

Make sure frida-server is up and running on the target device.

Instructions are here: prerequisites / quick smoke-test

Launch RMS via the following command

    rms (or RMS-Runtime-Mobile-Security)

Open your browser at http://127.0.0.1:5000/
Start enjoying RMS iphonefire

EOF

## Install and setup Objection
pip3 install --upgrade objection
cat <<'EOF' | tee -a $BDIR/README.txt
## Objection

objection is installed, you can now run :
objection -h

Some examples:

objection explore
	ls
	env
	file download fhash.dat fhash.dat
	android hooking list activities
	android intent launch_activity com.facebook.ads.AudienceNetworkActivity
EOF

# Install fernflower
cd $GDIR/fernflower
./gradlew build

cat <<'EOF' | tee -a $BDIR/README.txt
This is java decompiler and you can use it like this:
java -jar fernflower.jar -hes=0 -hdc=0 c:\Temp\binary\ -e=c:\Java\rt.jar c:\Temp\source\

java -jar fernflower.jar -dgs=1 c:\Temp\binary\library.jar c:\Temp\binary\Boot.class c:\Temp\source\
EOF

## enjarify apk to java
cat <<'EOF' | tee -a $BDIR/README.txt
cd $GDIR/enjarify
python3 -O -m enjarify.main yourapp.apk
EOF



cat <<'EOF' | tee -a $BDIR/README.txt
## Inspeckage
Inspeckage is a tool developed to offer dynamic analysis of Android applications. By applying hooks to functions of the Android API, Inspeckage will help you understand what an Android application is doing at runtime.

EOF

cat <<'EOF' | tee -a $BDIR/README.txt
Some example endroid apks for practice

EOF

## PIDCat
cat <<'EOF'  | tee -a $BDIR/README.txt
An update to Jeff Sharkey's excellent logcat color script which only shows log entries for processes from a specific application package.

During application development you often want to only display log messages coming from your app. Unfortunately, because the process ID changes every time you deploy to the phone it becomes a challenge to grep for the right thing.

This script solves that problem by filtering by application package. Supply the target package as the sole argument to the python script and enjoy a more convenient development process.

pidcat com.oprah.bees.android

EOF

## QArk
( cd $GDIR/qark
pip install -r requirements.txt
pip install . --user
)

cat <<'EOF'  | tee -a $BDIR/README.txt
This tool is designed to look for several security related Android application vulnerabilities, either in source code or packaged APKs. The tool is also capable of creating "Proof-of-Concept" deployable APKs and/or ADB commands, capable of exploiting many of the vulnerabilities it finds. There is no need to root the test device, as this tool focuses on vulnerabilities that can be exploited under otherwise secure conditions.

qark --apk path/to/my.apk


Usage

For more options please see the --help command.

APK:

~ qark --apk path/to/my.apk

Java source code files:

~ qark --java path/to/parent/java/folder
~ qark --java path/to/specific/java/file.java
EOF

## FireBaseScanner
download_file 'https://cdn2.hubspot.net/hubfs/436053/Appthority%20Q2-2018%20MTR%20Unsecured%20Firebase%20Databases.pdf'


cat <<'EOF'  | tee -a $BDIR/README.txt
Once the script is downloaded, run the script with the required arguments. We can either provide the APK file as an input as shown below:

python FirebaseMisconfig.py --path /home/shiv/TestAPK/test.apk
or
python FirebaseMisconfig.py -p /home/shiv/TestAPK/test.apk

EOF

## apktool
download_file 'https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool'
download_file 'https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.6.0.jar'
sudo mv $DDIR/apktool /usr/local/bin/apktool
sudo mv $DDIR/apktool_2.6.0.jar /usr/local/bin/apktool.jar
sudo chmod +x /usr/local/bin/apktool

## dex2jar


cat <<'EOF'  | tee -a $BDIR/README.txt

## Dex2jar

EOF
## jadx
cd $GDIR/jadx
./gradlew dist
echo 'export PATH=$PATH:$HOME/mobilehacking/git/jadx/build/jadx/bin' >> ~/.bashrc

cat <<'EOF'  | tee -a $BDIR/README.txt
jadx - Dex to Java decompiler


Command line and GUI tools for producing Java source code from Android Dex and Apk files

exclamation exclamation exclamation Please note that in most cases Jadx can't decompile all 100% of the code, so errors will occur. Check Troubleshooting guide for workarounds

Main features:

    decompile Dalvik bytecode to java classes from APK, dex, aar, aab and zip files
    decode AndroidManifest.xml and other resources from resources.arsc
    deobfuscator included

jadx-gui features:

    view decompiled code with highlighted syntax
    jump to declaration
    find usage
    full text search
    smali debugger (thanks to @LBJ-the-GOAT), check wiki page for setup and usage

See these features in action here: jadx-gui features overview
EOF


cat <<'EOF'  | tee -a $BDIR/README.txt

Secure tweet vulnerable app.

EOF

## cycript
wget -c -O $DDIR/cycript.zip https://cydia.saurik.com/api/latest/3
cat <<'EOF'  | tee -a $BDIR/README.txt

Read the documentation at :
http://www.cycript.org/manual/
What is Cycript?

Cycript is a hybrid of ECMAScript some-6, Objective-C++, and Java. It is implemented as a Cycript-to-JavaScript compiler and uses (unmodified) JavaScriptCore for its virtual machine. It concentrates on providing "fluent FFI" with other languages by adopting aspects of their syntax and semantics as opposed to treating the other language as a second-class citizen.

The primary users of Cycript are currently people who do reverse engineering work on iOS. Cycript features a highly interactive console that features live syntax highlighting and grammar-assisted tab completion, and can even be injected into a running process (similar to a debugger) using Cydia Substrate. This makes it an ideal tool for "spelunking".

However, Cycript was specifically designed as a programming environment and maintains very little (if any) "baggage" for this use case. Many modules from node.js can be loaded into Cycript, while it also has direct access to libraries written for Objective-C and Java. It thereby works extremely well as a scripting language.
EOF

## MSTG
download_file 'https://github.com/OWASP/owasp-mstg/releases/download/v1.4.0/OWASP_MSTG-v1.4.0.pdf'

## Cydia Impactor for Linux
wget -c -O $DDIR/cydia-impactor.tgz https://cydia.saurik.com/api/latest/5
cd $DDIR
mkdir cydia-impactor
cd cydia-impactor
tar xvf ../cydia-impactor.tgz

cat <<'EOF'  | tee -a $BDIR/README.txt

Building:
./build.sh
Testing:
./test.sh
Usage
    sign my.apk
    sign my.apk --override

keytool -genkey -alias replserver \
    -keyalg RSA -keystore keystore.jks \
    -keysize 4096 -deststoretype pkcs12 \
    -dname "CN=WhoAmI, OU=NA, O=NA, L=NA, S=NA, C=NA" \
    -storepass password -keypass password

jarsigner -storepass password -keypass password \
    -alias replserver \
    -sigalg SHA1withRSA -digestalg SHA1 new.apk baws -keystore keystore
EOF

## AppMon
pip install argparse frida flask termcolor dataset htmlentities --upgrade

cat <<'EOF'  | tee -a $BDIR/README.txt

AppMon is an automated framework for monitoring and tampering system API calls of native apps on macOS, iOS and Android. It is based on Frida. You may call it the GreaseMonkey for native mobile apps. ;-) 

EOF



cat <<'EOF' |tee -a $BDIR/README.txt
Installed FireBaseScanner

EOF

## Burp
wget -c  "https://portswigger.net/burp/releases/download?product=community&version=2021.12.1&type=Jar" -O $DDIR/burp.jar
cat <<'EOF' >$DDIR/burp
java -jar $DDIR/burp.jar
EOF
sudo cp $DDIR/burp /usr/local/bin/burp
sudo chmod +x /usr/local/bin/burp

## ZAP
cd $DDIR
l="https://github.com/zaproxy/zaproxy/releases/download/v2.11.1/ZAP_2.11.1_Linux.tar.gz"
download_file "$l"
tar xvzf "$(basename $l)"
cat <<'EOF' | sudo tee /usr/local/bin/zap
cd $DDIR/ZAP_2.11.1
./zap.sh
EOF
sudo chmod +x /usr/local/bin/zap




cat <<'EOF' |tee -a $BDIR/README.txt

# Vim Setup

You can use the following plugins with vim
https://github.com/python-mode/python-mode
https://github.com/vim-scripts/awk-support.vim
https://github.com/vim-scripts/bash-support.vim
https://github.com/vim-scripts/ctrlp.vim
https://github.com/vim-scripts/current-func-info.vim
https://github.com/vim-scripts/c.vim
https://github.com/vim-scripts/ftcolor.vim
https://github.com/ekalinin/Dockerfile.vim
https://github.com/vim-scripts/Improved-AnsiEsc
https://github.com/vim-scripts/MultipleSearch
https://github.com/vim-scripts/perl-support.vim
https://github.com/icx-jonv/kernel-coding-style
https://github.com/vim-scripts/rest.vim
https://github.com/python-mode/python-mode
https://github.com/vim-scripts/snipmate-snippets
https://github.com/vim-scripts/spec.vim
https://github.com/vim-scripts/supertab
https://github.com/vim-scripts/taglist.vim
https://github.com/tomtom/tlib_vim
https://github.com/vim-scripts/todo.vim
https://github.com/todotxt/todo.txt-cli
https://github.com/vim-scripts/vim-addon-mw-utils
https://github.com/vivien/vim-linux-coding-style
https://github.com/flazz/vim-colorschemes
https://github.com/vim-scripts/vimpager
https://github.com/vim-perl/vim-perl
https://github.com/Vimjas/vim-python-pep8-indent
https://github.com/jacquesbh/vim-showmarks
https://github.com/vim-scripts/snipMate
https://github.com/vim-scripts/vimtodo
https://github.com/vim-scripts/yaml.vim
https://github.com/tmhedberg/SimpylFold
https://github.com/psf/black
https://github.com/PotatoesMaster/i3-vim-syntax
https://github.com/scrooloose/nerdtree.git
https://github.com/tomasiser/vim-code-dark
https://github.com/ryanoasis/vim-devicons
http://fedorapeople.org/cgit/wwoods/public_git/vim-scripts.git/
https://github.com/garbas/vim-snipmate.git

EOF


a=(  \
    'https://github.com/python-mode/python-mode' \
    'https://github.com/vim-scripts/awk-support.vim' \
    'https://github.com/vim-scripts/bash-support.vim' \
    'https://github.com/vim-scripts/ctrlp.vim' \
    'https://github.com/vim-scripts/current-func-info.vim' \
    'https://github.com/vim-scripts/c.vim' \
    'https://github.com/vim-scripts/ftcolor.vim' \
    'https://github.com/ekalinin/Dockerfile.vim' \
    'https://github.com/vim-scripts/Improved-AnsiEsc' \
    'https://github.com/vim-scripts/MultipleSearch' \
    'https://github.com/vim-scripts/perl-support.vim' \
    'https://github.com/icx-jonv/kernel-coding-style' \
    'https://github.com/vim-scripts/rest.vim' \
    'https://github.com/python-mode/python-mode' \
    'https://github.com/vim-scripts/snipmate-snippets' \
    'https://github.com/vim-scripts/spec.vim' \
    'https://github.com/vim-scripts/supertab' \
    'https://github.com/vim-scripts/taglist.vim' \
    'https://github.com/tomtom/tlib_vim' \
    'https://github.com/vim-scripts/todo.vim' \
    'https://github.com/todotxt/todo.txt-cli' \
    'https://github.com/vim-scripts/vim-addon-mw-utils' \
    'https://github.com/vivien/vim-linux-coding-style' \
    'https://github.com/flazz/vim-colorschemes' \
    'https://github.com/vim-scripts/vimpager' \
    'https://github.com/vim-perl/vim-perl' \
    'https://github.com/Vimjas/vim-python-pep8-indent' \
    'https://github.com/jacquesbh/vim-showmarks' \
    'https://github.com/vim-scripts/snipMate' \
    'https://github.com/vim-scripts/vimtodo' \
    'https://github.com/vim-scripts/yaml.vim' \
    'https://github.com/tmhedberg/SimpylFold' \
    'https://github.com/psf/black' \
    'https://github.com/PotatoesMaster/i3-vim-syntax' \
    'https://github.com/scrooloose/nerdtree.git' \
    'https://github.com/tomasiser/vim-code-dark' \
    'https://github.com/ryanoasis/vim-devicons' \
    'http://fedorapeople.org/cgit/wwoods/public_git/vim-scripts.git/' \
    'https://github.com/garbas/vim-snipmate.git' \
)

read -p "Setup vim (yes/no)?" vimans

if [[ $vimans == "yes" ]]
then
    [[ ! -d ~/.vim/pack/mypack/start ]] &&	mkdir -p ~/.vim/pack/mypack/start
    cd ~/.vim/pack/mypack/start
    for f in ${a[@]}
    do
        git clone $f
    done
    pip install black
fi

read -p "Install VS Code (yes/no)?" vimans

if [[ $vimans == "yes" ]]
then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf install code
fi
