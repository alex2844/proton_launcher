#!/usr/bin/env bash

########################################################################
##
## Project name: Wine launch wrapper
## Version: 1.3.10
## Author: Kron4ek
## Contact emails: kron4ek@protonmail.com, kron4ek@gmail.com
##
## Links to the latest version and documentation:
##
## Google Drive: https://drive.google.com/open?id=1fTfJQhQSzlEkY-j3g0H6p4lwmQayUNSR
## MEGA: https://mega.nz/folder/oY01CKzD#5VaFPNvaUDT0j39FUqwrdQ
##
## This is a script for creating portable Wine applications. It should
## work on all Linux distributions that have the bash shell and the standard
## GNU utilities. And wget is (optionally) needed for the script to be able
## to download winetricks.
##
########################################################################

## Exit if the script is running with root rights
## If you really need this for some reason and you absolutely know what you
## are doing, then just remove this if block

if [ "$EUID" = 0 ]; then
  echo "Please do not run this script as root!"
  exit 1
fi

## Show available arguments

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
	clear
	echo -e "Available arguments:\n"
	echo -e "--cfg\t\t\t\tRun winecfg"
	echo -e "--reg\t\t\t\tRun regedit"
	echo -e "--fm\t\t\t\tRun Wine file manager"
	echo -e "--kill\t\t\t\tKill all processes running in the prefix"
	echo -e "--tricks\t\t\tRun winetricks with the specified arguments"
	echo -e "\t\t\t\t(for example, ./start.sh --tricks vcrun2015)"
	echo -e "--debug\t\t\t\tShow more information when running Wine"
	echo -e "--steam\t\t\t\tAdd shortcuts to steam"
	echo -e "--shortcuts\t\t\tAdd shortcuts to launch the script on"
	echo -e "\t\t\t\tthe desktop and the applications menu"
	echo -e "\t\t\t\tIf the shortcuts already exist, they will be"
	echo -e "\t\t\t\tremoved."
	echo -e "--clean\t\t\t\tRemove all files and directories"
	echo -e "\t\t\t\t(except the settings_* and winetricks)"
	echo -e "\t\t\t\tcreated by the script."
	echo -e "\t\t\t\tThis will likely remove all game settings and"
	echo -e "\t\t\t\tsaves. Use with caution!"
	echo -e "\nAll other arguments that don't match any of the above"
	echo "will be passed to the game itself."

	exit
fi

export script="$(readlink -f "${BASH_SOURCE[0]}")"
export scriptdir="$(dirname "$script")"

cd "${scriptdir}" || exit 1

## Set path to Wine binaries

export WINE="${scriptdir}"/wine/bin/wine
export WINE64="${scriptdir}"/wine/bin/wine64
export WINESERVER="${scriptdir}"/wine/bin/wineserver
export USE_SYSTEM_WINE=0

## Set path to Wine prefix

export WINEPREFIX="${scriptdir}"/prefix

## By default, when the script recreates the prefix, it renames the old
## prefix to WINEPREFIX_old_DATE. This is useful because the old prefix may
## contain important information that you might want to move to the new
## prefix manually.
##
## Enable this variable to just remove old prefixes instead of
## renaming them.

export REMOVE_OLD_PREFIXES=0

## Set path to the documents directory
## This directory will be used to store games saves and settings
## Except when the game stores its saves in its own directory

export DOCUMENTS_DIR="${scriptdir}"/documents

## Set prefix architecture
## win64 for 64-bit apps, win32 for 32-bit apps
## Even though win64 can run 32-bit apps too, the script expects that
## you will use win32 for 32-bit apps

export WINEARCH=win64

## Disable Wine debug

export WINEDEBUG="-all"

## Set Windows version
## Available values: winxp, win7, win8, win10, default.
## This only has effect during the prefix (re)creation

export WINDOWS_VERSION=default

## Enable this only if Wine hangs when creating prefix
## You need to remove the prefix directory after enabling this
## Workaround for the bug: https://bugs.winehq.org/show_bug.cgi?id=51086

export PREFIX_HANG_FIX=0

## Enable ESYNC/FSYNC
## It's safe to enable both of them simultaneously
## Wine will prefer FSYNC if it's supported by kernel, otherwise it will
## use ESYNC
##
## FUTEX2 depends on FSYNC. If you disable FSYNC, then FUTEX2 won't work too
## FUTEX2 may cause issues in some games

export WINEESYNC=1
export WINEFSYNC=1
export WINEFSYNC_FUTEX2=0

## Enable LARGE_ADDRESS_AWARE
## Useful for 32-bit games hitting address space limitations

export WINE_LARGE_ADDRESS_AWARE=1

## Enable AMD FidelityFX Super Resolution (FSR)

export WINE_FULLSCREEN_FSR=1
export WINE_FULLSCREEN_FSR_STRENGTH=2

## Disable pesky winemenubuilder which pollutes application menus

export WINEDLLOVERRIDES="winemenubuilder.exe="

## Set the cache directory

export XDG_CACHE_HOME="${scriptdir}"/cache

## Nvidia variables

export __GL_SHADER_DISK_CACHE_SIZE=2147483648
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
export __GL_SHADER_DISK_CACHE_PATH="${XDG_CACHE_HOME}"/nvidia

