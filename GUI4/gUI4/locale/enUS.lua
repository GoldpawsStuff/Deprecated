local addon = ...

local L = _G.GP_LibStub("GP_AceLocale-3.0"):NewLocale(addon, "enUS", true)
if not L then return end

---------------------------------------------------------------------------
-- General Guidelines 
---------------------------------------------------------------------------
--
-- When writing locales, make sure that what you replace 
-- is the text AFTER the equal sign, not before. 
-- 
-- So the following is the correct way: 
--  L["Toggle movable frames"] = "切换框架"
-- 
-- While this one here would be WRONG!!  
--  L["切换框架"] = true
-- 
-- This is because the entry before the equal sign is what WoW recognizes the 
-- string value by, while what comes after is what it prints to the screen. 
-- 
-- In Lua coding terms we refer to this as table[key] = value, 
-- where the 'key' should never change as that is what the code interpreter uses. 
-- While the 'value' is what value the 'key' holds. 
--
-- In our locales, a value of 'true' simply means "use the key as the value too",
-- which is why the fallback locale of the UI which is enUS uses this. 
-- Other locales need to insert the translated strings where the 'true' value is.
-- 
-- Also, if you don't translate all the strings in the locale file, 
-- the missing entries will use their enUS defaults instead. 
-- Or at least until the translation is finished! :)


---------------------------------------------------------------------------
-- Escape Sequences
---------------------------------------------------------------------------
--
-- Make sure not to replace any escape sequences. 
-- 
-- Escape sequences are things things that start with a | or a \ sign, 
-- usually followed by a letter or number. 
-- 
-- In WoW, these indicate colors, textures, and other things
-- that aren't text and not meant to be translated. 
--
-- An example of a string with many escape sequences is this:
-- 	L["Click the button below or type |cff4488ff\"/install\"|r in the chat (without the quotes) followed by the Enter key to run the automatic chat window setup.|n|n"] = true
-- 
-- The |n means the text will start on a new line. 
-- The |cff488ff changes the color of the text, while the |r return it to normal. 
-- 
-- The \" means just a quote sign, but to be able to put it inside the string 
-- which is already enclosed by quotes without breaking the string, 
-- we escape by using the backslash. 
-- 
-- The \" in WoW can be compared to the &quot; in HTML. 
-- It gives us the symbol, without having the code interpreter treat it as a quote.
--  
-- You can read more about WoW Lua escape sequences here: 
-- http://wow.gamepedia.com/UI_escape_sequences


---------------------------------------------------------------------------
-- Formatted Output
---------------------------------------------------------------------------
--
-- The third thing to watch out for is formatted output. 
-- Many strings are meant to be used multiple times, and have various 
-- other numbers and strings inserted into them at specific places. 
-- 
-- The places values are inserted starts with a % percentage sign, 
-- followed by a usually just letter, sometimes a few numbers.
-- 
-- An example of formatted output is this:
-- 	L["%s requires WoW patch %s(%d) or higher, and you only have %s(%d), bailing out!"] = true
--
-- In this string, %s indicates that another string or word should be inserted here,
-- while %d indicates that an integer number value should be inserted. 
-- Floating points are indicated with %f, and sometimes values like %.1f which means "show 1 digit after the decimal point".
-- 
-- More about Lua floating point conversions here: 
-- http://www.gnu.org/software/libc/manual/html_node/Floating_002dPoint-Conversions.html#Floating_002dPoint-Conversions

-- And more about Lua formatted output here:
-- http://www.gnu.org/software/libc/manual/html_node/Table-of-Output-Conversions.html#Table-of-Output-Conversions



-------------------------------------------------------
-------------------------------------------------------
-- Core
-------------------------------------------------------
-------------------------------------------------------

-- keybinds
L["gUI4"] = true
L["Goldpaw's UI"] = true
L["Toggle movable frames"] = true
L["Toggle Calendar"] = true
L["Toggle Help Window"] = true
L["Toggle Blizzard Store"] = true

-- intro messages
L["/glock to toggle movable frames."] = true
L["/glockreset to reset movable frames."] = true
L["/disablefade to disable fading"] = true
L["/enablefade to enable fading (explorer mode)"] = true
L["/install to automatically set up chat windows"] = true

-- used by the auto-setup
-- chat window titles
L["Main"] = true -- main chat
L["Loot"] = true -- loot chat
L["Log"] = true -- combat log
L["Pet"] = true -- pet battle log

-- gUI4 system messages, popups and stuff
L["%s requires WoW patch %s(%d) or higher, and you only have %s(%d), bailing out!"] = true
-- L["gUI4 could not be loaded beacuse gUI3 was still active. Do you wish to disable it?"] = true
-- L["gUI3 has been scheduled for disabling, but a reload is required in order to complete the operation.|n|nReload the user interface now?"] = true
L["The user interface needs to be reloaded for the changes to take effect. Do you wish to reload it now?"] = true
L["This is your first time running %s.|nWould you like the chat window autosetup to run now? This action will set up the chat windows, channels and messagegroups to what Goldpaw uses."] = true
L["This will set up your chat windows, chat channels and messagegroups to what Goldpaw uses.|n|nAre you sure you wish to do this?"] = true
L["You can run the setup again any time with /install"] = true
L["This will reset the positions of all movable frames. Are you sure?"] = true
-- L["This will disable %s and enable the Blizzard raid addons. Are you sure?"] = true
L["%s: Unknown state '%s'"] = true 

