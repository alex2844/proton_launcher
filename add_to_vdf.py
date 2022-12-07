#!/usr/bin/env python3

#-------------------------------------------------------------------------------
# Name:        Steam Shortcut Manager
# Purpose:     Command line tool to add non-Steam application shortcuts.
#              Intended to be used in conjunction with a tool that automates the adding of shortcuts.
#              In addition to adding the shortcut, the steam://rungameid/### is returned.
#              Close Steam before running!
#
#              Should be cross-platform with Linux/Mac/Windows.
#
#              I might make a GUI, or support removing shortcuts at some point. For now, it just adds shortcuts.
#
#              Oh, and you NEED to have an existing shortcuts.vdf - basically, add at least one non-steam shortcut via the GUI.
#              This is an incredibly simple fix for me to implement, I'm just lazy.
#
#              For more information, I'll probably document the file format itself somewhere on a github wiki page sometime.
#              https://github.com/CorporalQuesadilla/Steam-Shortcut-Manager/wiki
#
# Usage:       Run from commandline. Needs the following arguments in this order:
#              Argument                 Explanation
#              --------                 -----------
#              Path to Shortcuts.vdf    Requires Your personal ID - steamID3 [U:1:THIS_PART_HERE_COPY_ME] from https://steamidfinder.com/
#                                           This is for the local path to your shortcuts.vdf file we're modifying,
#                                           located in \Path\To\Steam\userdata\USERIDHERE\config\shortcuts.vdf. Use double quotes.
#              Name of program          Whatever you want to call it. In double quotes if it has spaces or other funky characters
#              Path to program or URL   In double quotes if the path has spaces or other funky characters
#              Path to start program    Basically the folder it's in (use double quotes)
#              Path to icon             Optional place to source the icon. In double quotes. BTW, I'm not sure where the Grid/BigPicture image comes from
#              Shortcut path            No idea what this is. Just do "" (literally 'the empty string' - two double quotes in a row)
#              Launch options           Probably needs double quotes if you got any spaces or other funky characters in there
#              Hidden?                  Put a 1 here to make it only visible under "Hidden", anything else won't hide it. You need something though. 0 is fine.
#              Allow Desktop Config?    Use controller's Desktop Configurations in this game. Put a 1 to enable it, anything else to disable. You need something though. 0 is fine.
#              Allow Steam Overlay?     Put a 1 to enable it, anything else to disable. You need something though. 0 is fine.
#              In VR library?           For the 'VR Library' Category. Put a 1 to enable it, anything else to disable. You need something though. 0 is fine.
#              Last Play Time           Date last played. No idea how this works yet. For now, put 0 and I'll take care of it (mark it as "Never Played")
#              Categories               Any categories you want it to appear in. If you use spaces in a category name, put it in double quotes
#
#              Example:
#              python shortcuts.py "C:\Program Files (x86)\Steam\userdata\ID_HERE\config\shortcuts.vdf" WoohooMyProgramWorks C:\d.exe C:\ "C:\Program Files (x86)\Steam\bin\steamservice.exe" "" WHATUPLAUNCH 0 1 1 1 0 tag1 tag2
#
# Author:      Corporal Quesadilla
#
# Created:     2018.07.15
# Copyright:   (c) Corporal Quesadilla 2018
# Licence:     Everything in this file is under GPL v3 (https://www.gnu.org/licenses/gpl-3.0.en.html).

import sys
from typing import Union, Tuple, List, Dict
from os import path


# def findLastEntryNumber(pathToShortcutsVDF)->int:
#     # From the end, search backwards to the beginning of the last entry to get it's ID
#     foundChars = 1
#     target = '\x00\x01appname'
#     lookingfor = b'target'
#     lastEntryNumber = 0

#     f = open(str(pathToShortcutsVDF), 'rb')
#     fileContents = f.read()

#     for i in range(len(fileContents)):
#         if lookingfor == b'target':
#             if (fileContents[-i]) == target[-foundChars]:
#                 #print repr(target[-foundChars]) + " found"
#                 foundChars = foundChars + 1
#                 if foundChars > len(target):
#                     lookingfor = b'number'
#             else:
#                 foundChars = 1
#                 # make sure current character didn't 'restart' the pattern
#                 # yeah I know copy-paste code sucks
#                 if (fileContents[-i]) == target[-foundChars]:
#                     #print repr(target[-foundChars]) + " found"
#                     foundChars = foundChars + 1
#                     if foundChars > len(target):
#                         lookingfor = b'number'
#         else:
#             if (fileContents[-i]).isdigit():
#                 #print repr(fileContents[-i]) + " found"
#                 lastEntryNumber = str((fileContents[-i])) + str(lastEntryNumber)
#                 #lastEntryPosition = len(fileContents) - i
#             else:
#                 break
#     f.close()
#     # Although unneccessary, also return the character position of the last entry's ID
#     return int(lastEntryNumber)


