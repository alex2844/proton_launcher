#!/bin/bash
#Check if running from install location
if [[ . -ef ~/Documents/Steam-Shortcut-Manager ]]; then
  echo "Seems like you've already installed SSM to the Steam Deck, not copying over myself..."
else
  cp -r . ~/Documents/Steam-Shortcut-Manager
fi

mv -v ~/Documents/Steam-Shortcut-Manager/AddToSteam.desktop ~/.local/share/kservices5/ServiceMenus/