-- gUI4 developer error messages
L["Attempt to modify read-only table"] = true
L["Cannot modify write protected media objects."] = true
L["You can't write singular values directly into gUI4's media library, use sub-libraries instead!"] = true
L["You can't write singular values directly into gUI4's color library, use sub-libraries instead!"] = true

-- glock
L["/glock"] = true
L["Toggle between automatic placement and free movement by clicking|nthe padlock icons in the upper right corners of the frame overlays."] = true
L["Hold down the left mouse button and drag the overlay|nto your preferred position when in free movement mode."] = true
L["Left-Click an overlay to move it to the front of the other overlays."] = true
L["<Left-Click to move it to the front.>"] = true
L["Right-Click an overlay to move it to the back of the other frames."] = true
L["<Right-Click to move it to the back.>"] = true
L["<Middle-Click to hide the anchor.>"] = true
L["Middle-Click an overlay to completely hide it."] = true
L["The frame is currently set to automatic positioning, |nwhich means its placement will be handled by the UI."] = true
L["<Left-Click to enable free movement>"] = true
L["<Left-Click %s to enable free movement>"] = true
L["Frame is currently set to free movement, |nwhich means you are free to place it wherever you wish."] = true
L["<Left-Click to enable automatic placement>"] = true
L["<Left-Click %s to enable automatic placement>"] = true

-- system messages
L["Activating Primary Specialization"] = true
L["Activating Secondary Specialization"] = true

-- options menu
L["Settings can't be modified while engaged in combat."] = true
L["Closing options window because you entered combat."] = true
--L["Goldpaw's UI"] = true
L["General"] = true -- used by most categories

-- options menu, auras category
L["Auras"] = true

-- options menu, chat category
L["Chat"] = true
L["|n|cffffd200" .. "Preparing the Chat Windows for Goldpaw's UI" .. "|r"] = true
L["Click the button below or type |cff4488ff\"/install\"|r in the chat (without the quotes) followed by the Enter key to run the automatic chat window setup.|n|n"] = true
L["Set Up Chat"] = true
L["Sets up the windows, chat channels and message groups to what Goldpaw uses. This action will change various game settings."] = true

-- options menu, fading category
L["Fading"] = true
L["Explorer Mode"] = true
L["Explorer mode is when the interface automatically fades out when you're in a \"safe\" situation to allow for more immersive exploration of the game world. The explorer mode can be toggled with the commands |cff4488ff/enabledfade|r and |cff4488ff/disablefade|r or by changing the selection below."] = true
L["Enable Explorer Mode"] = true
L["Toggle the explorer mode where the interface automatically fades out to allow for more immersive exploring. |n|n|cffff0000Deselect to keep the interface permanently visible and deactivate the fading.|r"] = true

-- options menu, groups category
L["Groups"] = true

-- options menu, maps category
L["Maps"] = true

-- options menu, merchants & trade category
L["Merchants & Trade"] = true

-- options menu, misc category
L["Miscellaneous"] = true

-- options menu, positioning category
L["Positioning"] = true
L["|nClick the button below or type |cff4488ff\"/glock\"|r in the chat (without the quotes) followed by the Enter key to toggle the visibility of the movable frame anchors, and choose between automatic and custom placement of the frames.|n"] = true
L["Lock"] = true
L["Lock all frames."] = true
L["Toggle Lock"] = true
L["Toggles the visibility of the movable frame anchors."] = true
L["Reset"] = true
L["Reset all movable frame anchors."] = true
L["|nClick the button below or type |cff4488ff\"/glock reset\"|r in the chat (without the quotes) followed by the Enter key to reset the positions of all movable frames, and return them all to automatic placement.|n"] = true

-- options menu, sizing category
L["Sizing"] = true

-- options menu, tooltips category
L["Tooltips"] = true

-- options menu, visibility category
L["Visibility"] = true

-- options menu, faq category
L["FAQ"] = true
L["Frequently Asked Questions"] = true
L["\n|cffffd200" .. "How do I stop stuff from fading out?" .. "|r"] = true
L["The commands /enablefade and /disablefade can toggle the automatic fading, or you can disable it directly in the options menu."] = true
L["\n|cffffd200" .. "How do I move items around?" .. "|r"] = true 
L["The command /glock toggles the movable frame anchors."] = true
L["\n|cffffd200" .. "How do I reset the position of something?" .. "|r"] = true
L["You can reset the positions of saved frames and return to a fully locked mode by using the command /resetlock, or from the options menu. It should be noted that his will reset all frame anchors, as there is no way to reset just a single item."] = true
L["\n|cffffd200" .. "Who wrote this masterpiece?" .. "|r"] = true
L["Goldpaw's UI was written by Lars \"Goldpaw\" Norberg of EU-Karazhan. Visit www.facebook.com/cogwerkz for more info."] = true



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's ActionBars
-------------------------------------------------------
-------------------------------------------------------

L["/setbars 1-3 to change number of visible bottom actionbars"] = true
L["/setsidebars 0-2 to change number of visible side actionbars"] = true

