#!/usr/bin/env python3
from typing import Union, Tuple, List, Dict
from typing_extensions import Literal
import os
import sys
from os import path
import vdf
import shutil
import steamAppIDLib
import libVDF

import requests
import json
import urllib.parse
import argparse
#from typing_extensions import Union


class SteamUser:
	name:str
	SteamID32:str
	SteamID64:str = ""
	dir:str
	gridDir:str

def GetSteamInstallation(steamDir:str="")->Tuple[str,str]:
	if steamDir!="":
		if os.path.isdir(steamDir):
			return steamDir,""
		else:
			return "","There is no steam installation located at "+steamDir
	#This works on Windows too
	userDir = os.path.expanduser("~")
	linuxSteamDir = path.join(userDir,".local","share","Steam")
	if os.path.isdir(linuxSteamDir):
		return linuxSteamDir,""

	linuxSteamDir = path.join(userDir,".local","steam")
	if os.path.isdir(linuxSteamDir):
		return linuxSteamDir,""

	macSteamDir = path.join(userDir,"Library","Application Support","Steam")
	if os.path.isdir(macSteamDir):
		return macSteamDir,""

	WindowsSteamDir = path.join(os.getenv("ProgramFiles(x86)",""),"Steam")
	if os.path.isdir(linuxSteamDir):
		return linuxSteamDir,""
	WindowsSteamDir = path.join(os.getenv("ProgramFiles",""),"Steam")
	if os.path.isdir(linuxSteamDir):
		return linuxSteamDir,""
	
	return "","Could not find a steam installation. Please manually specify it."

def GetSteamUsers(steamDir:str)->List[SteamUser]:
	steamUsers:List[SteamUser] = []
	for userDir in next(os.walk( os.path.join(steamDir,"userdata") ))[1]:
		if userDir=="anonymous": #Anonymous account is used for steam CLI only
			continue
		configFile = os.path.join(steamDir,"userdata",userDir,"config","localconfig.vdf")
		if not path.isfile(configFile):
			print("User "+userDir+" has no local config! Have you logged in recently?")
			print("Tried searching "+configFile)
			continue
		d = vdf.load(open(configFile))
		user = SteamUser()
		user.dir = os.path.join(steamDir,"userdata",userDir)
		user.name = d['UserLocalConfigStore']['friends']['PersonaName']
		user.SteamID32=userDir
		#user.SteamID64=str(steamAppIDLib.steamid_to_64bit(user.SteamID32))

		gridDir=os.path.join(user.dir,"config","grid")
		if path.isdir(gridDir):
			os.chmod(gridDir,0o777)
		else:
			os.mkdir(gridDir, 0o777)
		user.gridDir=gridDir

		steamUsers.append(user)
		#user.name
	return steamUsers

def isValidImage(fName:str):
	for ext in ['.png','.jpg','.jpeg','.tga','.gif','.webp']:
		if fName.lower().endswith(ext):
			return True
	return False

def resolveFullImagePath(basePath,imgPath)->str:
	if not imgPath:
		return ""
	tmp= path.join(basePath,imgPath)
	if path.isfile(tmp):
		if not isValidImage(tmp):
			print("Unsupported image file type, ignoring.")
			return ""
		return tmp
	else:
		print("Image "+imgPath+" specified in manifest does not exist, ignoring.")
	return ""

# def AddCover(gridDir,appTarget,appName,imagePath):
# 	fName = str(steamAppIDLib.GetAppID(appTarget,appName))+".p"
# 	if not isValidImage(imagePath):
# 		print("Unsupported image file type, ignoring.")
# 		return
# 	shutil.copyfile(imagePath,fName,follow_symlinks=True)
# 	#print("Copied ")


#def AddCover_WithAppID

def parseManifest(manifestLocation:str)->Dict[str,str]:
	#TODO: This should really be a class
	manifest:Dict[str,str] = {
		"icon":"",
		"banner":"",
		"hero":"",
		"portrait":"",
		"logo":"",
		"proton":"true",
		"args":""
	}
	with open(manifestLocation,'r') as f:
		manifestFile = f.read()
		for l in manifestFile.splitlines():
			if not l or l.startswith("#"):
				continue
			k,v = l.split("=",1)
			manifest[k.lower()]=v
	return manifest

def isBlackList(n:str)->bool:
	blackListExeNames = [
		"UnityCrashHandler",
		"unins",
		"AppLauncher",
		"dxweb",
		"vcredist",
		"7z", "7za",
		"ManiaMod",
		"jsrsetup" #Literally just Jet Set Radio. Maybe just write a manifest for this one
		]
	nn = n.lower()
	for blacklistName in blackListExeNames:
		if nn.startswith(blacklistName.lower()):
			return True
	return False