## DXVK variables

export DXVK_LOG_PATH="${XDG_CACHE_HOME}"/dxvk
export DXVK_STATE_CACHE_PATH="${XDG_CACHE_HOME}"/dxvk
export DXVK_CONFIG_FILE="${scriptdir}"/dxvk.conf
export DXVK_LOG_LEVEL=none
export DXVK_HUD=0
export DISABLE_DXVK=0
#export DXVK_STATE_CACHE=0
#export DXVK_FRAME_RATE=60

## This variable works only with DXVK with the async patch applied

export DXVK_ASYNC=1

## VKD3D variables

export USE_BUILTIN_VKD3D=0
export VKD3D_DEBUG=none
export VKD3D_SHADER_DEBUG=none

## Wine-Staging variables

export STAGING_SHARED_MEMORY=1
#export STAGING_WRITECOPY=1

## Set realtime priority for the wineserver
## This usually improves performance
## 99 is the highest, but is not recommended.
##
## This requires the ability to set realtime priorities for processes
## This ability can be configured in /etc/security/limits.conf

#export STAGING_RT_PRIORITY_SERVER=90

## Set priority for the application
## This usually improves performance
## -20 is the highest priority, 19 is the lowest.
##
## This requires the ability to increase priorities for processes
## This ability can be configured in /etc/security/limits.conf

#export NICE_LEVEL="-4"

## If this is enabled, the script will store the Wine prefix and the documents
## directory in /home/username/.local/share/games/GAMENAME
##
## Enable this if you are using NTFS filesystem and encounter problems
## starting the game.

export NTFS_MODE=0

## File descriptors limit for Esync
## Values lower than 1 million are not recommended
## ESYNC will be automatically disabled by the script if ulimit
## fails to set the required limit
##
## This requires the ability to increase file descriptors limit
## This ability can be configured in /etc/security/limits.conf

export ULIMIT_SIZE=1000000

## Enable Wine virtual desktop

export VIRTUAL_DESKTOP=0
export VIRTUAL_DESKTOP_SIZE="1280x720"

## Restore screen resolution after Wine terminates

export RESTORE_RESOLUTION=1

## Set the locale. This is useful for games that set their language
## depending on the system locale being used.

#export LANG=ru_RU.UTF-8

## Useful when a game doesn't work

export ENABLE_DEBUG=0

## Disable dlls. Comma separated list.

#export DISABLE_DLLS="winegstreamer,d3d12"

## May be useful for games with native OpenGL renderer
## The first variable is for Nvidia GPUs
## And the second is for AMD/Intel GPUs

#export __GL_THREADED_OPTIMIZATIONS=1
#export mesa_glthread=true

## Make Wine binaries executable

if [ -f "${WINE}" ] && [ ! -x "${WINE}" ]; then
	chmod +x "${WINE}"
fi

if [ -f "${WINE64}" ] && [ ! -x "${WINE64}" ]; then
	chmod +x "${WINE64}"
fi

if [ -f "${WINESERVER}" ] && [ ! -x "${WINESERVER}" ]; then
	chmod +x "${WINESERVER}"
fi

## If a Wine build is fully 64-bit, make a symlink from wine64 to wine

if [ ! -f "${WINE}" ] && [ -f "${WINE64}" ]; then
	ln -sr "${WINE64}" "${WINE}"
	export WINE="${WINE64}"
fi

script_name="$(basename "${script}" | cut -d. -f1)"
settings_file=settings_"${script_name}"

## Generate settings file

if [ ! -f "${settings_file}" ]; then
	cat <<EOF > "${settings_file}"
export USE_SYSTEM_WINE=${USE_SYSTEM_WINE}
export RESTORE_RESOLUTION=${RESTORE_RESOLUTION}
export VIRTUAL_DESKTOP=${VIRTUAL_DESKTOP}
export VIRTUAL_DESKTOP_SIZE="${VIRTUAL_DESKTOP_SIZE}"
export DISABLE_DXVK=${DISABLE_DXVK}
export DXVK_HUD=${DXVK_HUD}
export USE_BUILTIN_VKD3D=${USE_BUILTIN_VKD3D}
export ENABLE_DEBUG=${ENABLE_DEBUG}
export STAGING_SHARED_MEMORY=${STAGING_SHARED_MEMORY}
#export STAGING_WRITECOPY=1
#export DXVK_STATE_CACHE=0
#export DXVK_FRAME_RATE=60

## Enable ESYNC/FSYNC
## It's safe to enable both of them simultaneously
## Wine will prefer FSYNC if it's supported by kernel, otherwise it will
## use ESYNC
##
## FUTEX2 depends on FSYNC. If you disable FSYNC, then FUTEX2 won't work too
## FUTEX2 may cause issues in some games

export WINEESYNC=${WINEESYNC}
export WINEFSYNC=${WINEFSYNC}
export WINEFSYNC_FUTEX2=${WINEFSYNC_FUTEX2}

## Enable LARGE_ADDRESS_AWARE
## Useful for 32-bit games hitting address space limitations

export WINE_LARGE_ADDRESS_AWARE=${WINE_LARGE_ADDRESS_AWARE}

