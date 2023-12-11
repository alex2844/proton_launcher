#!/usr/bin/env bash

path="$HOME/.var/app/com.heroicgameslauncher.hgl";
accounts=()

mkdir -p "${path}"
cd "${path}"

function show_input_dialog() {
	input=$(zenity --entry --title="Введите значение" --text="Введите имя аккаунта:")
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
		if ! zenity --question --title="Добавить поле" --text="Хотите добавить еще один аккаунт?"; then
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
	flatpak run com.heroicgameslauncher.hgl "$@"
fi