L["Usage: '/setbars n' - where 'n' is the number of bottom action bars, from 1 to 3."] = true
L["Usage: '/setsidebars n' - where 'n' is the number of side action bars, from 0 to 2."] = true

L["Bar %s"] = true
L["Stance Bar"] = true
L["Pet Bar"] = true
L["ExtraActionButton"] = true
L["Exit Vehicle"] = true
L["Fishing"] = true
L["Salvage Crates and Garrison Mine Tools"] = true
L["You can't change number of visible actionbars while engaged in combat!"] = true
L["You can't configure actionbars while engaged in combat!"] = true

L["XP Bar"] = true
L["Current XP: "] = true
L["Rested Bonus: "] = true
L["Rested"] = true
L["Normal"] = true
L["%s of normal experience\ngained from monsters."] = true
L["You should rest at an Inn."] = true
L["Resting"] = true
L["You must rest for %s additional\nminutes to become fully rested."] = true
L["You must rest for %s additional\nhours to become fully rested."] = true
L["Time to level"] = true
L["Kills: "] = true
L["Quests: "] = true

L["Reputation Bar"] = true
L["Current Reputation: "] = true
L["Maximum Reputation"] = true -- used when the reputation tracked is maxed out
L["<Left-Click to toggle Reputation pane>"] = true

L["Artifact Bar"] = true
L["Current Artifact Power: "] = true
L["<Left-Click to toggle Artifact Window>"] = true

-- options menu
L["ActionBars"] = true
L["\n|cffffd200" .. "Where is the micro menu?" .. "|r"] = true
L["There currently isn't one in Goldpaw's Actionbars, but you can middle click the minimap for a dropdown menu with all the relevant shortcuts if you have Goldpaw's Minimap installed."] = true
L["\n|cffffd200" .. "How can I move the bars around?" .. "|r"] = true
L["The command /glock toggles the movable frame anchors, though currently only the stance bar, the pet bar, the extra actionbutton, the vehicle exit button and the fishing button are movable."] = true
L["\n|cffffd200" .. "How can I change number of visible actionbars?" .. "|r"] = true
L["The command /setbars followed by a number from 1 to 3, and the command /setsidebars followed by a number from 0 to 2 toggles the number of visible bars. You can also change this setting from the /gui options menu under the 'Visibility' submenu and the 'ActionBars' tab."] = true
L["\n|cffffd200" .. "My spells are cast when I try to move them!" .. "|r"] = true
L["This setting used to exist in Blizzard's interface menu under the 'Combat' settings, but was removed in patch 7.0.1 from the interface. You can change it now from the /gui options menu under the 'Miscellaneous' submenu and the 'ActionBars' tab!"] = true
L["ActionBar Visibility"] = true
L["Here you can manually decide whether or not to show specific bars. Not all bars can be toggled, as some like the main actionbar is required for basic game functionality."] = true
L["|n|n|cffffd200" .. "Main ActionBars" .. "|r"] = true
L["Choose the number of visible actionbars located at the bottom of the screen.|n|n"] = true
L["One Bar"] = true
L["Only display the main actionbar."] = true
L["Two Bars"] = true
L["Display two bottom actionbars, with the main bar at the bottom, and the bar referred to as the \"bottom left\" bar in the default UI displayed at the top."] = true
L["Three Bars"] = true
L["Display all three bottom actionbars, with the main bar at the bottom, and the bar referred to as the \"bottom right\" bar in the default UI displayed at the top."] = true
L["|n|n|cffffd200" .. "Sidebars" .. "|r"] = true
L["Choose the number of visible actionbars located at the right side of the screen.|n|n"] = true
L["No Bars"] = true
L["Keep the sidebars hidden"] = true
L["Only display the right sidebar."] = true
L["Display both sidebars."] = true
L["|n|n|cffffd200" .. "Custom Buttons" .. "|r"] = true
L["Choose the visibility of special actionbars and buttons like the Fishing button that appears when you equip a Fishing Pole.|n|n"] = true
L["Display the fishing button."] = true
L["Toggles the display of the Fishing button that appears when you equip a Fishing Pole."] = true
L["Display salvage crates and garrison mining tools."] = true
L["Toggles the display of clickable salvage crate buttons when you're in your Salvage Yard, as well as various mining tools when visiting your Garrison Mine."] = true
L["Enable Pet Bar"] = true
L["Toggle the display of the pet bar. This is sometimes used for vehicles and temporary pets, and is at some point needed for all classes, not just the ones with pets. It is recommened to always have this enabled."] = true
L["Enable Stance Bar"] = true
L["Toggle the display of the stance bar. This bar is also used for Druid forms, Rogue stealth, Death Knight presences, and so on."] = true
L["Actionbuttons come in two main sizes. The big buttons which is the default size for the five standard actionbars, and the small buttons which is the default for the pet- and stance bars. Click the buttons below or type |cff4488ff/smallbars|r or |cff4488ff/bigbars|r to toggle the sizes.|n|n"] = true
L["Small Bars"] = true
L["Display all bars with small buttons. This is the same as typing |cff4488ff/smallbars|r in the chat."] = true
L["Big Bars (default)"] = true
L["Display the five standard actionbars with large buttons, while keeping the pet- and stance bars small. This is the same as typing |cff4488ff/bigbars|r in the chat."] = true