## Enable AMD FidelityFX Super Resolution (FSR)

export WINE_FULLSCREEN_FSR=${WINE_FULLSCREEN_FSR}
export WINE_FULLSCREEN_FSR_STRENGTH=${WINE_FULLSCREEN_FSR_STRENGTH}

## Enable this only if Wine hangs when creating prefix
## You need to remove the prefix directory after enabling this
## Workaround for the bug: https://bugs.winehq.org/show_bug.cgi?id=51086

export PREFIX_HANG_FIX=${PREFIX_HANG_FIX}

## This variable works only with DXVK with the async patch applied

export DXVK_ASYNC=${DXVK_ASYNC}

## Set realtime priority for the wineserver
## This usually improves performance
## 99 is the highest, but is not recommended.
##
## This requires the ability to set realtime priorities for processes
## This ability can be configured in /etc/security/limits.conf

#export STAGING_RT_PRIORITY_SERVER=90

## Set priority for the application
## This usually improves performance
## -20 is the highest priority, 19 is the lowest.
##
## This requires the ability to increase priorities for processes
## This ability can be configured in /etc/security/limits.conf

#export NICE_LEVEL="-4"

## Set prefix architecture
## win64 for 64-bit apps, win32 for 32-bit apps
## Even though win64 can run 32-bit apps too, the script expects that
## you will use win32 for 32-bit apps

export WINEARCH=${WINEARCH}

## Set Windows version
## Available values: winxp, win7, win8, win10, default.
## This only has effect during the prefix (re)creation

export WINDOWS_VERSION=${WINDOWS_VERSION}

## Disable dlls. Comma separated list.

#export DISABLE_DLLS="winegstreamer,d3d12"

## If this is enabled, the script will store the Wine prefix and the documents
## directory in /home/username/.local/share/games/GAMENAME
##
## Enable this if you are using NTFS filesystem and encounter problems
## starting the game.

export NTFS_MODE=${NTFS_MODE}

## Set the locale. This is useful for games that set their language
## depending on the system locale being used.

#export LANG=ru_RU.UTF-8

## File descriptors limit for Esync
## Values lower than 1 million are not recommended
## ESYNC will be automatically disabled by the script if ulimit
## fails to set the required limit
##
## This requires the ability to increase file descriptors limit
## This ability can be configured in /etc/security/limits.conf

export ULIMIT_SIZE=${ULIMIT_SIZE}

## You can also put any custom environment variables in this file.
EOF
fi

source "${settings_file}"

if [ -n "${DISABLE_DLLS}" ]; then
	export WINEDLLOVERRIDES="${DISABLE_DLLS}=;${WINEDLLOVERRIDES}"
fi

if [ -n "${STEAM_COMPAT_TOOL_PATHS}" ]; then
	proton="${STEAM_COMPAT_TOOL_PATHS%%:*}"
	if [ -f "${proton}/dist/bin/wine" ]; then
		export WINE="${proton}/dist/bin/wine"
	elif [ -f "${proton}/files/bin/wine" ]; then
		export WINE="${proton}/files/bin/wine"
	fi
	if [ -f "${proton}/dist/bin/wine64" ]; then
		export WINE64="${proton}/dist/bin/wine64"
	elif [ -f "${proton}/files/bin/wine64" ]; then
		export WINE64="${proton}/files/bin/wine64"
	fi
	if [ -f "${proton}/dist/bin/wineserver" ]; then
		export WINESERVER="${proton}/dist/bin/wineserver"
	elif [ -f "${proton}/files/bin/wineserver" ]; then
		export WINESERVER="${proton}/files/bin/wineserver"
	fi
fi

## Use system Wine if needed

if [ ! -f "${WINE}" ] || [ "${USE_SYSTEM_WINE}" = 1 ]; then
	export WINE=wine
	export WINE64=wine64
	export WINESERVER=wineserver

	USE_SYSTEM_WINE=1
fi

## Check if the Wine binary works at all

if ! "${WINE}" --version &>/dev/null; then
	echo "There is a problem running Wine binary!"
	exit 1
fi

## Disable ESYNC if ulimit fails to set the required limit

if ! ulimit -n ${ULIMIT_SIZE} 2>/dev/null; then
	export WINEESYNC=0
fi

## Disable restoring screen resolution if there is no xrandr

if ! command -v xrandr 1>/dev/null; then
	export RESTORE_RESOLUTION=0
fi

## Check if sed is installed

if ! command -v sed 1>/dev/null; then
	echo "Please install sed and run the script again."
	exit 1
fi

## Use the game_info_SCRIPTNAME.txt file if it exists
## Otherwise use the game_info.txt file

if [ -f "${scriptdir}"/game_info/game_info_"${script_name}".txt ]; then
	GAME_INFO="$(cat "${scriptdir}"/game_info/game_info_"${script_name}".txt)"
elif [ -f "${scriptdir}"/game_info/game_info.txt ]; then
	GAME_INFO="$(cat "${scriptdir}"/game_info/game_info.txt)"
fi

if [ -z "${GAME_INFO}" ]; then
	clear
	echo "There is no game_info.txt file!"
	exit 1
