# Goldpaw's UI Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) 
and this project adheres to [Semantic Versioning](http://semver.org/).

## [1.1.40] 2018-06-05
### Changed
- Updated readme links to point to BitBucket. We're leaving GitHub.

### Fixed
- The changelog dates was a full year off. Major facepalm.

## [1.1.39] 2018-05-12
### Added 
- Added option to toggle the Minimap spikes. You'll find it under the "Maps" submenu in the /gui options menu. 

### Changed
- Bottomleft actionbar disabled by default for all characters now, and not just for characters below level 10. This only affects default values for characters using the UI for the first time, it does not affect saved settings for characters already using it.  

## [1.1.38] 2018-05-12
### Fixed
- Fixed an issue causing empty tooltips.

## [1.1.37] 2018-05-10
### Fixed
- Fixed some minor tooltip anchor related bugs. 

## [1.1.36] 2018-02-12
### Changed
- Health values in the group frames visible in raids and battlegrounds now show a decimal. 
- Changed the name of the unitframe and groupframe addons to "Goldpaw's UnitFrames" and "Goldpaw's GroupFrames" in the addon listing. 

## [1.1.35] 2018-01-15
### Changed
- More fixes to the GameTooltip to work around Blizzard's faulty Legion 7.3 nameplate protected tooltip bug.

## [1.1.34] 2017-12-19
### Fixed
- Forgot to add an upvalue in the 1.1.33 change, resulting in bugs when trying to access the /gui options menu.

## [1.1.33] 2017-12-19
### Changed
- Changed how the UI deals with the PlaySound changes in the 7.3.0 WoW client patch, to be compatible with the nitwit way Ace3 handles it. They check for the existence of the PlaySoundKitID API call and base their PlaySound usage on that, instead of checking for the client version as they should. 

## [1.1.32] 2017-12-09
### Fixed
- Working around the protected GameTooltip bug introduced with secure friendly dungeon nameplates in WoW patch 7.3.0 by Blizzard. This bug mostly occurred on specs with dispel abilities when hovering over friendly auras. 

## [1.1.31] 2017-12-06
### Changed
- The on-screen game engine damage text is no longer changed by the font changer. The Blizzard font works just fine here since the release of Legion. 

## [1.1.30] 2017-09-26
### Changed
- The fishing button should be hidden on login now, and only shown if or when a fishing pole is equipped.

## [1.1.29] 2017-09-07
### Changed
- Changed how some Blizzard UI elements (e.g. pet cast bar) are hidden, in an effort to get rid of the taint constantly blamed on gUI4_Chat.

### Fixed
- Fixed how the AM/PM clock is displayed, were some bugs around 12PM'ish. 

## [1.1.28] 2017-08-30
### Fixed
- Fixed the toc file typos that made the UI list as "incompatible" no matter what you did. Sorry! 

## [1.1.27] 2017-08-29
### Changed
- Bumped the toc version to patch 7.3.0.

## [1.1.26] 2017-08-15
### Fixed
- The bugs preventing /shownames, /hidenames, /showbinds and /hidebinds from functioning should now be fixed!

## [1.1.25] 2017-07-24
### Added
- Added Chinese (zhCN) localization!

## [1.1.24] 2017-07-22
### Fixed
- Fixed a typo in Goldpaw's NamePlates that would sometimes cause nameplate auras to have their remaining time and spell count hidden.

## [1.1.23] 2017-07-18
### Changed
- Added the spell Vivify with a 40 yard range to the unitframe range checker element for Monks, as the group frames were reporting a far shorter healing range than Monks actually have.

## [1.1.22] 2017-07-17
### Changed
- Changed how LibWindow, glock and the floaters module handles frame placements, in an attempt to override Mappy's handling of the Durability frame and the Vehicle Seat Indicator frame. 

## [1.1.21] 2017-07-13
### Fixed
- Fixed a bug in the unitframe module's spawn function that would send incorrect values to the /glock frame movement module about numbered units like boss frames, thus preventing them from being moved.
- Removed the code making the quest tracker minimized when in an arena or fighting a boss, as this would cause taint and other problems. Better to touch the blizzard tracker as little as possible, or replace it completely with a custom one at a later time. 

## [1.1.20] 2017-07-13
### Changed
- Goldpaw's UI is now WoW 7.1.5-7.3.0 compatible.
- Major library change to avoid future incompatibilites out of our control. All libraries have been renamed to be locked at the current version regardless of what versions other addons may have. We will manually keep them both updated and backwards compatible.

### Fixed 
- Fixed all the PlaySound errors in the PTR client patch 7.3.0.
- Fixed a stack overflow when attempting to unlock the position of the durability frame, talking head frame, return to graveyard frame or vehicle seat selector. 

## [1.1.19] 2017-06-20
### Removed
- Removed the completely redundant aura consolidation box. This doesn't exist in the game anymore. 

## [1.1.18] 2017-06-20
### Fixed
- Added an existance check to solve an issue with the GroupAuras unitframe element in line 155 of groupauras.lua. This is just a workaround, as the function in question shouldn't have been called in the first place if the GroupAuras element didn't exist. So further testing is needed, but for now the important thing is to get rid of the error.

## [1.1.17] 2017-06-20
### Changed
- Forcefully disable both chat bubbles and the skinning of them while inside instances, to avoid big spammy boss chat bubbles from WoW client patch 7.2.5 and beyond. 

## [1.1.16] 2017-06-19
### Fixed
- The chat bubbles should be working again now for non-protected chat bubbles. Nameplates and chat bubbles from friendly NPCs within instances will not be restyled, but this is not a bug, this is the intended behaviour from Blizzard. Other nameplates and bubbles will be styled as before.

## [1.1.15] 2017-06-18
### Changed
- The chat bubble module is temporarily disabled for WoW client patch 7.2.5 while I figure out a way to work around their new stupid protected instance chat bubbles. 

## [1.1.14] 2017-06-16
### Fixed
- Changed the spellID the unitframe combopoint module identifies Druid Cat Form with, as this apparently changed in 7.2.5 (or the WoD steroid cat spell was finally removed from the game).

## [1.1.13] 2017-05-04
### Fixed
- Fixed a bug in the new oUF element GroupAuras where it would bug out at startup for classes not able to dispel. 

## [1.1.12] 2017-05-04
### Changed
- Changed the old unitframe element RaidDebuffs into a new one called GroupAuras. The code was optimized, and proper support for Disc Priest Atonment was added. Menu options were updated to reflect the changes. The internal name change and change in menu description was meant to better reflect that this option no longer handles only raid debuffs, but other important auras relevant to groups as well.

## [1.1.11] 2017-04-29
### Fixed
- Fixed a faulty reference in line 88 of gUI4\libs\oUF-Elements\altpower.lua. This was an entry I overlooked during 1.1.10's rearrangement of the folder structure.

## [1.1.10] 2017-04-28
### Added
- Added Atonement to the group aura tracking

### Changed
- Changed the group debuff system to allow tracking of custom auras like Atonement
- Moved oUF and all the custom elements into the core addon, to allow all modules access to the same instance.

## [1.1.9] 2017-04-24
### Fixed
- Fixed a type comparison error in the aura module that would occur when using an offhand weapon with a temporary enchant.

## [1.1.8] 2017-04-13
### Changed
- Moved all localization into the core addon, to simplify translating for volunteers.

## [1.1.7] 2017-04-10
### Added
- The Talking Head Frame has been moved far away from the actionbars, and is also be movable with /glock.

### Changed
- Added menu entries to toggle chat smileys and URLs in the Chat section of the /gui options menu.
- Now forcing target nameplate insets (padding from screen edges) to blizzard defaults, which works best with Goldpaw's UI.

### Fixed
- The red warning text shouldn't collide with the order hall information anymore.

## [1.1.6] 2017-04-06
### Fixed
- In 7.2.0 Blizzard introduced nameplates for friendly NPCs in instances. These plates are bugged as fuck, and we can't even call normal read only frame methods like :GetName() on them without causing a wall of taints and errors. This broke the chat bubbles which does exactly that. Fixed now. 

## [1.1.5] 2017-04-06
### Changed
- Merged the entire Goldpaw's UI addon suite into a single project. Addon structure in-game remains untouched, this change only affects download and bug reports. 

### Fixed 
- Stances should follow the default Blizzard UI, this fixes the problem with Rogue Shadowdance. 

## [1.0.4] 2017-03-29
### Changed
- Bumped toc to patch 7.2.0.

### Fixed
- Fixed bugs related to C_ArtifactUI changes in 7.2.0, with the introduction of an artifact tier return value in GetEquippedArtifactInfo method, which now is needed when calling the GetEquippedArtifactXP method. The bugs occured in the artifact bar module, as well as the xp bar's tooltip.

## [1.0.3] 2017-03-28
### Changed
- Updated patreon links in the readme.md file and in-game options menu.

## [1.0.2] 2016-12-12
### Changed
- Changed the required patch and build for Goldpaw's UI to 7.1.0(22578).

### Fixed
- Fixed versioning in the .toc file

### Removed
- Removed the /mainspec, /offspec, /togglespec commands as they have no meaning in Legion

## [1.0.1] 2016-12-2
### Added
- Added Tbag and Tbag-Shefki to the list of supported bag addons, meaning the Blizzard bags will no longer open alongside these addons.

### Fixed
- ChatFrame1 and ChatFrame2 are no longer removed from the UIPARENT_MANAGED_FRAME_POSITIONS table, as this would result in a nil bug when trying to run /install or reset chat windows to their default settings. Instead we modifiy the table to return the same values as our desired defaults.
- Fixed an AceDB bug in the windows styling module which was a result of the database being declared multiple times

## [1.0.0] 2016-11-23
### Added
- Added a new option in the /gui menu under the submenu 'Miscellaneous' to toggle whether spells are cast on key down or key up, since Blizzard removed this from their own interface options with the release of Legion

### Changed
- Migrated all repositories to GitHub, starting fresh on version numbers for semantic reasons
- Changed the FAQ entry describing how to change whether spells are cast on up- or downpress to point to the /gui menu