def find_game_exe(appBaseDir:str,manifest:dict)->str:

	appFullPath=""
	commonExeDirs=[
		appBaseDir,
		path.join(appBaseDir,"Binaries","Win64"),
		path.join(appBaseDir,"Binaries","Win32"),
		path.join(appBaseDir,"bin","win_x64"), # Simulator games
		path.join(appBaseDir,"Program")
	]

	for d in commonExeDirs:
		for x in os.listdir(d):
			if path.isdir(x):
				continue
			elif isBlackList(x):
				print("Ignoring non-game exe "+x)
				continue
			#print(x)
			if x.lower().endswith(".exe"):
				manifest['proton']="true"
				appFullPath=path.join(appBaseDir,x)
				return appFullPath
			elif x.lower().endswith(".x86") or x.lower().endswith(".x86_64") or x.lower().endswith(".sh"):
				manifest['proton']="false"
				appFullPath=x
				return appFullPath
	return appFullPath

def find_steam_appid(fullPathToExe:str)->int:
	print(fullPathToExe)
	appLocation = path.abspath(path.dirname(fullPathToExe))
	unityDataDir=path.abspath(fullPathToExe[:-4]+"_Data")
	print(appLocation)
	print(unityDataDir)
	appid=0
	for p in [
		path.join(appLocation,"steam_appid.txt"), #normal games. Most steam games already have this.
		path.join(appLocation,"settings","steam_appid.txt"),
		path.join(unityDataDir,"Plugins","steam_appid.txt"), #Unity games
		path.join(unityDataDir,"Plugins","settings","steam_appid.txt"),
		path.join(unityDataDir,"Plugins","x86_64","steam_appid.txt"),
	]:
		#print("Searching "+p)
		if path.isfile(p):
			with open(p,'r') as f:
				return int(f.read().strip())

	#Check every emu in existence...
	emuCfgs = [
		"steam_api.ini",
		"ALI213.ini",
		"REVOLT.ini",
		"steam_emu.ini",
		"VALVE.ini",
		"Binaries/Win32/CONFIG.ini", #Guilty Gear Xrd REV. 2
		"cream_api.ini"
	]
	for e in emuCfgs:
		emuIni = path.join(appLocation,e)
		if path.isfile(emuIni):
			with open(emuIni,'r',encoding='utf-8',errors='ignore') as f:
				for l in f.readlines():
					if "=" not in l:
						continue
					elif not l:
						print("Couldn't find a single line with an appid!!!")
						break
					#print(l)
					k,v = l.split("=",1)
					#print([k,v])
					if k.strip().lower()=="appid":
						return int(v.strip())
	return 0

#Steam refers to images types as "capsule","hero","logo","header", but I've added in some aliases to make it easier
def download_image_from_steam(appID:int,type_:Literal['portrait','capsule','header','banner','hero','logo'])->Tuple[bytes,bool]:
	STEAM_CDN_URL= f"https://steamcdn-a.akamaihd.net/steam/apps/{appID}/"
	#resp
	try:
		if type_=="portrait" or type_=="capsule":
			resp:requests.Response = requests.get(STEAM_CDN_URL+"library_600x900_2x.jpg")
		elif type_=="banner" or type_=="header":
			resp = requests.get(STEAM_CDN_URL+"header.jpg")
		elif type_=="hero":
			resp = requests.get(STEAM_CDN_URL+"library_hero.jpg")
		elif type_=="logo":
			resp = requests.get(STEAM_CDN_URL+"logo.png")
		else:
			print("Invalid type "+type_+" given for image!")
			return bytes(0),False
		if resp.ok:
			return resp.content,True
		else:
			print("Attempted "+resp.url)
			print(resp)
	except requests.exceptions.RequestException as e:
		print(e)
	return bytes(0),False

def get_griddb_appid(griddb_key:str,steamAppID:int=0,gameName:str="")->Tuple[int,str]:
	if steamAppID>0:
		resp=requests.get(f"https://www.steamgriddb.com/api/v2/games/steam/{steamAppID}",headers={
			"Authorization":"Bearer "+griddb_key
		})
		if resp.ok:
			json_:dict=json.loads(resp.content.decode("utf-8"))
			if json_['success']==True:
				return int(json_['data']['id']),json_['data']['name']
			else:
				print("Error!")
				print(json_)
	print("No steamID given for game, searching '"+gameName+"'")
	resp = requests.get("https://www.steamgriddb.com/api/v2/search/autocomplete/"+urllib.parse.quote(gameName),
		headers={
			"Authorization":"Bearer "+griddb_key
		}
	)
	if resp.ok:
		json_:dict=json.loads(resp.content.decode('utf-8'))
		if json_['success']==True:
			print(json_)
			if len(json_['data']) > 0:
				print("Got "+json_['data'][0]['name'])
				return int(json_['data'][0]['id']),json_['data'][0]['name']