fi

GAME="$(echo "${GAME_INFO}" | sed -n 6p)"
VERSION="$(echo "${GAME_INFO}" | sed -n 2p)"
ADDITIONAL_PATH="$(echo "${GAME_INFO}" | sed -n 5p)"
EXE="$(echo "${GAME_INFO}" | sed -n 3p)"
ARGS="$(echo "${GAME_INFO}" | sed -n 4p)"
ARGV=("$@")

if [[ "${ARGV[@]}" =~ ' -- ' ]]; then
	last_index=$(printf '%s\n' "${ARGV[@]}" | grep -n "\-\-" | tail -n 1 | cut -d ':' -f 1)
	if [ -n "$last_index" ]; then
		if [ -n "${STEAM_COMPAT_DATA_PATH}" ]; then
			if [ -z "${EXE}" ]; then
				EXE="${ARGV[$last_index+2]}"
			fi
			LAUNCH=("${ARGV[@]:0:$last_index-3}")
			ARGV=("${ARGV[@]:$last_index+3}")
		else
			if [ -z "${EXE}" ]; then
				EXE="${ARGV[$last_index]}"
			fi
			LAUNCH=("${ARGV[@]:0:$last_index}")
			ARGV=("${ARGV[@]:$last_index+1}")
		fi
	fi
fi
if [ -n "${STEAM_COMPAT_DATA_PATH}" ]; then
	if [ ! -d "${STEAM_COMPAT_DATA_PATH}" ]; then
		mkdir -p "${STEAM_COMPAT_DATA_PATH}"
	fi
	export WINEPREFIX="${STEAM_COMPAT_DATA_PATH}/pfx"
	export REMOVE_OLD_PREFIXES=1
elif [ "${NTFS_MODE}" = 1 ]; then
	mkdir -p "${HOME}"/.local/share/games/"${GAME}"

	export WINEPREFIX="${HOME}"/.local/share/games/"${GAME}"/prefix
	export DOCUMENTS_DIR="${HOME}"/.local/share/games/"${GAME}"/documents
fi

## Function for retreiving a list of files of the game_info directory
## When the list of files changes, the WINEPREFIX is recreated