L["The option to toggle whether spells are cast when you press the key down or when you release it still exists in-game, but was for reasons unknown removed from the normal user interface menu by Blizzard with the release of Legion.|n|n"] = true
L["Cast action keybinds on key down."] = true
L["Cast spells when you push a button down. Uncheck to cast spells when you release the button instead."] = true

-- keybinds
L["Alt"] = "A"
L["Ctrl"] = "C"
L["Shift"] = "S"
L["NumPad"] = "N"

L["Backspace"] = "BS"
L["Button1"] = "B1"
L["Button2"] = "B2"
L["Button3"] = "B3"
L["Button4"] = "B4"
L["Button5"] = "B5"
L["Button6"] = "B6"
L["Button7"] = "B7"
L["Button8"] = "B8"
L["Button9"] = "B9"
L["Button10"] = "B10"
L["Button11"] = "B11"
L["Button12"] = "B12"
L["Button13"] = "B13"
L["Button14"] = "B14"
L["Button15"] = "B15"
L["Button16"] = "B16"
L["Button17"] = "B17"
L["Button18"] = "B18"
L["Button19"] = "B19"
L["Button20"] = "B20"
L["Button21"] = "B21"
L["Button22"] = "B22"
L["Button23"] = "B23"
L["Button24"] = "B24"
L["Button25"] = "B25"
L["Button26"] = "B26"
L["Button27"] = "B27"
L["Button28"] = "B28"
L["Button29"] = "B29"
L["Button30"] = "B30"
L["Button31"] = "B31"
L["Capslock"] = "Cp"
L["Clear"] = "Cl"
L["Delete"] = "Del"
L["End"] = "En"
L["Home"] = "HM"
L["Insert"] = "Ins"
L["Mouse Wheel Down"] = "WD"
L["Mouse Wheel Up"] = "WU"
L["Num Lock"] = "NL"
L["Page Down"] = "PD"
L["Page Up"] = "PU"
L["Scroll Lock"] = "SL"
L["Spacebar"] = "Sp"
L["Tab"] = "Tb"

L["Down Arrow"] = "Dn"
L["Left Arrow"] = "Lf"
L["Right Arrow"] = "Rt"
L["Up Arrow"] = "Up"



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's Auras
-------------------------------------------------------
-------------------------------------------------------

L["Player Buffs"] = true
L["Here you can change the settings for the benefitial player auras located next to the minimap by default."] = true
L["Enable Player Buffs"] = true
L["Toggle the display of benefitial player auras next to the minimap. Disable if you don't wish to track these, or have another way of tracking them that you prefer."] = true
L["Consolidate Buffs"] = true
L["Consolidate long term buffs into a separate container."] = true

L["Player Debuffs"] = true
L["Here you can change the settings for the harmful player auras located next to the minimap by default."] = true
L["Enable Player Debuffs"] = true
L["Toggle the display of harmful player auras next to the minimap. Disable if you don't wish to track these, or have another way of tracking them that you prefer."] = true
L["Color Debuff Borders"] = true
L["Enable to color the border of harmful auras in the color of their school of magic. Disable to color everything red."] = true

L["Consolidated Auras"] = true
L["Click to toggle display of consolidated auras."] = true



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's CastBars
-------------------------------------------------------
-------------------------------------------------------

L["Player"] = PLAYER
L["Focus"] = FOCUS
L["Target"] = TARGET
L["Vehicle"] = "Vehicle"

L["Player CastBar"] = true
L["Focus CastBar"] = true
L["Target CastBar"] = true

L["Timers"] = true

L["d"] = true -- 'days' abbreviation
L["h"] = true -- 'hours' abbreviation
L["m"] = true -- 'minutes' abbreviation
L["s"] = true -- 'seconds' abbreviation

-- options menu
L["CastBars & Timers"] = true
L["CastBars"] = true
L["Toggle the visibility of the on-screen floating castbars."] = true
L["Enable the Player castbar"] = true
L["Displays the your own castbar when you're casting a spell."] = true
L["Enable the Target castbar"] = true
L["Displays the target's castbar when the target is casting a spell."] = true
L["Enable the Focus Target castbar"] = true
L["Displays the focus target's castbar when the focus target is casting a spell."] = true



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's Chat
-------------------------------------------------------
-------------------------------------------------------

-- keybinds
L["Goldpaw's Chat"] = true
L["Whisper your Target"] = true
L["Whisper your Focus Target"] = true

-- options menu
L["Chat"] = true
L["General"] = true
L["Here you can toggle what chat modules are enabled. Disabling a module will completely bypass its functionality."] = true

-- options menu, chat bubble module
L["Bubbles"] = true
L["|n|cffffd200" .. "Chat Bubbles" .. "|r"] = true
L["Goldpaw's Chat features custom chat bubbles. These bubbles were designed to be far less intrusive than the default chat bubbles, and meant to encourage a far more immersive gaming experience. Here you can toggle them or change their settings."] = true
L["Use custom chat bubbles."] = true
L["Replaces the default chat bubbles with a set of less intrusive bubbles, allowing for a far more immersive gaming experience."] = true
L["|n|cffffd200" .. "Opacity" .. "|r"] = true
L["Set the opacity of the chat bubble background. A higher value makes the chat easier to read, but can also be more intrusive as it covers more of the background."] = true
L["|n|cffffd200" .. "Size" .. "|r"] = true
L["Set the size of the font used within the chat bubbles. As with the opacity, a higher value makes it easier to read, but at the cost of immersion."] = true
L["Select the size of the font used within the chat bubbles."] = true