#Honestly, I don't know why the previous code was written the way it is because shortcuts.vdf
#will never change. Even though it was designed to support more tags, Valve just added extra tags
#in other vdf files anyways.
def findLastEntryNumber(pathToShortcutsVDF)->int:
    foundAppID = False
    startPosition=0
    endPosition=0
    with open(str(pathToShortcutsVDF), 'rb') as f:
        fileContents = f.read()
        for i in range(len(fileContents)-7,0,-1):
            if foundAppID:
                if fileContents[i]==0:
                    startPosition=i+1
                    #print("StartPos: "+str(startPosition))
                    #print(fileContents[startPosition:endPosition])
                    break
                else:
                    print(fileContents[i:endPosition])
                    if i < endPosition-5:
                        print("Failed to get entryNum.")
#                        sys.exit(-1)
                        break
            else:
                #print(fileContents[i:i+7])
                if fileContents[i:i+7]==b"\x00\x02appid":
                    foundAppID=True
                    endPosition=i
                    #print("Pos: "+str(i))
    return int(fileContents[startPosition:endPosition])


def addEntry(pathToShortcutsVDF, inputTuple):
    # if path.getsize(pathToShortcutsVDF) < 35:
    #     print("shortcuts.vdf appears to be empty. Need at least 1 shortcut to add more.")
    #     return
    # Entries are added before the last two characters of the file
    f = open(str(pathToShortcutsVDF), 'rb+')
    fileContents = f.read()
    f.seek(len(fileContents) - 2)
    endFileContents = f.read()
    f.seek(len(fileContents) - 2)
    f.write(createEntry(inputTuple) + endFileContents)
    f.close()

def createEntry(inputTuple)->bytes:
    # Put together all the variables and delimiters

    var_entryID         = inputTuple[0]
    var_appName         = inputTuple[1]
    var_unquotedPath    = inputTuple[2]
    var_startDir        = inputTuple[3]
    var_iconPath        = inputTuple[4]
    var_shortcutPath    = inputTuple[5]
    var_launchOptions   = inputTuple[6]
    var_isHidden        = inputTuple[7]
    var_allowDeskConf   = inputTuple[8]
    var_allowOverlay    = inputTuple[9]
    var_openVR          = inputTuple[10]
    var_lastPlayTime    = inputTuple[11]
    var_tags            = inputTuple[12]


    # There are several parts to an entry, all on one line
    # The data type refers to the input - \x01 indicates String, \x02 indicates boolean, \x00 indicates list
    # Strings must be encapsulated in quotes (aside from launch options)
    # Bools treat '\x01' as True and '\x00' as False
    # Lists are as follows: '\x01' + index + '\x00' + tagContents + '\x00'
    # I have no idea about Date. Not sure why LastPlayTime is marked as a bool
    #   4 characters, usually ending in '[' (maybe?). All 4 being '\x00' is fine too (default?).


    # Key                # Data Type  # Internal Name       # Delimiter     # Input             # Delimiter
    full_entryID        =                                      '\x00'  +  var_entryID        +  '\x00'
    full_appName        =  '\x01'  +  'appname'             +  '\x00'  +  var_appName        +  '\x00'
    full_quotedPath     =  '\x01'  +  'exe'                 +  '\x00'  +  var_unquotedPath   +  '\x00'
    full_startDir       =  '\x01'  +  'StartDir'            +  '\x00'  +  var_startDir       +  '\x00'
    full_iconPath       =  '\x01'  +  'icon'                +  '\x00'  +  var_iconPath       +  '\x00'
    full_shortcutPath   =  '\x01'  +  'ShortcutPath'        +  '\x00'  +  var_shortcutPath   +  '\x00'
    full_launchOptions  =  '\x01'  +  'LaunchOptions'       +  '\x00'  +  var_launchOptions  +  '\x00'
    full_isHidden       =  '\x02'  +  'IsHidden'            +  '\x00'  +  var_isHidden       +  '\x00\x00\x00'
    full_allowDeskConf  =  '\x02'  +  'AllowDesktopConfig'  +  '\x00'  +  var_allowDeskConf  +  '\x00\x00\x00'
    full_allowOverlay   =  '\x02'  +  'AllowOverlay'        +  '\x00'  +  var_allowOverlay   +  '\x00\x00\x00'
    full_openVR         =  '\x02'  +  'OpenVR'              +  '\x00'  +  var_openVR         +  '\x00\x00\x00'
    full_lastPlayTime   =  '\x02'  +  'LastPlayTime'        +  '\x00'  +  var_lastPlayTime
    full_tags           =  '\x00'  +  'tags'                +  '\x00'  +  var_tags           +  '\x08\x08'

    newEntry = full_entryID + full_appName + full_quotedPath + full_startDir + full_iconPath + full_shortcutPath + full_launchOptions + full_isHidden + full_allowDeskConf + full_allowOverlay + full_openVR + full_tags
    return newEntry.encode('utf-8')
    pass