list_game_info_content() {
	for dir in game_info/*/; do
		if [ "${dir}" != "game_info/data/" ]; then
			GAME_INFO_CONTENT="$(ls "${dir}" 2>/dev/null) ${GAME_INFO_CONTENT}"
		fi
	done
}

get_steam_shortcuts_path() {
	ls -lt "$HOME/.local/share/Steam/userdata/"*"/config/shortcuts.vdf" 2>/dev/null | head -n 1 | awk '{print $NF}'
}

get_steam_appid() {
	if [ -f "${scriptdir}/game_info/steam_appid.txt" ]; then
		cat "${scriptdir}/game_info/steam_appid.txt"
	elif [ -f "${scriptdir}/game_info/data/steam_appid.txt" ]; then
		cat "${scriptdir}/game_info/data/steam_appid.txt"
	elif [ -f "${scriptdir}/game_info/data/steam_settings/steam_appid.txt" ]; then
		cat "${scriptdir}/game_info/data/steam_settings/steam_appid.txt"
	fi
}

download_image() {
	if [[ "$2" == *.ico ]]; then
		wget -qO "$2" "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/$1"
	else
		wget -qO "$2" "https://cdn.cloudflare.steamstatic.com/steam/apps/$1"
	fi
}

download_icon() {
	if [ -n "$1" ]; then
		content=$(wget -qO- --referer="https://www.steamgriddb.com/game/$1" "https://www.steamgriddb.com/api/public/game/$1")
	fi
	if [ -n "${content}" ]; then
		content=$(printf "%s" "$content" | python -c 'import sys, json; steam = json.load(sys.stdin)["data"]["platforms"]["steam"]; print(steam["id"]+"/"+steam["metadata"]["clienticon"]+".ico")')
		if [ -n "${content}" ]; then
			download_image "${content}" "${scriptdir}/game_info/icon.ico"
		fi
	elif [ -n "$2" ]; then
		content=$(wget -qO- "https://www.steamgriddb.com/api/public/search/autocomplete/?term=$2")
		content=$(printf "%s" "$content" | python -c 'import sys, json; print(json.load(sys.stdin)["data"][0]["id"])')
		if [ -n "${content}" ]; then
			download_icon "${content}"
		fi
	fi
}

## A function to download winetricks
## It's only used if the winetricks_list.txt file exists
## Or if the script is launched with the --tricks argument

download_winetricks() {
	unset missing_deps
	winetricks_deps="wget cabextract"

	for i in ${winetricks_deps}; do
		if ! command -v ${i} 1>/dev/null; then
			missing_deps="${i} ${missing_deps}"
		fi
	done

	if [ -n "${missing_deps}" ]; then
		echo "Please install these packages: ${missing_deps}"
		echo "After that run the script again"
		return 1
	fi

	if [ ! -s winetricks ]; then
		rm -f winetricks

		echo "Downloading winetricks..."
		wget -q -O winetricks "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
	fi

	if [ -s winetricks ]; then
		if [ ! -x winetricks ]; then
			chmod +x winetricks
		fi

		if [ ! -L "${XDG_CACHE_HOME}"/winetricks ]; then
			if [ -d "${XDG_CACHE_HOME}"/winetricks ]; then
				rm -rf "${XDG_CACHE_HOME}"/winetricks
			fi

			mkdir -p "${XDG_CACHE_HOME}"
			mkdir -p winetricks_cache
			ln -sr winetricks_cache "${XDG_CACHE_HOME}"/winetricks
		fi

		return 0
	else
		echo "winetricks is missing"
		echo "Perhaps you have no internet connection"
		return 1
	fi
}

prefix_init_error() {
		clear
		echo "There is a problem initializing the Wine prefix!"
		echo "If you are using NTFS this might be the reason."
		echo
		echo "Check temp_files/wineboot.log for more information."

		rm -rf "${WINEPREFIX}"
		exit 1
}

get_system_info() {
	rm -f temp_files/sysinfo

	ldd --version &>>temp_files/sysinfo
	echo >>temp_files/sysinfo

	if command -v inxi 1>/dev/null; then
		inxi -b &>>temp_files/sysinfo
		echo >>temp_files/sysinfo
	else
		uname -a &>>temp_files/sysinfo
		echo >>temp_files/sysinfo

		if command -v lspci 1>/dev/null; then
			lspci | grep VGA &>>temp_files/sysinfo
			echo >>temp_files/sysinfo
		fi

		if [ -f /etc/os-release ]; then
			cat /etc/os-release >>temp_files/sysinfo
			echo >>temp_files/sysinfo
		fi

		if [ -f /etc/lsb-release ]; then
			cat /etc/lsb-release >>temp_files/sysinfo
			echo >>temp_files/sysinfo
		fi
	fi

	if command -v glxinfo 1>/dev/null; then
		glxinfo -B &>>temp_files/sysinfo
		echo >>temp_files/sysinfo
	fi

	if command -v vulkaninfo 1>/dev/null; then
		vulkaninfo --summary &>>temp_files/sysinfo
		echo >>temp_files/sysinfo
	fi
}

## Check the launch arguments

if [ "$1" = "--clean" ]; then
	rm -rf cache
	rm -rf "${DOCUMENTS_DIR}"
	rm -rf "${WINEPREFIX}"
	rm -rf "${WINEPREFIX}"_old_*
	rm -rf temp_files

	echo "Files have been removed!"
	exit
fi

if [ "$1" = "--steam" ]; then
	shortcuts_path=$(get_steam_shortcuts_path)
	if [ -z "${shortcuts_path}" ]; then
		clear
		echo "shortcuts.vdf not found!"
		exit 1
	fi
	steam_appid=$(get_steam_appid)
	gamedir="${scriptdir}/game_info/data"
	if [ -n "${ADDITIONAL_PATH}" ]; then
		gamedir="${gamedir}/${ADDITIONAL_PATH}"
	fi
	if [ ! -f "${scriptdir}/game_info/icon.ico" ]; then
		download_icon "${steam_appid}" "${GAME}"
	fi
	if [ ! -f "${scriptdir}/libVDF.py" ]; then
		wget -qO "${scriptdir}/libVDF.py" "https://raw.githubusercontent.com/alex2844/proton_launcher/master/libVDF.py"
	fi
	appid=$(python "${scriptdir}/libVDF.py" "${shortcuts_path}" "${GAME}" "${gamedir}/${EXE}" "${gamedir}" "${scriptdir}/game_info/icon.ico" "" "${script} %command%" 0 1 1 0 0 "" | awk -F': ' '{print $2}')
	mkdir -p "${scriptdir}/temp_files"
	echo "${appid}" > "${scriptdir}/temp_files/appid"
	if [ -n "${steam_appid}" ]; then
		grid_path="$(dirname "$shortcuts_path")/grid"
		download_image "${steam_appid}/header.jpg" "${grid_path}/${appid}.jpg"
		download_image "${steam_appid}/library_600x900_2x.jpg" "${grid_path}/${appid}p.jpg"
		download_image "${steam_appid}/library_hero.jpg" "${grid_path}/${appid}_hero.jpg"
		download_image "${steam_appid}/logo.png" "${grid_path}/${appid}_logo.png"
	fi
	echo 'Please restart steam client'
	exit
fi

if [ "$1" = "--shortcuts" ]; then
	desktop_icon="${HOME}"/Desktop/"${GAME}".desktop
	menu_icon="${HOME}"/.local/share/applications/"${GAME}".desktop

	if [ -f "${desktop_icon}" ] || [ -f "${menu_icon}" ]; then
		rm -f "${desktop_icon}"
		rm -f "${menu_icon}"

		echo "Shortcuts have been removed!"
	else
		if [ ! -f "${scriptdir}/game_info/icon.ico" ]; then
			download_icon "$(get_steam_appid)" "${GAME}"
		fi
		cat <<EOF > game.desktop
[Desktop Entry]
Version=1.0
Name=${GAME}
Type=Application
Terminal=false
Exec="${scriptdir}/start.sh"
Icon=${scriptdir}/game_info/icon.ico
EOF

		mkdir -p "${HOME}"/Desktop
		mkdir -p "${HOME}"/.local/share/applications

		cp game.desktop "${desktop_icon}"
		cp game.desktop "${menu_icon}"
		rm -f game.desktop

		echo "Shortcuts have been added!"
	fi

	exit
fi

## Exit if user have no write permissions on the current directory

if ! touch write_test; then
	clear
	echo "You have no write permissions on this directory!"
	exit 1
fi
rm -f write_test

WINE_VERSION="$("${WINE}" --version 2>/dev/null)"

list_game_info_content

## If the USER environment variable is empty (which is unlikely),
## get the username using the id command

if [ -z "${USER}" ]; then
	USER="$(id -un)"
fi

## Create or recreate the prefix
## WINEPREFIX will be automatically (re)created in these cases:
##
## If the WINEPREFIX directory doesn't exist
## If the DOCUMENTS_DIR directory doesn't exist
## If the content of the game_info directory has changed since the last launch
## If the username has changed since the last launch
## If the Wine version has changed since the last launch

if [ ! -d "${WINEPREFIX}" ] || [ ! -d "${DOCUMENTS_DIR}" ] \
	|| [ "${USER}" != "$(cat temp_files/lastuser 2>/dev/null)" ] \
	|| [ "${WINE_VERSION}" != "$(cat temp_files/lastwine 2>/dev/null)" ] \
	|| [ "${GAME_INFO_CONTENT}" != "$(cat temp_files/last_game_info_files 2>/dev/null)" ]; then

	## Disable WINEESYNC and WINEFSYNC temporarily when creating a prefix

	WINEESYNC_VALUE="${WINEESYNC}"
	WINEFSYNC_VALUE="${WINEFSYNC}"
	export WINEESYNC=0
	export WINEFSYNC=0

	mkdir -p temp_files

	if [ "${REMOVE_OLD_PREFIXES}" = 1 ]; then
		rm -rf "${WINEPREFIX}"
	else
		mv "${WINEPREFIX}" "${WINEPREFIX}"_old_"$(date '+%d.%m_%H:%M:%S')" 2>/dev/null
	fi

	unset disable_wine_gst
	if [ "${PREFIX_HANG_FIX}" = 1 ]; then
		disable_wine_gst="winegstreamer,"
	fi

	echo "Creating prefix"
	export WINEDEBUG="err+all,fixme+all"
	WINEDLLOVERRIDES="${disable_wine_gst}mscoree,mshtml=;${WINEDLLOVERRIDES}" "${WINE}" wineboot &>temp_files/wineboot.log || prefix_init_error
	export WINEDEBUG="-all"
	"${WINESERVER}" -w

	## Valve's Proton always uses steamuser as a username
	## Given this we can determine if Proton is being used instead of
	## regular Wine

	if [ -d "${WINEPREFIX}"/drive_c/users/steamuser ]; then
		USERNAME="steamuser"
	else
		USERNAME="${USER}"
	fi

	## Sandbox the prefix; Partially borrowed from the winetricks script
	## And move the user's directory outside the prefix

	rm -f "${WINEPREFIX}"/dosdevices/*
	ln -sr "${WINEPREFIX}"/drive_c "${WINEPREFIX}"/dosdevices/c:
	ln -sr "${scriptdir}" "${WINEPREFIX}"/dosdevices/k:

	"${WINE}" regedit /D "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Desktop\\Namespace\\{9D20AAE8-0625-44B0-9CA7-71889C2254D9}" &>/dev/null
	echo disable > "${WINEPREFIX}"/.update-timestamp

	if [ ! -d "${DOCUMENTS_DIR}" ]; then
		if cd "${WINEPREFIX}"/drive_c/users/"${USERNAME}"; then
			## Use one directory (Documents_Multilocale) for all symlinks
			## This is necessary for multilocale compatibility

			mkdir -p Documents_Multilocale

			for x in *; do
				if test -h "${x}" && test -d "${x}"; then
					rm -f "${x}"
					ln -sr Documents_Multilocale "${x}"
				fi
			done
		fi
		cd "${scriptdir}"

		mv "${WINEPREFIX}"/drive_c/users/"${USERNAME}" "${DOCUMENTS_DIR}"
		mv "${WINEPREFIX}"/drive_c/users/Public "${DOCUMENTS_DIR}"/Public
		mv "${WINEPREFIX}"/drive_c/ProgramData "${DOCUMENTS_DIR}"/ProgramData
	fi

	rm -rf "${WINEPREFIX}"/drive_c/users/"${USERNAME}"
	rm -rf "${WINEPREFIX}"/drive_c/users/Public
	rm -rf "${WINEPREFIX}"/drive_c/ProgramData
	ln -sr "${DOCUMENTS_DIR}" "${WINEPREFIX}"/drive_c/users/"${USERNAME}"
	ln -sr "${DOCUMENTS_DIR}"/Public "${WINEPREFIX}"/drive_c/users/Public
	ln -sr "${DOCUMENTS_DIR}"/ProgramData "${WINEPREFIX}"/drive_c/ProgramData

	## Change My Documents directory to Documents_Multilocale via registry
	## This is mostly useful for Proton as it doesn't create symlinks
	## in the user's directory in Wine prefix, so we can't just redirect symlinks.

	"${WINE}" reg add 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' \
	/v "Personal" /t REG_EXPAND_SZ /d "%USERPROFILE%\Documents_Multilocale" /f &>/dev/null

	## Execute winetricks actions from the winetricks_list.txt file

	if [ -f game_info/winetricks_list.txt ]; then
		if download_winetricks; then
			echo "Executing winetricks"

			"${scriptdir}"/winetricks -q $(cat game_info/winetricks_list.txt) &>/dev/null
			"${WINESERVER}" -w
		else
			rm -rf "${WINEPREFIX}"
			exit 1
		fi
	fi

	## Execute files in the game_info/exe directory using Wine

	if [ -d game_info/exe ]; then
		echo "Executing files"

		for file in game_info/exe/*; do
			"${WINE}" start "${file}" &>/dev/null
			"${WINESERVER}" -w
		done
	fi

	## Import reg files

	if [ -d game_info/regs ]; then
		echo "Importing registry files"

		for file in game_info/regs/*; do
			"${WINE}" regedit "${file}" &>/dev/null
			"${WINE64}" regedit "${file}" &>/dev/null
		done
	fi

	## Override dlls

	if [ -d game_info/dlls ]; then
		echo "Overriding dlls"

		for x in game_info/dlls/*; do
			echo "${x}" >> "${scriptdir}"/temp_files/dlls
			rm -f "${WINEPREFIX}"/drive_c/windows/system32/"$(basename "${x}")"
			ln -sr "${scriptdir}"/"${x}" "${WINEPREFIX}"/drive_c/windows/system32

			"${WINE}" reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v \
			"$(basename "${x}" .dll)" /d native /f &>/dev/null

			"${WINE}" regsvr32 "$(basename $x)"  &>/dev/null
			"${WINE64}" regsvr32 "$(basename $x)"  &>/dev/null
		done
	fi

	## Copy the content of the additional directory

	if [ -d game_info/additional ]; then
		echo "Copying additional files"

		if [ -d game_info/additional/prefix ]; then
			for f in game_info/additional/prefix/*; do
				cp -r "${f}" "${WINEPREFIX}"
			done
		fi

		if [ -d game_info/additional/documents ]; then
			for f in game_info/additional/documents/*; do
				cp -r "${f}" "${DOCUMENTS_DIR}"
			done
		fi
	fi

	## Execute scripts in the game_info/sh directory

	if [ -d game_info/sh ]; then
		echo "Executing scripts"

		chmod -R 700 game_info/sh
		for file in game_info/sh/*; do
			"${file}"
		done
	fi

	## Set Windows version

	if [ -n "${WINDOWS_VERSION}" ] && [ "${WINDOWS_VERSION}" != "default" ]; then
		if [ "${WINDOWS_VERSION}" = "winxp" ]; then
			"${WINE}" winecfg /v winxp &>/dev/null
			"${WINE}" winecfg /v winxp64 &>/dev/null
		else
			"${WINE}" winecfg /v "${WINDOWS_VERSION}" &>/dev/null
		fi
	fi

	## Enable debug during the first run

	export ENABLE_DEBUG=1

	## Wait for all Wine processes to terminate

	"${WINESERVER}" -w
	sleep 1

	## Save the information about the system, the username, the Wine version and
	## the list of files of the game_info directory
	## This is needed to know when to recreate the prefix

	get_system_info
	echo "${USER}" > temp_files/lastuser
	echo "${WINE_VERSION}" > temp_files/lastwine
	echo "${GAME_INFO_CONTENT}" > temp_files/last_game_info_files

	export WINEESYNC="${WINEESYNC_VALUE}"
	export WINEFSYNC="${WINEFSYNC_VALUE}"
fi

## Check the launch arguments

if [ "$1" = "--cfg" ]; then
	"${WINE}" winecfg
	exit
elif [ "$1" = "--reg" ]; then
	"${WINE}" regedit
	exit
elif [ "$1" = "--fm" ]; then
	"${WINE}" winefile
	exit
elif [ "$1" = "--kill" ]; then
	"${WINESERVER}" -k

	echo "All processes in the prefix have been killed!"
	exit
elif [ "$1" = "--tricks" ]; then
	if download_winetricks; then
		shift
		"${scriptdir}"/winetricks "$@"
		"${WINESERVER}" -w
	fi

	exit
elif [ "$1" = "--debug" ]; then
	export ENABLE_DEBUG=1
	shift
fi

## Disable DXVK if the appropriate variable is enabled
## Otherwise disable nvapi as it doesn't work with DXVK

if [ "${DISABLE_DXVK}" = 1 ]; then
	export WINEDLLOVERRIDES="dxgi,d3d9,d3d10,d3d10_1,d3d10core,d3d11=b;${WINEDLLOVERRIDES}"
else
	export WINEDLLOVERRIDES="nvapi,nvapi64=;${WINEDLLOVERRIDES}"
fi

## Use builtin VKD3D instead of external VKD3D-proton if the appropriate
## variable is enabled

if [ "${USE_BUILTIN_VKD3D}" = 1 ]; then
	export WINEDLLOVERRIDES="dxgi,d3d12=b;${WINEDLLOVERRIDES}"
fi

## Enable virtual desktop if the appropriate variable is enabled

if [ "${VIRTUAL_DESKTOP}" = 1 ]; then
	VDESKTOP="explorer /desktop=Wine,${VIRTUAL_DESKTOP_SIZE}"
fi

if [ -f temp_files/enable_debug ]; then
	rm temp_files/enable_debug
	ENABLE_DEBUG=1
fi

## Enable debug if the appropriate variable is enabled

if [ "${ENABLE_DEBUG}" = 1 ]; then
	export WINEDEBUG="err+all,fixme+all"
	unset DXVK_LOG_LEVEL
	unset VKD3D_DEBUG
	unset VKD3D_SHADER_DEBUG
fi

## Get screen resolution if the appropriate variable is enabled

if [ "${RESTORE_RESOLUTION}" = 1 ]; then
	## If there are multiple monitors connected, get resolution of primary monitor

	SCREEN_RESOLUTION="$(xrandr -q | sed -n -e 's/.* connected primary \([^ +]*\).*/\1/p')"
	SCREEN_OUTPUT="$(xrandr -q | sed -n -e 's/\([^ ]*\) connected primary.*/\1/p')"

	## If there is only one monitor, then xrandr doesn't mark it as "primary"
	## So it's necessary to handle its output slightly differently

    if [ -z "${SCREEN_RESOLUTION}" ] || [ -z "${SCREEN_OUTPUT}" ]; then
		SCREEN_RESOLUTION="$(xrandr -q | sed -n -e 's/.* connected \([^ +]*\).*/\1/p')"
		SCREEN_OUTPUT="$(xrandr -q | sed -n -e 's/\([^ ]*\) connected.*/\1/p')"
	fi
fi

## Execute everytime scripts

if [ -d game_info/sh/everytime ]; then
	echo "Executing everytime scripts"

	chmod -R 700 game_info/sh/everytime
	for file in game_info/sh/everytime/*; do
		"${file}"
	done
fi

## Unset SDL_AUDIODRIVER, becuase it causes issues for Windows games when
## set to a driver not available on Windows (alsa, pulse)

unset SDL_AUDIODRIVER

## Show some info

clear
echo "========================================================================"
echo "Game: ${GAME}"
echo "Version: ${VERSION}"
echo -n "Wine: ${WINE_VERSION}"

if [ "${USE_SYSTEM_WINE}" = 1 ]; then
	echo -n " (using system Wine)"
fi
echo

if [ -n "${ARGS}" ] || [ -n "$1" ]; then
	echo "Launch arguments: ${ARGS} ${ARGV[@]}"
fi

if [ -f game_info/dlls/d3d9.dll ] || [ -f game_info/dlls/d3d11.dll ]; then
	if [ "${DISABLE_DXVK}" != 1 ]; then
		echo "DXVK: enabled"
	else
		echo "DXVK: disabled"
	fi
fi

if [ -f game_info/dlls/d3d12.dll ]; then
	if [ "${USE_BUILTIN_VKD3D}" != 1 ]; then
		echo "VKD3D: external (vkd3d-proton)"
	else
		echo "VKD3D: builtin"
	fi
fi

if [ -n "${DISABLE_DLLS}" ]; then
	echo "Disabled DLLs: ${DISABLE_DLLS}"
fi

echo "========================================================================"
echo

env > "${scriptdir}"/temp_files/env
if [ -n "${NICE_LEVEL}" ] && [ "${NICE_LEVEL}" != 0 ]; then
	echo nice -n "${NICE_LEVEL}" "${LAUNCH[@]}" "${WINE}" ${VDESKTOP} "${EXE}" ${ARGS} "${ARGV[@]}" > "${scriptdir}"/temp_files/exec
else
	echo "${LAUNCH[@]}" "${WINE}" ${VDESKTOP} "${EXE}" ${ARGS} "${ARGV[@]}" > "${scriptdir}"/temp_files/exec
fi
for arg in "$@"; do
    echo "$arg" >> "${scriptdir}"/temp_files/exec
done
## Launch the game

cd "${scriptdir}"/game_info/data/"${ADDITIONAL_PATH}" || exit 1

if [ -n "${NICE_LEVEL}" ] && [ "${NICE_LEVEL}" != 0 ]; then
	nice -n "${NICE_LEVEL}" "${LAUNCH[@]}" "${WINE}" ${VDESKTOP} "${EXE}" ${ARGS} "${ARGV[@]}"
else
	"${LAUNCH[@]}" "${WINE}" ${VDESKTOP} "${EXE}" ${ARGS} "${ARGV[@]}"
fi

## If the game or Wine fails, enable debug for the next launch

if [ $? -ne 0 ]; then
    echo > "${scriptdir}"/temp_files/enable_debug
fi

"${WINESERVER}" -w

## Restore screen resolution

if [ "${RESTORE_RESOLUTION}" = 1 ]; then
	xrandr --output "${SCREEN_OUTPUT}" --mode "${SCREEN_RESOLUTION}" &>/dev/null
	xgamma -gamma 1.0 &>/dev/null
fi