-- options menu, chat window module
L["Windows"] = true
L["|n|cffffd200" .. "Chat Windows" .. "|r"] = true
L["|n|cffffd200" .. "Window Positioning" .. "|r"] = true
L["By default the chat frames are confined to the screen borders. Here you can change the settings for this.|n"] = true
L["Clamp the chat windows to the screen."] = true
L["Uncheck to freely move the windows where you want, including to the very edges of the screen, or to other screens."] = true
L["|n|cffffd200" .. "Display" .. "|r"] = true
L["Goldpaw's UI hides a lot of the graphics in the chat frames by default, to make them smoother and more immersive. Here you can toggle the visibility of these elements.|n"] = true
L["Hide the navigation buttons."] = true
L["The button frame is where the buttons to navigate within the chat frame resides. In Goldpaw's Chat you can use the mouse wheel to scroll up or down, and by holding down the Shift key you can move to the top or bottom of the frame."] = true
L["Hide the chat tab background."] = true
L["Hides the chat tab backgrounds. Does not hide the actual tabs, as you can still mouse over them to see them."] = true
L["Hide the input box background."] = true
L["Hides the background and highlight textures of the input boxes."] = true

-- options menu, chat filter & abbreviations module
L["Filters"] = true
L["Filters & Smileys"] = true
L["Display smileys in chat."] = true

L["|n|cffffd200" .. "Chat Filters" .. "|r"] = true
L["|n|cffffd200" .. "Chat Abbreviations" .. "|r"] = true
L["Show certain well known emoticons as icons instead of text."] = true
L["Make URLs clickable."] = true
L["Turn URLs into clickable hyperlinks that can be copied into a browser."] = true

-- options menu, sound module
L["Sounds"] = true
L["|n|cffffd200" .. "Whisper Sounds" .. "|r"] = true
L["Goldpaw's Chat plays a sound when you receive a whisper. Here you can toggle or modify that behavior to your liking."] = true
L["|n|cffffd200" .. "Sound Channel" .. "|r"] = true
L["Here you can choose which sound channel to send the whisper sound to. By choosing 'Master' the sound will be heard even when sound effects are turned off in the system settings. This is the default setting."] = true
L["Select the sound channel to send the whisper sound to. Choosing 'Master' will allow the whisper sound to be heard even with sound effects disabled."] = true
L["Master"] = true
L["SFX"] = "Sound Effects"
L["Ambience"] = true
L["Music"] = true
L["Test Sound"] = true
L["Test the whisper sound with your current settings."] = true
L["Play a sound when receiving a whisper."] = true
L["Play a sound when somebody sends you a private whisper."] = true
L["Play a sound when receiving a battle.net whisper."] = true
L["Play a sound when somebody sends you a private whisper through battle.net."] = true

-- options menu, faq section
L["\n|cffffd200" .. "I can't see any public chat!" .. "|r"] = true
L["This is because you allowed Goldpaw's UI to automatically set up the chat windows the way Goldpaw has them when you first ran the UI on this character. Your public chat should be in the 3rd chat tab now, in the window named 'General'. To change settings for this, you have to manually do it the same way it has always been done in WoW. You right click the chat tab, and use the Blizzard options from there."] = true
L["\n|cffffd200" .. "I can't see any loot!" .. "|r"] = true
L["The answer to this is the same as the previous one, except that the loot has been moved to the 4th tab, and is called 'Loot'. This too is just a normal Blizzard chat window, and can be configured or removed through the normal Blizzard chat settings available by right clicking on its tab header, like anything else."] = true
L["\n|cffffd200" .. "How can I scroll to the top or bottom of the chat frames?" .. "|r"] = true
L["By holding down the Shift key while moving the mouse wheel upwards or downwards, the chat frame will scroll to the very top or bottom."] = true
L["\n|cffffd200" .. "I can't click on any links in the chat frames!" .. "|r"] = true
L["You've probably made the window non-interactive. This is a Blizzard setting which can be changed by right clicking on the chat window's tab header, and selecting 'Make interactive'. Be more careful what you click in the future!"] = true

-- options menu, chat fading
L["|n|cffffd200" .. "Chat Frame Fading" .. "|r"] = true
L["By default the messages in the chat frames fade out after a certain amount of time. Here you can toggle this behavior or change its settings.|n"] = true
L["Fade out the chat messages."] = true
L["Fades out chat messages after a certain period of time. Uncheck to keep the chat visible at all times."] = true
L["|n|cffffd200" .. "Display Duration" .. "|r"] = true
L["Set how long in seconds the chat messages remain visible before fading out."] = true
L["|n|cffffd200" .. "Fade Duration" .. "|r"] = true
L["Set how much time the chat messages will spend fading out in seconds."] = true



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's DevTools
-------------------------------------------------------
-------------------------------------------------------

