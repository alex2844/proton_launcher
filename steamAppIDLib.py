# CC0, Public Domain
from pathlib import Path
import binascii

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
		'cover': grid / f"{shortcut}p.jpg",
		'hero':   grid / f"{shortcut}_hero.jpg",
		'logo':   grid / f"{shortcut}_logo.png",
		'banner': grid / f"{bp_shortcut}.png",
	}