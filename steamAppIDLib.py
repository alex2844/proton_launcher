#!/usr/bin/env python3
# CC0, Public Domain
from pathlib import Path
import binascii
#import zlib

def get_steam_shortcut_id_raw(s:str)->int:
	return binascii.crc32(str.encode(s)) | 0x80000000

def get_steam_shortcut_id(exe, appname):
	"""Get id for non-steam shortcut.

	get_steam_shortcut_id(str, str) -> str
	"""
	unique_id = ''.join([exe, appname])
	id_int = binascii.crc32(str.encode(unique_id)) | 0x80000000
	return id_int

def get_grid_art_destinations(full_steam_user_dir:str, exe:str, appname:str):
	"""Get filepaths for the grid images for the input shortcut.

	get_grid_art_destinations(str, str, str, str) -> dict[str,Path]
	"""
	grid = Path(f"{full_steam_user_dir}/config/grid")
	shortcut = get_steam_shortcut_id(exe, appname)
	bp_shortcut = (shortcut << 32) | 0x02000000
	return {
		'portrait': grid / f"{shortcut}p.jpg", #Also known as capsule
		'hero':   grid / f"{shortcut}_hero.jpg",
		'logo':   grid / f"{shortcut}_logo.png",
		'banner': grid / f"{bp_shortcut}.png",
		'banner2':grid / f"{shortcut}.png",
	}

if __name__=="__main__":
	import sys
	if len(sys.argv)>2:
		print(f'\033[93mIf your steam shortcut is quoted, you have to double quote it in the launch arguments for {sys.argv[0]}!\033[0m')
		#print(sys.argv)
		print(f"AppExe:  {sys.argv[1]}")
		print(f"AppName: {sys.argv[2]}")
		shortcut = get_steam_shortcut_id(sys.argv[1],sys.argv[2])
		legacy =(shortcut << 32) | 0x02000000
		print(f"Full:   {shortcut}")
		print(f"Legacy: {legacy}")
		#print(get_grid_art_destinations("/tmp",'"'+sys.argv[1]+'"',sys.argv[2]))
	else:
		print("Usage: \"Path to game exe\" \"Game Name\"")
		print("Example: \"/home/deck/Documents/Games/Blue Reflection/BLUE_REFLECTION.exe\" \"BLUE REFLECTION\"")