#			else:
#				print("No results...")
	print("Failed to find any results.")
	return 0,""


def download_image_from_steamgriddb(griddb_key:str,griddb_appid:int,griddb_type:str)->Tuple[bytes,str]:
	sgdbAliases = {
		#"banner":"grids",
		"icon":"icons",
		"logo":"logos",
		"hero":"heroes"
	}
	if griddb_type in sgdbAliases:
		sgdbk=sgdbAliases[griddb_type]
		listing = requests.get(f"https://www.steamgriddb.com/api/v2/{sgdbk}/game/{griddb_appid}",
			headers={
				"Authorization":"Bearer "+griddb_key
			},
			# params={
			# 	"mimes":["image/png"]
			# }
		)
		if listing.ok:
			json_:dict=json.loads(listing.content.decode("utf-8"))
			if json_['success']==True:
				if len(json_['data'])>0:
					resp = requests.get(json_['data'][0]['url'])
					if resp.ok:
						return resp.content,resp.url
				else:
					print("This game has no "+griddb_type+"... Sad")
					return b'',""
		else:
			print(listing.content)
	elif griddb_type=="portrait" or griddb_type=="banner":
		d = "600x900" if griddb_type=="portrait" else "460x215"
		listing = requests.get(f"https://www.steamgriddb.com/api/v2/grids/game/{griddb_appid}",
			headers={
				"Authorization":"Bearer "+griddb_key
			},
			params={
				"dimensions":[d]
			}
		)
		if listing.ok:
			json_:dict=json.loads(listing.content.decode("utf-8"))
			if json_['success']==True:
				if len(json_['data'])>0:
					resp = requests.get(json_['data'][0]['url'])
					if resp.ok:
						return resp.content,resp.url
				else:
					print("This game has no "+griddb_type+"... Sad")
					return b'',""
			else:
				print(json_)
		else:
			print(listing.content)
	print("Invalid type specified or steamgriddb API is not working.")
	return b'',""
	

