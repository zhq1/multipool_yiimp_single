#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

clear
source /etc/functions.sh
source $STORAGE_ROOT/yiimp/.yiimp.conf

# Set timezone
echo Setting TimeZone to UTC...
if [ ! -f /etc/timezone ]; then
echo "Setting timezone to UTC."
echo "Etc/UTC" > sudo /etc/timezone
restart_service rsyslog
fi

# Add repository
echo Adding the required repsoitories...
if [ ! -f /usr/bin/add-apt-repository ]; then
echo "Installing add-apt-repository..."
hide_output sudo apt-get -y update
apt_install software-properties-common
fi
# PHP 7
echo Installing Ondrej PHP PPA...
if [ ! -f /etc/apt/sources.list.d/ondrej-php-bionic.list ]; then
hide_output sudo add-apt-repository -y ppa:ondrej/php
fi
# MariaDB
echo Installing MariaDB Repository...
hide_output sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mirrors.evowise.com/mariadb/repo/10.3/ubuntu xenial main'

# Upgrade System Files
echo Updating system packages...
hide_output sudo apt-get update
echo Upgrading system packages...
if [ ! -f /boot/grub/menu.lst ]; then
apt_get_quiet upgrade
else
sudo rm /boot/grub/menu.lst
hide_output sudo update-grub-legacy-ec2 -y
apt_get_quiet upgrade
fi
echo Running Dist-Upgrade...
apt_get_quiet dist-upgrade
echo Running Autoremove...
apt_get_quiet autoremove

echo Installing Base system packages...
apt_install python3 python3-dev python3-pip \
wget curl git sudo coreutils bc \
haveged pollinate unzip \
unattended-upgrades cron ntp fail2ban screen

# ### Seed /dev/urandom
echo Initializing system random number generator...
hide_output dd if=/dev/random of=/dev/urandom bs=1 count=32 2> /dev/null
hide_output sudo pollinate -q -r

if [ -z "$DISABLE_FIREWALL" ]; then
# Install `ufw` which provides a simple firewall configuration.
echo Installing UFW...
apt_install ufw

# Allow incoming connections.
ufw_allow ssh;
ufw_allow http;
ufw_allow https;

# ssh might be running on an alternate port. Use sshd -T to dump sshd's #NODOC
# settings, find the port it is supposedly running on, and open that port #NODOC
# too. #NODOC
SSH_PORT=$(sshd -T 2>/dev/null | grep "^port " | sed "s/port //") #NODOC
if [ ! -z "$SSH_PORT" ]; then
if [ "$SSH_PORT" != "22" ]; then

echo Opening alternate SSH port $SSH_PORT. #NODOC
ufw_allow $SSH_PORT #NODOC

fi
fi

sudo ufw --force enable;
fi #NODOC

echo Installing YiiMP Required system packages...
if [ -f /usr/sbin/apache2 ]; then
echo Removing apache...
hide_output apt-get -y purge apache2 apache2-*
hide_output apt-get -y --purge autoremove
fi
hide_output sudo apt-get update

apt_install php7.2-fpm php7.2-opcache php7.2-fpm php7.2 php7.2-common php7.2-gd \
php7.2-mysql php7.2-imap php7.2-cli php7.2-cgi \
php-pear php-auth-sasl mcrypt imagemagick libruby \
php7.2-curl php7.2-intl php7.2-pspell php7.2-recode php7.2-sqlite3 \
php7.2-tidy php7.2-xmlrpc php7.2-xsl memcached php-memcache \
php-imagick php-gettext php7.2-zip php7.2-mbstring \
fail2ban ntpdate python3 python3-dev python3-pip \
curl git sudo coreutils pollinate unzip unattended-upgrades cron \
nginx pwgen libgmp3-dev libmysqlclient-dev libcurl4-gnutls-dev \
libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils git cmake libboost-all-dev zlib1g-dev libz-dev libseccomp-dev libcap-dev libminiupnpc-dev \
libkrb5-dev libldap2-dev libidn11-dev libssl-dev gnutls-dev librtmp-dev libminiupnpc10 libzmq5 libcanberra-gtk-module libqrencode-dev libzmq3-dev \
build-essential libtool autotools-dev automake pkg-config openssl libevent-dev bsdmainutils --allow-downgrades

sudo add-apt-repository -y ppa:bitcoin/bitcoin
sudo apt-get -y update
sudo apt-get install -y libdb4.8-dev libdb4.8++-dev libdb5.3 libdb5.3++

echo Downloading selected YiiMP Repo...
hide_output sudo git clone ${YiiMPRepo} $STORAGE_ROOT/yiimp/yiimp_setup/yiimp
if [[ ("$CoinPort" == "y" || "$CoinPort" == "Y" || "$CoinPort" == "yes" || "$CoinPort" == "Yes" || "$CoinPort" == "YES") ]]; then
	cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp
	sudo git fetch
	sudo git checkout multi-port
fi

cd $HOME/multipool/yiimp_single
