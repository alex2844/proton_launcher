#!/usr/bin/env python3
from typing import Union, Tuple, List, Dict
import os
import sys
from os import path
import vdf
import shutil
import steamAppIDLib
import libVDF
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
		user.SteamID64=str(steamAppIDLib.steamid_to_64bit(user.SteamID32))

		gridDir=os.path.join(user.dir,"config","grid")
		if path.isdir(gridDir):
			os.chmod(gridDir,0o777)
		else:
			os.mkdir(gridDir, 0o777)
		user.gridDir=gridDir

		steamUsers.append(user)
		#user.name
	return steamUsers

def resolveFullImagePath(basePath,imgPath)->str:
	tmp= path.join(basePath,imgPath)
	if path.isfile(tmp):
		ext = os.path.splitext(tmp)[1]
		if ext != ".png" and ext != ".jpg" and ext != ".jpeg" and ext != ".tga":
			print("Unsupported image file type, ignoring.")
			return ""
		return tmp
	else:
		print("Image "+imgPath+" specified in manifest does not exist, ignoring.")
	return ""

def AddCover(gridDir,appTarget,appName,imagePath):
	fName = str(steamAppIDLib.GetAppID(appTarget,appName))+".p"
	ext = os.path.splitext(imagePath)[1]
	if ext != ".png" and ext != ".jpg" and ext != ".jpeg" and ext != ".tga":
		print("Unsupported image file type, ignoring.")
		return
	shutil.copyfile(imagePath,fName+ext,follow_symlinks=True)
	#print("Copied ")

#def AddCover_WithAppID

if __name__=="__main__":
	with open(sys.argv[1],'r') as f:
		manifestFile = f.read()

	manifest:Dict[str,str] = {}
	for l in manifestFile.splitlines():
		if not l or l.startswith("#"):
			continue
		k,v = l.split("=",1)
		manifest[k.lower()]=v

	
	appLocation = path.dirname(path.abspath(sys.argv[1]))
	appFullPath = path.join(appLocation,manifest['exec'])
	print(appLocation)
	assert (len(appLocation) > 5),"Invalid path obtained for install location"
	if not path.isfile(appFullPath):
		print("Executable specified in manifest does not exist, cannot add shortcut")
		sys.exit(1)

	appIcon=resolveFullImagePath(appLocation,manifest['icon'])

	if manifest['proton'].lower()=="false":
		#chmod +x if native linux app, since some crappy file transfer programs will not transfer it
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
		lastEntryInfo = add_to_vdf.findLastEntryNumber(shortcutsVDF)
		inputTuple = add_to_vdf.namedInputPreparation(lastEntryInfo,
			appName=manifest['name'],
			target=appFullPath,
			startDir=appLocation,
			launchArgs=manifest['args'],
			iconPath=appIcon
		)
		add_to_vdf.addEntry(shortcutsVDF,inputTuple)

		print("Added "+manifest['name']+" to steam shortcuts.")
		print("Calc image names based on "+'"'+appFullPath+'",'+manifest["name"])
		destinations = steamAppIDLib.get_grid_art_destinations(user.dir,'"'+appFullPath+'"',manifest["name"])
		print(destinations)
		for imgType in ['cover','hero','logo','banner']:
			if imgType in manifest and manifest[imgType]:
				bannerPath = resolveFullImagePath(appLocation,manifest[imgType])
				if bannerPath:
					shutil.copyfile(bannerPath,destinations[imgType],follow_symlinks=True)
					print("Copied "+imgType+": "+bannerPath+" -> "+str(destinations[imgType]))


# The MIT License (MIT)

# Copyright (c) 2022 Amaryllis Works

# This program uses code from Ice, steam rom manager, and steamgrid

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