if __name__=="__main__":

	parser = argparse.ArgumentParser(description="Adds steam shortcuts for non steam games. Including artwork.")
	parser.add_argument('-v','--verbose',action="store_true",help="Enable verbose output for debugging.")
	parser.add_argument('-n',"--dry-run",action="store_true",dest="dry_run",help="Don't add a shortcut to steam (still downloads images)")
	parser.add_argument("--offline",action="store_true", help="Don't download missing artwork.")
	parser.add_argument("input",help="Game or folder name.")
	#parser.add_argument
	args = parser.parse_args()

	arg = args.input
	appBaseDir=""
	appStartDir=""
	appFullPath=""
	manifest:Dict[str,str] = {
		"icon":"",
		"banner":"",
		"hero":"",
		"portrait":"",
		"logo":"",
		"proton":"true",
		"args":""
	}
	if path.isfile(arg):
		manifest=parseManifest(arg)
		appBaseDir=path.abspath(path.dirname(arg))
		appFullPath = path.join(appBaseDir,manifest['exec'])
	elif path.isdir(arg):
		print("No manifest given, just dir... Searching for manifest")
		manifest['name']=arg.split("/")[-1]
		appBaseDir=path.abspath(arg)
		foundManifest=False
		for x in os.listdir(arg):
			if x.endswith(".smanifest") and path.isfile(x):
				manifest=parseManifest(x)
				appFullPath = path.join(appBaseDir,manifest['exec'])
				foundManifest=True
				break
		if foundManifest==False:
			print("No manifest found, searching manually for files.")

			appFullPath=find_game_exe(appBaseDir,manifest)
			if appFullPath=="":
				print("Couldn't determine exe. Giving up.")
				sys.exit(1)

	else:
		print("Either no path was given or there was an error reading manifest.")
		sys.exit(1)

	assert (len(appFullPath) > 5),"Invalid path obtained for install location"
	if not path.isfile(appFullPath):
		print("Executable specified in manifest does not exist, cannot add shortcut")
		sys.exit(1)


	#Search for images and download more images here
	for x in os.listdir(appBaseDir):
		if path.isdir(x):
			continue
		elif isValidImage(x):
			pairings = {
				"banner":['header','banner','grid'],
				"icon":['icon'],
				"portrait":['capsule','portrait','boxart'],
				"hero":['hero','wide_banner'],
				"logo":['logo']
			}
			for p in pairings:
				for f in pairings[p]:
					if x.lower().startswith(f) or x.lower().startswith("steam_"+f) or x.lower().startswith("steam"+f):
						print("Found "+x+" as "+p)
						manifest[p]=x
						break
	if args.offline:
		print("Offline mode specified, not downloading any missing artwork.")
	else:
		steamAPPID=find_steam_appid(appFullPath)
		if steamAPPID>0:
			print("Steam APP ID: "+str(steamAPPID))
			print("Found steam information, getting additional artwork from Steam...")
			#STEAM_CDN_URL = "https://steamcdn-a.akamaihd.net/steam/apps/%v/"

			for k in ['banner','portrait','hero','logo']:
				if manifest[k]=="":
					img,ok = download_image_from_steam(steamAPPID,k) #type:ignore
					if ok:
						ext = ".jpg" if img[6]==74 else ".png" #ord("J") -> 74
						fullImgPath = path.join(appBaseDir,"steam_"+k+ext)
						with open(fullImgPath,'wb') as f:
							f.write(img)
							print("wrote "+fullImgPath)
						manifest[k]=fullImgPath
		else:
			print("Doesn't seem to be a steam game. Getting additional artwork from steamgrid API...")
		steamGridAPIkey = os.environ['STEAMGRIDDB_API_KEY']
		if steamGridAPIkey:
			steamGridGameID,gameName=get_griddb_appid(steamGridAPIkey,steamAPPID,path.split(appBaseDir)[-1])
			if steamGridGameID>0:
				manifest['name']=gameName
				for k in ["icon","logo","hero","portrait","banner"]:
					if manifest[k]=="":
						print("Grabbing missing "+k+" artwork...")
						img,url = download_image_from_steamgriddb(steamGridAPIkey,steamGridGameID,k)
						if len(img) > 5:
							imgFileName="steam_"+k+"_"+url.split("/")[-1]
							fullImgPath = path.join(appBaseDir,imgFileName)
							with open(fullImgPath,'wb') as f:
								f.write(img)
								print("wrote "+fullImgPath)
							manifest[k]=imgFileName

	appStartDir = path.abspath(path.dirname(appFullPath))
	print("BASE DIR:   "+appBaseDir)
	print("START DIR:  "+appStartDir)
	print("EXE TARGET: "+appFullPath)






	appIcon=resolveFullImagePath(appBaseDir,manifest['icon'])

	if args.dry_run:
		print("Dry run specified, exiting.")
		sys.exit(0)

	if manifest['proton'].lower()=="false":
		#chmod +x if native linux app, since some crappy file transfer programs will not transfer execute bit
		os.chmod(appFullPath,0o755)
		print("Chmod +x to native linux game...")
	
	steamDir,err = GetSteamInstallation()
	if err != "":
		print(err)
		sys.exit(1)
	
	steamUsers = GetSteamUsers(steamDir)
	if len(steamUsers) < 1:
		print("There are no valid steam accounts.")
		sys.exit(1)
	for user in steamUsers:
		print("Processing shortcut for user "+user.SteamID32)
		shortcutsVDF = os.path.join(user.dir,"config","shortcuts.vdf")
		print("Checking shortcuts.vdf")
		lastEntryInfo = libVDF.findLastEntryNumber(shortcutsVDF)
		inputTuple = libVDF.namedInputPreparation(lastEntryInfo,
			appName=manifest['name'],
			target=appFullPath,
			startDir=appStartDir,
			launchArgs=manifest['args'],
			iconPath=appIcon
		)
		libVDF.addEntry(shortcutsVDF,inputTuple)

		print("Added "+manifest['name']+" to steam shortcuts.")
		print("Calc image names based on "+'"'+appFullPath+'",'+manifest["name"])
		destinations = steamAppIDLib.get_grid_art_destinations(user.dir,'"'+appFullPath+'"',manifest["name"])
		print(destinations)
		for imgType in ['portrait','hero','logo','banner']: #Icon is skipped since you can just specify it in the vdf for whatever reason
			if imgType in manifest and manifest[imgType]:
				bannerPath = resolveFullImagePath(appBaseDir,manifest[imgType])
				if bannerPath:
					shutil.copyfile(bannerPath,destinations[imgType],follow_symlinks=True)
					if imgType=="banner":
						shutil.copyfile(bannerPath,destinations['banner2'],follow_symlinks=True)
					print("Copied "+imgType+": "+bannerPath+" -> "+str(destinations[imgType]))

# Copyright (c) 2022 Amaryllis Works

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