L["Goldpaw's Developer Tools"] = true
L["Reload the user interface"] = true
L["Activate fullscreen mode"] = true
L["Activate windowed mode"] = true
L["Activating Primary Specialization"] = true
L["Activating Secondary Specialization"] = true



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's GroupFrames
-------------------------------------------------------
-------------------------------------------------------

-- system messages
L["You need to update to build r%s or higher of Goldpaw's UI(core) in order to use Goldpaw's GroupFrames!"] = true

-- /glock
L["Group Leader Tools"] = "Group Leader Tools|n|cffff0000Locked group frames are anchored to this!"
L["Group Leader Tools Toggle"] = true

-- raid leader tools
L["Disband Group"] = true
L["This will disband your group. Are you sure?"] = true
L["Group Members: |cffffffff%s|r"] = true
L["Group Members: |cffffffff%s|r/|cffffffff%s|r"] = true

-- options menu
L["GroupFrames"] = true

-- options menu, auras
L["Display important auras on the Group Frames."] = true
L["Shows important auras such as boss debuffs, dispellable debuffs for dispellers  and Disc Priest Atonement on the Group Frames."] = true
L["5 Player Groups"] = true
L["\n|cffffd200" .. "5 Player Group Aura Visibility" .. "|r"] = true
L["Select whether or not to show the 5 player group aura widgets. Deselecting a widget will override all other settings."] = true
L["Display buffs and debuffs on the 5 Player Group Frames."] = true
L["Shows the normal buffs and debuffs on the 5 Player Group Frames."] = true

-- options menu, groups
L["General"] = true

-- options menu, faq
L["\n|cffffd200" .. "How can I toggle the display of debuffs on the Group Frames?" .. "|r"] = true
L["To toggle this option, open the /gui options menu, go to the Auras submenu, and then choose the Group Frames tab."] = true



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's Minimap
-------------------------------------------------------
-------------------------------------------------------

-- system messages
L["You need to update to build r133 or higher of Goldpaw's UI(core) in order to access the new Garrison Report button!"] = true

-- performance widget
L["Network Stats"] = true
L["World latency %s:"] = true
L["(Combat, Casting, Professions, NPCs, etc)"] = true
L["Home latency %s:"] = true
L["(Chat, Auction House, etc)"] = true

-- mail widget
L["New Mail!"] = true

-- middle-click menu
L["Calendar"] = true

-- options menu
L["Minimap"] = true
L["Use 24-hour clock."] = true
L["Toggles the use of the normal 24-hour clock."] = true
L["Use realm time."] = true
L["Toggles the use of the time as reported by your current realm."] = true
L["Show Garrison Report button."] = true
L["Toggles the display of the Garrison Report button."] = true
L["Show spikes around the Minimap."] = true
L["Toggles the display of spikes on the Minimap border."] = true 


-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's NamePlates
-------------------------------------------------------
-------------------------------------------------------



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's Objectives
-------------------------------------------------------
-------------------------------------------------------

L["Objectives"] = true
L["World Score"] = true
L["Vehicle Seat"] = true
L["Graveyard Teleport"] = true
L["ZoneText"] = true
L["Capture Bar"] = true
L["Talking Head Frame"] = true



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's Tooltip
-------------------------------------------------------
-------------------------------------------------------

L["Ghost"] = true -- refers to your spirit form when you're running towards your corpse after dying
L["Boss Debuff: "] = true 
L["Caster: "] = true -- as in "the caster of the buff"
L["Item ID: "] = true
L["Item Level: "] = true
L["Item Sets: "] = true
L["Item crafter: "] = true
L["Spell ID: "] = true
L["Targeting: "] = true -- as in "Paul is targeting Vera"

L["Tooltip"] = true

