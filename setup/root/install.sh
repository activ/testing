#!/bin/bash

# exit script if return code != 0
set -e

echo Server = https://archive.archlinux.org/repos/last/\$repo/os/\$arch > /etc/pacman.d/mirrorlist

# build scripts
####

# download build scripts from github
#curl -o /tmp/scripts-master.zip -L https://github.com/binhex/scripts/archive/master.zip

# unzip build scripts
#unzip /tmp/scripts-master.zip -d /tmp

# move shell scripts to /root
#find /tmp/scripts-master/ -type f -name '*.sh' -exec mv -i {} /root/  \;

# pacman packages
####

# define pacman packages
pacman_packages="unzip unrar gnu-netcat tmux transmission-cli"

# install compiled packages using pacman
if [[ ! -z "${pacman_packages}" ]]; then
	pacman -Sy
	pacman -S --needed $pacman_packages --noconfirm
fi

# aor packages
####

# define arch official repo (aor) packages
#aor_packages=""

# call aor script (arch official repo)
#source /root/aor.sh

# aur packages
####

# define aur helper
#aur_helper="apacman"

# define aur packages
#aur_packages=""

# call aur install script (arch user repo)
#source /root/aur.sh

# call custom install script
#source /root/custom.sh

# config - php
####



# container perms
####


# create file with contents of here doc
 cat <<'EOF' > /tmp/permissions_heredoc
# set permissions inside container
#chown -R "${PUID}":"${PGID}" /etc/webapps/ /usr/share/webapps/ /usr/share/nginx/html/ /etc/nginx/ /etc/php/ /run/php-fpm/ /var/lib/nginx/ /var/log/nginx/ /etc/privoxy/ /home/nobody/ /etc/webapps/flood
#chmod -R 775 /etc/webapps/ /usr/share/webapps/ /usr/share/nginx/html/ /etc/nginx/ /etc/php/ /run/php-fpm/ /var/lib/nginx/ /var/log/nginx/ /etc/privoxy/ /home/nobody/ /etc/webapps/flood
chown -R "${PUID}":"${PGID}" /usr/bin/transmission-daemon /usr/bin/privoxy /etc/privoxy /home/nobody /config
chmod -R 775 /usr/bin/transmission-daemon /usr/bin/privoxy /etc/privoxy /home/nobody /config
	
# set shell for user nobody
chsh -s /bin/bash nobody

EOF

# env vars
####

cat <<'EOF' > /tmp/envvars_heredoc

# check for presence of network interface docker0
check_network=$(ifconfig | grep docker0 || true)

# if network interface docker0 is present then we are running in host mode and thus must exit
if [[ ! -z "${check_network}" ]]; then
	echo "[crit] Network type detected as 'Host', this will cause major issues, please stop the container and switch back to 'Bridge' mode" | ts '%Y-%m-%d %H:%M:%.S' && exit 1
fi

export VPN_ENABLED=$(echo "${VPN_ENABLED}" | sed -e 's/^[ \t]*//')
if [[ ! -z "${VPN_ENABLED}" ]]; then
	echo "[info] VPN_ENABLED defined as '${VPN_ENABLED}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[warn] VPN_ENABLED not defined,(via -e VPN_ENABLED), defaulting to 'yes'" | ts '%Y-%m-%d %H:%M:%.S'
	export VPN_ENABLED="yes"
fi

