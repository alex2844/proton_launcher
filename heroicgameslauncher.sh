#!/usr/bin/env bash

path="$HOME/.var/app/com.heroicgameslauncher.hgl";
accounts=()

mkdir -p "${path}"
cd "${path}"

function show_input_dialog() {
	input=$(zenity --entry --title="Account" --text="Input name account:")
    if [[ -n $input ]]; then
		accounts+=("$input")
    fi
}

if [ -f "${path}/account.txt" ]; then
	last_account="$(cat "${path}/account.txt" 2>/dev/null)"
	if [ -n "${last_account}" ]; then
		echo "last_account: ${last_account}";
		if [ -d "${path}/config" ]; then
			if [ -d "${path}/config_${last_account}" ]; then
				rm -r "${path}/config_${last_account}";
			fi
			mv "${path}/config" "${path}/config_${last_account}";
		fi
		rm "${path}/account.txt";
	fi
fi
if [ -f "${path}/accounts.txt" ]; then
	while IFS= read -r line; do
		accounts+=("$line")
	done < "${path}/accounts.txt"
else
	show_input_dialog
	while [[ -n ${input} ]]; do
		if ! zenity --question --title="Account" --text="Want to add another account?"; then
			break
		fi
		show_input_dialog
	done
	if [ -n "${accounts}" ]; then
		for line in "${accounts[@]}"; do
			echo "${line}"
		done > "${path}/accounts.txt"
	fi
fi
for line in "${accounts[@]}"; do
	echo "account: ${line}"
done
if [ -z "$ACCOUNT" ]; then
	zenity=(zenity --list --title="Heroic Games Launcher" --column="Account");
	zenity+=("${accounts[@]}");
	ACCOUNT=$("${zenity[@]}");
fi
if [ -n "$ACCOUNT" ]; then
	echo "ACCOUNT: ${ACCOUNT}";
	echo "${ACCOUNT}" > "${path}/account.txt"
	if [ -d "${path}/config_${ACCOUNT}" ]; then
		mv "${path}/config_${ACCOUNT}" "${path}/config";
	fi
	if [ -n "${STEAM_BASE_FOLDER}" ]; then
		compat_tools="${STEAM_BASE_FOLDER}/compatibilitytools.d";
		for proton in "${path}/config/heroic/tools/proton/"*/; do
			if [ -d "${proton}" ]; then
				proton_version=$(basename "${proton}")
				if [ ! -d "${compat_tools}/${proton_version}" ]; then
					if zenity --question --title="Proton" --text="Add proton: ${proton_version} to steam?"; then
						mkdir -p "${compat_tools}";
						ln -s "${proton}" "${compat_tools}/${proton_version}";
					fi
				fi
			fi
		done
	fi
	flatpak run com.heroicgameslauncher.hgl "$@"
fi