-- options menu
L["Tooltips"] = true
L["General"] = true
L["All Tooltips"] = true
L["Hide blank lines."] = true
L["Removes blank or empty lines from the tooltip."] = true
L["Unit Tooltips"] = true
L["|n|cffffd200" .. "Unit Names" .. "|r"] = true
L["Select how a character's name is displayed in the tooltip and what elements are included.|n|n"] = true
L["Show player realm."] = true
L["Displays the realm name of players next to their name."] = true
L["Show player title."] = true
L["Displays the currently selected title of players next to their name."] = true
L["Show player gender."] = true
L["Displays the gender of player characters next to their level, race and class."] = true
L["|n|cffffd200" .. "Additional Unit Info" .. "|r"] = true
L["Choose whether or not to show additional unit info like who the unit is targeting, it's current power and so on.|n|n"] = true
L["Show power bars."] = true
L["Displays power bars below the unit health bar when available."] = true
L["Show unit target."] = true
L["Displays who or what the unit is currently targeting."] = true
L["Item Tooltips"] = true
L["|n|cffffd200" .. "Item Information" .. "|r"] = true
L["Toggle general information about the item's power or price."] = true
L["Hide item level."] = true
L["Hides the item level describing the overall power of this item from the tooltip."] = true
L["Hide item ID."] = true
L["Hides the item ID of this item from the tooltip. Item IDs are used to identify items by the game, as well as most fansites like www.wowhead.com and similar."] = true
L["Hide sell value."] = true
L["Hides the sell value of this item from the tooltip."] = true
L["Hide item crafter."] = true
L["Hides who the crafter of the current items is."] = true
L["|n|cffffd200" .. "Item Sets & Bonuses" .. "|r"] = true
L["Toggle information about what equipment manager sets you have included this item in, as well as what gear sets this item belongs to and what bonuses they bring."] = true
L["Hide Equipment Manager sets the item is part of."] = true
L["Hides what Equipment Manager sets the item is a part of."] = true
L["Hide the list of items in the current gear set."] = true
L["Hides the list of items in item sets such as Cenarion Rayment and Gladiator's Sanctuary. Only the set name and number of current items will be displayed."] = true
L["|n|cffffd200" .. "Item Transmogrification" .. "|r"] = true
L["Item transmogrification is when an item is made to look like something else. This can also apply to illusions like custom weapon enchant glows created with the Enchanter's Study in your Garrison."] = true
L["Hide transmogrifications."] = true
L["Hides the transmogrification description from items that have been transmogrified to look like something else."] = true
L["Only hide the transmogrification labels."] = true
L["Only hides the label indicating that an item has been transmogrified. Does not affect the transmogrification description itself."] = true
L["|n|cffffd200" .. "Item Enchantments" .. "|r"] = true
L["Item enchantments can refer to any sort added or created enhancement on an item."] = true
L["Hide enchantments."] = true
L["Hides all enchantments on this item."] = true
L["Only hide the enchantment label."] = true
L["Only hides the label indicating that it's an enchantment, but displays the enchantment details."] = true
L["|n|cffffd200" .. "Item Requirements" .. "|r"] = true
L["Some items have requirements in order to use them. This can include level, race, class, reputation and a variety of other things."] = true
L["Hide requirements."] = true
L["Hides all requirements to wear this item, like race, class or level."] = true
L["Only hide met requirements."] = true
L["Hides requirements to wear this item if they are met, but displays them otherwise."] = true
L["|n|cffffd200" .. "Item Requirements" .. "|r"] = true
L["Some items have requirements in order to use them. This can include level, race, class, reputation and a variety of other things."] = true



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's Trade
-------------------------------------------------------
-------------------------------------------------------

-- merchant module
L["<Alt-Click to buy the maximum amount>"] = true
L["-%s|cFF00DDDDx%d|r %s"] = true
L["Earned %s"] = true
L["You repaired your items for %s using Guild Bank funds"] = true
L["You repaired your items for %s"] = true
L["|cffff0000%s|r"] = true
L["You haven't got enough available funds to repair!"] = true
L["Your profit is %s"] = true
L["Your expenses are %s"] = true

-- money module
L["Goldpaw's UI: Gold"] = true

-- durability module
L["Goldpaw's UI: Durability"] = true

-- options menu
L["Merchants"] = true
L["Merchants & Trade"] = true
L["Automatically repair your equipment."] = true
L["Automatically repair your equipment when visiting a merchant with repair capabilities. This is limited by your available funds."] = true
L["Use guild funds to repair."] = true
L["Use guild funds to repair your gear when available, instead of using your personal gold. This is limited by your daily available funds set by the guild master of your guild."] = true
L["Automatically sell garbage."] = true
L["Automatically sells gray quality loot in your inventory when visiting a merchant."] = true
L["Display a detailed sales report."] = true
L["Displays a detailed report of every item sold when enabled. Disabled to just show the profit or expenses as a total."] = true



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's UnitFrames
-------------------------------------------------------
-------------------------------------------------------

-- system messages
L["You need to update to build r%s or higher of Goldpaw's UI(core) in order for the Boss frames to be shown!"] = true
L["You need to update to build r%s or higher of Goldpaw's UI(core) to use Goldpaw's UnitFrames!"] = true

L["RP"] = true -- display text button for MyRolePlay and totalRP2

-- module display names. the index is the actual module name, so don't change it. 
L["Player"] = "Player" 
L["AltPowerBar"] = "Alternate Power Bar"
L["ClassBar"] = "Class Resource Bar"
L["Pet"] = "Player's Pet"
L["PetTarget"] = "Player's Pet's Target"
L["Target"] = "Target"
L["ToT"] = "Target's Target (ToT)"
L["ToTTarget"] = "Target's Target's Target"
L["Focus"] = "Focus Target"
L["FocusTarget"] = "Focus Target's Target"
L["Boss"] = "Boss"

-- module descriptions for tooltip hovering. index is the internal module name here too.
-- L["PlayerDesc"] = "The currently controlled player or vehicle." 
-- L["AltPowerBarDesc"] = "Alternate Power Bar used in various quests and instances throughout the world."
-- L["ClassBarDesc"] = "Third class resource like Druid Eclipse, Death Knight Runes, Monk Chi and so on."
-- L["PetDesc"] = "Currently active pet or minion."
-- L["PetTargetDesc"] = "The currently active pet's or minion's target."
-- L["TargetDesc"] = "Your current target."
-- L["ToTDesc"] = "Your current target's target. Use this to figure out who your target is attacking or helping."
-- L["ToTTargetDesc"] = "Your current target's target's target. Useful when healing the tank, as this will point to who the tank's target is attacking."
-- L["FocusDesc"] = "Your focused target. Use this to watch out for enemy casts or friendly health and debuffs."
-- L["FocusTargetDesc"] = "Your focused target's target. Use this to track who your tank is attacking, or your enemy is targeting."
-- L["BossDesc"] = "Instance bosses."