if [[ $VPN_ENABLED == "yes" ]]; then
	export VPN_PROV=$(echo "${VPN_PROV}" | sed -e 's/^[ \t]*//')
	if [[ ! -z "${VPN_PROV}" ]]; then
		echo "[info] VPN_PROV defined as '${VPN_PROV}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[crit] VPN_PROV not defined,(via -e VPN_PROV), exiting..." | ts '%Y-%m-%d %H:%M:%.S' && exit 1
	fi

	export VPN_REMOTE=$(echo "${VPN_REMOTE}" | sed -e 's/^[ \t]*//')
	if [[ ! -z "${VPN_REMOTE}" ]]; then
		echo "[info] VPN_REMOTE defined as '${VPN_REMOTE}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[crit] VPN_REMOTE not defined (via -e VPN_REMOTE), exiting..." | ts '%Y-%m-%d %H:%M:%.S' && exit 1
	fi

	export VPN_PORT=$(echo "${VPN_PORT}" | sed -e 's/^[ \t]*//')
	if [[ ! -z "${VPN_PORT}" ]]; then
		echo "[info] VPN_PORT defined as '${VPN_PORT}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[crit] VPN_PORT not defined (via -e VPN_PORT), exiting..." | ts '%Y-%m-%d %H:%M:%.S' && exit 1
	fi

	export VPN_PROTOCOL=$(echo "${VPN_PROTOCOL}" | sed -e 's/^[ \t]*//')
	if [[ ! -z "${VPN_PROTOCOL}" ]]; then
		echo "[info] VPN_PROTOCOL defined as '${VPN_PROTOCOL}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[crit] VPN_PROTOCOL not defined (via -e VPN_PROTOCOL), exiting..." | ts '%Y-%m-%d %H:%M:%.S' && exit 1
	fi

	export LAN_NETWORK=$(echo "${LAN_NETWORK}" | sed -e 's/^[ \t]*//')
	if [[ ! -z "${LAN_NETWORK}" ]]; then
		echo "[info] LAN_NETWORK defined as '${LAN_NETWORK}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[crit] LAN_NETWORK not defined (via -e LAN_NETWORK), exiting..." | ts '%Y-%m-%d %H:%M:%.S' && exit 1
	fi

	export NAME_SERVERS=$(echo "${NAME_SERVERS}" | sed -e 's/^[ \t]*//')
	if [[ ! -z "${NAME_SERVERS}" ]]; then
		echo "[info] NAME_SERVERS defined as '${NAME_SERVERS}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[warn] NAME_SERVERS not defined (via -e NAME_SERVERS), defaulting to Google and FreeDNS name servers" | ts '%Y-%m-%d %H:%M:%.S'
		export NAME_SERVERS="8.8.8.8,37.235.1.174,8.8.4.4,37.235.1.177"
	fi

	if [[ $VPN_PROV != "airvpn" ]]; then
		export VPN_USER=$(echo "${VPN_USER}" | sed -e 's/^[ \t]*//')
		if [[ ! -z "${VPN_USER}" ]]; then
			echo "[info] VPN_USER defined as '${VPN_USER}'" | ts '%Y-%m-%d %H:%M:%.S'
		else
			echo "[warn] VPN_USER not defined (via -e VPN_USER), assuming authentication via other method" | ts '%Y-%m-%d %H:%M:%.S'
		fi

		export VPN_PASS=$(echo "${VPN_PASS}" | sed -e 's/^[ \t]*//')
		if [[ ! -z "${VPN_PASS}" ]]; then
			echo "[info] VPN_PASS defined as '${VPN_PASS}'" | ts '%Y-%m-%d %H:%M:%.S'
		else
			echo "[warn] VPN_PASS not defined (via -e VPN_PASS), assuming authentication via other method" | ts '%Y-%m-%d %H:%M:%.S'
		fi
	fi

	export VPN_INCOMING_PORT=$(echo "${VPN_INCOMING_PORT}" | sed -e 's/^[ \t]*//')
	if [[ ! -z "${VPN_INCOMING_PORT}" ]]; then
		echo "[info] VPN_INCOMING_PORT defined as '${VPN_INCOMING_PORT}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[warn] VPN_INCOMING_PORT not defined (via -e VPN_INCOMING_PORT), downloads may be slow" | ts '%Y-%m-%d %H:%M:%.S'
		export VPN_INCOMING_PORT=""
	fi

	export VPN_DEVICE_TYPE=$(echo "${VPN_DEVICE_TYPE}" | sed -e 's/^[ \t]*//')
	if [[ ! -z "${VPN_DEVICE_TYPE}" ]]; then
		echo "[info] VPN_DEVICE_TYPE defined as '${VPN_DEVICE_TYPE}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[warn] VPN_DEVICE_TYPE not defined (via -e VPN_DEVICE_TYPE), defaulting to 'tun'" | ts '%Y-%m-%d %H:%M:%.S'
		export VPN_DEVICE_TYPE="tun"
	fi

	export ENABLE_PRIVOXY=$(echo "${ENABLE_PRIVOXY}" | sed -e 's/^[ \t]*//')
	if [[ ! -z "${ENABLE_PRIVOXY}" ]]; then
		echo "[info] ENABLE_PRIVOXY defined as '${ENABLE_PRIVOXY}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[warn] ENABLE_PRIVOXY not defined (via -e ENABLE_PRIVOXY), defaulting to 'no'" | ts '%Y-%m-%d %H:%M:%.S'
		export ENABLE_PRIVOXY="no"
	fi


	
elif [[ $VPN_ENABLED == "no" ]]; then
	echo "[warn] !!IMPORTANT!! You have set the VPN to disabled, you will NOT be secure!" | ts '%Y-%m-%d %H:%M:%.S'
fi

EOF


# cleanup
yes|pacman -Scc
rm -rf /usr/share/locale/*
rm -rf /usr/share/man/*
rm -rf /tmp/*