def inputPreperation(args, lastEntryInfo):
    # Get all the variables cleaned up

    # This is the newest entry, one more than the last one.
    var_entryID = str(int(lastEntryInfo[0])+1)

    # Strings
    var_appName         =       args[2]
    var_unquotedPath    = '"' + args[3] + '"'
    var_startDir        = '"' + args[4] + '"'
    var_iconPath        = '"' + args[5] + '"'
    var_shortcutPath    = '"' + args[6] + '"' # quoted? what is this?
    var_launchOptions   =       args[7]

    # Boolean checks
    if args[8] == '1':
        var_isHidden = '\x01'
    else:
        var_isHidden = '\x00'
    if args[9] == '1':
        var_allowDeskConf = '\x01'
    else:
        var_allowDeskConf = '\x00'
    if args[10] == '1':
        var_allowOverlay = '\x01'
    else:
        var_allowOverlay = '\x00'
    if args[11] == '1':
        var_openVR = '\x01'
    else:
        var_openVR = '\x00'

    # Date
    # Since the format hasn't been cracked yet, I'll populate with default
    #   values if you just pass in a '0'. Thank me later.
    var_tags= ''
    if args[12] == '0':
        var_lastPlayTime = '\x00\x00\x00\x00'
    else:
        var_lastPlayTime = args[12]

    for tag in range(13,len(args)-1):
        var_tags = var_tags + '\x01' + str(tag-13) + '\x00' + args[tag] + '\x00'

    return (var_entryID, var_appName, var_unquotedPath, var_startDir, var_iconPath, var_shortcutPath, var_launchOptions, var_isHidden, var_allowDeskConf, var_allowOverlay, var_openVR, var_lastPlayTime, var_tags)

def namedInputPreparation(lastEntryInfo:int=0,
    appName="",target="",startDir="",iconPath="",shortcutPath="",launchArgs="",
    isHidden=False,useDesktopConfig=False,useSteamOverlay=True,inVRLibrary=False,
    lastPlayed=0,categories:List[str]=[]
    ):
    
    # Get all the variables cleaned up

    # This is the newest entry, one more than the last one.
    var_entryID = str(lastEntryInfo+1)

    # Strings
    var_appName         =       appName
    var_unquotedPath    = '"' + target + '"'
    var_startDir        = '"' + startDir + '"'
    var_iconPath        = '"' + iconPath + '"'
    var_shortcutPath    = '"' + shortcutPath + '"' # quoted? what is this?
    var_launchOptions   =       launchArgs

    # Boolean checks
    if isHidden:
        var_isHidden = '\x01'
    else:
        var_isHidden = '\x00'
    if useDesktopConfig:
        var_allowDeskConf = '\x01'
    else:
        var_allowDeskConf = '\x00'
    if useSteamOverlay == '1':
        var_allowOverlay = '\x01'
    else:
        var_allowOverlay = '\x00'
    if inVRLibrary == '1':
        var_openVR = '\x01'
    else:
        var_openVR = '\x00'

    # Date
    # Since the format hasn't been cracked yet, I'll populate with default
    #   values if you just pass in a '0'. Thank me later.
    var_tags= ''
    
    var_lastPlayTime = '\x00\x00\x00\x00'

    for i,tag in enumerate(categories):
        var_tags = var_tags + '\x01' + str(i) + '\x00' + tag + '\x00'

    return (var_entryID, var_appName, var_unquotedPath, var_startDir, var_iconPath, var_shortcutPath, var_launchOptions, var_isHidden, var_allowDeskConf, var_allowOverlay, var_openVR, var_lastPlayTime, var_tags)


if __name__=="__main__":
    pathToShortcutsVDF = sys.argv[1]
    # fileExistenceCheck() # check if file exists. NOT IMPLEMENTED YET.
    lastEntryInfo = findLastEntryNumber(pathToShortcutsVDF)
    inputTuple = inputPreperation(sys.argv, lastEntryInfo)
    addEntry(pathToShortcutsVDF, inputTuple)

#def addFromDict(d:dict):