-- optionsmenu
L["UnitFrames"] = true

-- player aura options
L["\n|cffffd200" .. "Player Aura Visibility" .. "|r"] = true
L["Select whether or not to show the player aura widgets. Deselecting a widget will override all other settings."] = true
L["Display Player Buffs"] = true
L["Display benefitial auras"] = true
L["Display Player Debuffs"] = true
L["Display harmful auras"] = true
L["\n|cffffd200" .. "Player Aura Filters" .. "|r"] = true
L["Toggle filters related to what auras are shown at what times."] = true
L["Only apply filters while engaged in combat."] = true
L["Only apply the aura filters while you are engaged in combat, and show every aura unfiltered otherwise."] = true
L["Hide auras not cast by the player"] = true
L["Hide auras eligible for consolidation."] = true
L["Hide auras with a very long duration like Mark of the Wild or similar."] = true
L["Hide long duration auras."] = true
L["Hide auras with a duration above 60 seconds. This includes food buffs."] = true
L["Hide static auras."] = true
L["Hide static auras that lack a duration, like mounts, feral forms, auras from group members and so on."] = true
L["Always Show Stealable Buffs"] = true
L["Always display buffs that can be stolen. Overrides other choices."] = true
L["Always Show Boss Debuffs"] = true
L["Always display debuffs cast by a boss. Overrides other choices."] = true

-- pet aura options
L["Display Pet Auras"] = true
L["Display auras on the pet frame"] = true
L["\n|cffffd200" .. "Pet Aura Visibility" .. "|r"] = true
L["Select whether or not to show the pet aura widget. Deselecting a widget will override all other settings."] = true
L["\n|cffffd200" .. "Pet Aura Filters" .. "|r"] = true

-- target aura options
L["\n|cffffd200" .. "Target Aura Visibility" .. "|r"] = true
L["Select whether or not to show the target aura widgets. Deselecting a widget will override all other settings."] = true
L["Display Target Buffs"] = true
-- L["Display benefitial auras"] = true
L["Display Target Debuffs"] = true
-- L["Display harmful auras"] = true
L["\n|cffffd200" .. "Target Aura Filters" .. "|r"] = true
-- L["Toggle filters related to what auras are shown at what times."] = true
-- L["Only apply filters while engaged in combat."] = true
-- L["Only apply the aura filters while you are engaged in combat, and show every aura unfiltered otherwise."] = true
-- L["Hide auras not cast by the player"] = true
-- L["Hide auras eligible for consolidation."] = true
-- L["Hide auras with a very long duration like Mark of the Wild or similar."] = true
-- L["Hide static auras."] = true
-- L["Hide static auras that lack a duration, like mounts, feral forms, auras from group members and so on."] = true
-- L["Always Show Stealable Buffs"] = true
-- L["Always display buffs that can be stolen. Overrides other choices."] = true
-- L["Always Show Boss Debuffs"] = true
-- L["Always display debuffs cast by a boss. Overrides other choices."] = true

-- tot aura options
L["Display Target of Target Auras"] = true
L["Display auras on the target's target's frame"] = true
L["\n|cffffd200" .. "Target of Target Aura Visibility" .. "|r"] = true
L["Select whether or not to show the target's target aura widget. Deselecting a widget will override all other settings."] = true
L["\n|cffffd200" .. "Target of Target Aura Filters" .. "|r"] = true 

-- focus aura options
L["Display Focus Target Auras"] = true
L["Display auras on the focus target's frame"] = true
L["\n|cffffd200" .. "Focus Target Aura Visibility" .. "|r"] = true
L["Select whether or not to show the focus target aura widget. Deselecting a widget will override all other settings."] = true
L["\n|cffffd200" .. "Focus Target Aura Filters" .. "|r"] = true

-- unit visibility
L["Unit Visibility"] = true
L["Here you can manually decide whether or not to show specific units. But be aware that disabling an object such as the player or the target, may lead to connected unitframes changing positions."] = true
L["Enable Player Frame"] = true
L["Toggle the display of the player's unit frame."] = true
L["Enable Player Resource Bars"] = true
L["Toggle the display of the player's resource bars."] = true
L["Enable Pet Frame"] = true
L["Toggle the display of your pet's unit frame."] = true
L["Enable Pet Target Frame"] = true
L["Toggle the display of your pet's target's unit frame."] = true
L["Enable Target Frame"] = true
L["Toggle the display of the target's unit frame."] = true
L["Enable Target's Target Frame"] = true
L["Toggle the display of the target's target's unit frame."] = true
L["Enable Target's Target's Target Frame"] = true
L["Toggle the display of the target's target's target unit frame."] = true
L["Enable Focus Target Frame"] = true
L["Toggle the display of the focus target's unit frame."] = true
L["Enable Focus Target's Target Frame"] = true
L["Toggle the display of the focus target's target's unit frame."] = true
L["Enable Boss Frames"] = true
L["Toggle the display of the boss frames."] = true

