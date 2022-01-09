local addon = ...

local L = _G.GP_LibStub("GP_AceLocale-3.0"):NewLocale(addon, "zhCN")
if not L then return end

-------------------------------------------------------
-------------------------------------------------------
-- Core
-------------------------------------------------------
-------------------------------------------------------

-- keybinds
L["gUI4"] = true
L["Goldpaw's UI"] = "Goldpaw's界面"
L["Toggle movable frames"] = "切换框架"
L["Toggle Calendar"] = "切换日历"
L["Toggle Help Window"] = "切换帮助窗口"
L["Toggle Blizzard Store"] = "切换暴雪商店"

-- intro messages
L["/glock to toggle movable frames."] = "/glock 移动界面框架"
L["/glockreset to reset movable frames."] = "/glockreset 重置界面框架"
L["/disablefade to disable fading"] = "/disablefade 禁用框架"
L["/enablefade to enable fading (explorer mode)"] = "/enablefade 启用衰落（浏览器模式）"
L["/install to automatically set up chat windows"] = "/install 自动设置聊天窗口"

-- used by the auto-setup
-- chat window titles
L["Main"] = "综合" -- main chat
L["Loot"] = "拾取" -- loot chat
L["Log"] = "日志" -- combat log
L["Pet"] = "宠物" -- pet battle log

-- gUI4 system messages, popups and stuff
L["%s requires WoW patch %s(%d) or higher, and you only have %s(%d), bailing out!"] = "%s 需要魔兽世界补丁 %s(%d) 或更高, 而您只有 %s(%d), 退出！"
-- L["gUI4 could not be loaded beacuse gUI3 was still active. Do you wish to disable it?"] = true
-- L["gUI3 has been scheduled for disabling, but a reload is required in order to complete the operation.|n|nReload the user interface now?"] = true
L["The user interface needs to be reloaded for the changes to take effect. Do you wish to reload it now?"] = "用户界面需要重新更改才能生效。您希望现在重新加载它吗？"
L["This is your first time running %s.|nWould you like the chat window autosetup to run now? This action will set up the chat windows, channels and messagegroups to what Goldpaw uses."] = "这是你第一次运行 %s.|n就会像你的聊天窗口自动安装一样？这一行动将设置聊天窗口、信息组."
L["This will set up your chat windows, chat channels and messagegroups to what Goldpaw uses.|n|nAre you sure you wish to do this?"] = "这将设置你的聊天窗口，聊天频道和信息类型用途。|n|n你确定要这样做吗？"
L["You can run the setup again any time with /install"] = "您可以随时运行安装程序 /install"
L["This will reset the positions of all movable frames. Are you sure?"] = "这将重置所有移动框架的位置。你确定吗？"
-- L["This will disable %s and enable the Blizzard raid addons. Are you sure?"] = true
L["%s: Unknown state '%s'"] = "%s: 未知的状态 '%s'" 

-- gUI4 developer error messages
L["Attempt to modify read-only table"] = "尝试修改只读表"
L["Cannot modify write protected media objects."] = "无法修改写受保护的媒体对象."
L["You can't write singular values directly into gUI4's media library, use sub-libraries instead!"] = true
L["You can't write singular values directly into gUI4's color library, use sub-libraries instead!"] = true

-- glock
L["/glock"] = true
L["Toggle between automatic placement and free movement by clicking|nthe padlock icons in the upper right corners of the frame overlays."] = "点击|在画面右上角的挂锁图标自动布局和自由流动之间切换覆盖."
L["Hold down the left mouse button and drag the overlay|nto your preferred position when in free movement mode."] = "按住鼠标左键并拖动覆盖| NTO您首选的位置时，在自由运动模式."
L["Left-Click an overlay to move it to the front of the other overlays."] = "Left-Click 叠加框架的层级显示."
L["<Left-Click to move it to the front.>"] = "<Left-Click 把它移到前面.>"
L["Right-Click an overlay to move it to the back of the other frames."] = "Right-Click 削减框架的层级显示."
L["<Right-Click to move it to the back.>"] = "<Right-Click 把它移到后面.>"
L["<Middle-Click to hide the anchor.>"] = "<Middle-Click 隐藏锚点.>"
L["Middle-Click an overlay to completely hide it."] = "Middle-Click 覆盖完全隐藏它."
L["The frame is currently set to automatic positioning, |nwhich means its placement will be handled by the UI."] = "该帧当前设置为自动定位, |n这意味着它的位置将由用户界面处理。."
L["<Left-Click to enable free movement>"] = "<Left-Click 自由移动>"
L["<Left-Click %s to enable free movement>"] = "<Left-Click %s 自由移动>"
L["Frame is currently set to free movement, |nwhich means you are free to place it wherever you wish."] = "框架当前设置为自由移动, |n这意味着你可以自由地把它放在任何你想去的地方."
L["<Left-Click to enable automatic placement>"] = "<Left-Click 启用自动配置>"
L["<Left-Click %s to enable automatic placement>"] = "<Left-Click %s 启用自动配置>"

-- system messages
L["Activating Primary Specialization"] = "激活初级专业"
L["Activating Secondary Specialization"] = "激活中等专业"

-- options menu
L["Settings can't be modified while engaged in combat."] = "战斗时不能修改设置."
L["Closing options window because you entered combat."] = "关闭选项窗口，因为你进入战斗."
--L["Goldpaw's UI"] = true
L["General"] = "一般" -- used by most categories

-- options menu, auras category
L["Auras"] = "光环"

-- options menu, chat category
L["Chat"] = "聊天"
L["|n|cffffd200" .. "Preparing the Chat Windows for Goldpaw's UI" .. "|r"] = "|n|cffffd200" .. "准备UI的聊天窗口" .. "|r"
L["Click the button below or type |cff4488ff\"/install\"|r in the chat (without the quotes) followed by the Enter key to run the automatic chat window setup.|n|n"] = "单击下面的按钮或键入 |cff4488ff\"/install\"|r 在聊天（没有引号）之后，输入键运行自动聊天窗口设置.|n|n"
L["Set Up Chat"] = "建立聊天"
L["Sets up the windows, chat channels and message groups to what Goldpaw uses. This action will change various game settings."] = "设置窗口，聊天频道和消息组。此操作将更改各种游戏设置."

-- options menu, fading category
L["Fading"] = "渐隐效果"
L["Explorer Mode"] = "资源管理器模式"
L["Explorer mode is when the interface automatically fades out when you're in a \"safe\" situation to allow for more immersive exploration of the game world. The explorer mode can be toggled with the commands |cff4488ff/enabledfade|r and |cff4488ff/disablefade|r or by changing the selection below."] = "资源管理器模式 是当你再 \"safe\" 情境让游戏世界更具沉浸感的探索。浏览器模式可以切换命令 |cff4488ff/enabledfade|r and |cff4488ff/disablefade|r 或者改变下面的选择."
L["Enable Explorer Mode"] = "启用资源管理器模式"
L["Toggle the explorer mode where the interface automatically fades out to allow for more immersive exploring. |n|n|cffff0000Deselect to keep the interface permanently visible and deactivate the fading.|r"] = "切换资源管理器模式，界面会自动淡出，以进行更为身临其境的探索. |n|n|cffff0000取消保持界面永久可见和停用渐隐.|r"

-- options menu, groups category
L["Groups"] = "队伍/团队"

-- options menu, maps category
L["Maps"] = "地图"

-- options menu, merchants & trade category
L["Merchants & Trade"] = "修理 & 卖灰"

-- options menu, misc category
L["Miscellaneous"] = "其他"

-- options menu, positioning category
L["Positioning"] = "定位"
L["|nClick the button below or type |cff4488ff\"/glock\"|r in the chat (without the quotes) followed by the Enter key to toggle the visibility of the movable frame anchors, and choose between automatic and custom placement of the frames.|n"] = "|n单击下面的按钮或键入 |cff4488ff\"/glock\"|r 在聊天中（没有引号）后面跟着回车键来切换可移动帧锚的可见性，并在帧的自动和自定义位置之间进行选择。.|n"
L["Lock"] = "锁定"
L["Lock all frames."] = "锁定全部框架."
L["Toggle Lock"] = "切换锁定"
L["Toggles the visibility of the movable frame anchors."] = "切换移动架锚的能见度."
L["Reset"] = "重置"
L["Reset all movable frame anchors."] = "重置所有活动框架位置."
L["|nClick the button below or type |cff4488ff\"/glock reset\"|r in the chat (without the quotes) followed by the Enter key to reset the positions of all movable frames, and return them all to automatic placement.|n"] = "|n单击下面的按钮或键入 |cff4488ff\"/glock reset\"|r 在聊天（没有引号）之后，回车键重置所有移动帧的位置，并将它们全部返回到自动放置.|n"

-- options menu, sizing category
L["Sizing"] = "动作条"

-- options menu, tooltips category
L["Tooltips"] = "鼠标提示"

-- options menu, visibility category
L["Visibility"] = "可见度"

-- options menu, faq category
L["FAQ"] = "常见问题解答"
L["Frequently Asked Questions"] = "经常被问到的问题"
L["\n|cffffd200" .. "How do I stop stuff from fading out?" .. "|r"] = "\n|cffffd200" .. "我怎样才能阻止东西淡出？" .. "|r"
L["The commands /enablefade and /disablefade can toggle the automatic fading, or you can disable it directly in the options menu."] = "命令 /enablefade and /disablefade 可以切换自动淡出功能，也可以直接在选项菜单中禁用它."
L["\n|cffffd200" .. "How do I move items around?" .. "|r"] = "\n|cffffd200" .. "如何移动物品？" .. "|r"  
L["The command /glock toggles the movable frame anchors."] = "命令 /glock 切换活动框锚."
L["\n|cffffd200" .. "How do I reset the position of something?" .. "|r"] = "\n|cffffd200" .. "如何重置某事物的位置？?" .. "|r"
L["You can reset the positions of saved frames and return to a fully locked mode by using the command /resetlock, or from the options menu. It should be noted that his will reset all frame anchors, as there is no way to reset just a single item."] = "通过使用命令，您可以重置保存帧的位置并返回到完全锁定模式 /resetlock, 或从选项菜单。需要注意的是，他将重置所有帧锚，因为没有办法重新设置一个项目。."
L["\n|cffffd200" .. "Who wrote this masterpiece?" .. "|r"] = "\n|cffffd200" .. "这杰作谁写的？" .. "|r"
L["Goldpaw's UI was written by Lars \"Goldpaw\" Norberg of EU-Karazhan. Visit www.facebook.com/cogwerkz for more info."] = "Goldpaw's UI 是由 \"Goldpaw\" EU-Karazhan设计,汉化源自【徒手破九霄】. 访问更多的信息www.facebook.com/cogwerkz."



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's ActionBars
-------------------------------------------------------
-------------------------------------------------------

L["/setbars 1-3 to change number of visible bottom actionbars"] = "/setbars 1-3 改变可见动作条数"
L["/setsidebars 0-2 to change number of visible side actionbars"] = "/setsidebars 0-2 改变右侧动作条数"

L["Usage: '/setbars n' - where 'n' is the number of bottom action bars, from 1 to 3."] = "使用: '/setbars n' - “n”是底部动作条的数量，从1到3."
L["Usage: '/setsidebars n' - where 'n' is the number of side action bars, from 0 to 2."] = "使用: '/setsidebars n' - “n”是从0到2的侧动作条的数量。"

L["Bar %s"] = "主动作条 %s"
L["Stance Bar"] = "姿态条"
L["Pet Bar"] = "宠物动作条"
L["ExtraActionButton"] = "苏拉玛变身"
L["Exit Vehicle"] = "下马"
L["Fishing"] = "垂钓"
L["Salvage Crates and Garrison Mine Tools"] = "打捞箱和守备地雷工具"
L["You can't change number of visible actionbars while engaged in combat!"] = "你可以在战斗不改变可见动作条数!"
L["You can't configure actionbars while engaged in combat!"] = "你不能在战斗中配置动作条!"

L["XP Bar"] = "经验条"
L["Current XP: "] = "当前 XP: "
L["Rested Bonus: "] = "奖金: "
L["Rested"] = "精力充沛"
L["Normal"] = "正常"
L["%s of normal experience\ngained from monsters."] = "%s 正常经验\技能的怪物."
L["You should rest at an Inn."] = "你应该在旅馆休息."
L["Resting"] = "休息"
L["You must rest for %s additional\nminutes to become fully rested."] = "你必须休息 %s 额外\n分钟左右成为充分休息."
L["You must rest for %s additional\nhours to become fully rested."] = "你必须休息 %s 额外的\n小时 才能保持精力充沛."
L["Time to level"] = "时间级别"
L["Kills: "] = "杀死: "
L["Quests: "] = "任务: "

L["Reputation Bar"] = "声望条"
L["Current Reputation: "] = "当前声望: "
L["Maximum Reputation"] = "最大声望" -- used when the reputation tracked is maxed out
L["<Left-Click to toggle Reputation pane>"] = "<Left-Click 切换荣誉条>"

L["Artifact Bar"] = "神器条"
L["Current Artifact Power: "] = "当前神器能量: "
L["<Left-Click to toggle Artifact Window>"] = "<Left-Click 切换神器窗口>"

-- options menu
L["ActionBars"] = "动作条"
L["\n|cffffd200" .. "Where is the micro menu?" .. "|r"] = "\n|cffffd200" .. "微型菜单在哪里？" .. "|r"
L["There currently isn't one in Goldpaw's Actionbars, but you can middle click the minimap for a dropdown menu with all the relevant shortcuts if you have Goldpaw's Minimap installed."] = "目前Goldpaw's Actionbars中没有一个，但是如果您安装了Goldpaw的Minimap，您可以点击下拉菜单中的所有相关快捷方式."
L["\n|cffffd200" .. "How can I move the bars around?" .. "|r"] = "\n|cffffd200" .. "如何移动动作条" .. "|r"
L["The command /glock toggles the movable frame anchors, though currently only the stance bar, the pet bar, the extra actionbutton, the vehicle exit button and the fishing button are movable."] = "使用 /glock 切换可动框架锚固件，尽管目前只有立杆，宠物栏，额外的动作按钮，下马按钮和钓鱼按钮是可移动的."
L["\n|cffffd200" .. "How can I change number of visible actionbars?" .. "|r"] = "\n|cffffd200" .. "如何更改可见动作栏的数量？" .. "|r"
L["The command /setbars followed by a number from 1 to 3, and the command /setsidebars followed by a number from 0 to 2 toggles the number of visible bars. You can also change this setting from the /gui options menu under the 'Visibility' submenu and the 'ActionBars' tab."] = "使用 /setbars 后跟一个从1到3的数字，命令/ setsidebars后跟一个从0到2的数字切换可见条数。 您还可以从“可见性”子菜单和“ActionBars”选项卡下的/ gui选项菜单中更改此设置."
L["\n|cffffd200" .. "My spells are cast when I try to move them!" .. "|r"] = "\n|cffffd200" .. "我的法术是在我试图移动他们的时候被施放的！" .. "|r"
L["This setting used to exist in Blizzard's interface menu under the 'Combat' settings, but was removed in patch 7.0.1 from the interface. You can change it now from the /gui options menu under the 'Miscellaneous' submenu and the 'ActionBars' tab!"] = "此设置过去存在于Blizzard的“Combat”设置下的界面菜单中，但在界面中已经从补丁7.0.1中删除。 您现在可以从“杂项”子菜单和“ActionBars”选项卡上的/ gui选项菜单中更改。"
L["ActionBar Visibility"] = "动作条可见性"
L["Here you can manually decide whether or not to show specific bars. Not all bars can be toggled, as some like the main actionbar is required for basic game functionality."] = "在这里，您可以手动决定是否显示特定的条。 并不是所有的酒吧都可以被切换，因为像基本的游戏功能需要主要的动作栏."
L["|n|n|cffffd200" .. "Main ActionBars" .. "|r"] = "|n|n|cffffd200" .. "主要动作条" .. "|r"
L["Choose the number of visible actionbars located at the bottom of the screen.|n|n"] = "选择位于屏幕底部的可见动作栏的数量.|n|n"
L["One Bar"] = "1行"
L["Only display the main actionbar."] = "只显示主动作栏."
L["Two Bars"] = "2行"
L["Display two bottom actionbars, with the main bar at the bottom, and the bar referred to as the \"bottom left\" bar in the default UI displayed at the top."] = "显示两个底部的动作栏，主栏位于底部，该栏被称为在顶部显示的默认UI中的“左下角”栏."
L["Three Bars"] = "3行"
L["Display all three bottom actionbars, with the main bar at the bottom, and the bar referred to as the \"bottom right\" bar in the default UI displayed at the top."] = "显示所有三个底部操作栏，主栏位于底部，并且在顶部显示的默认UI中称为“右下角”栏。."
L["|n|n|cffffd200" .. "Sidebars" .. "|r"] = "|n|n|cffffd200" .. "侧边栏" .. "|r"
L["Choose the number of visible actionbars located at the right side of the screen.|n|n"] = "选择位于屏幕右侧的可见动作栏的数量.|n|n"
L["No Bars"] = "不显示"
L["Keep the sidebars hidden"] = "隐藏侧边栏"
L["Only display the right sidebar."] = "只显示右边栏."
L["Display both sidebars."] = "显示两个侧边栏."
L["|n|n|cffffd200" .. "Custom Buttons" .. "|r"] = "|n|n|cffffd200" .. "自定义按钮" .. "|r"
L["Choose the visibility of special actionbars and buttons like the Fishing button that appears when you equip a Fishing Pole.|n|n"] = "选择特殊动作栏和按钮的可见性，如装备钓鱼杆时出现的“钓鱼”按钮.|n|n"
L["Display the fishing button."] = "显示钓鱼按钮."
L["Toggles the display of the Fishing button that appears when you equip a Fishing Pole."] = "切换装备钓鱼杆时出现的“钓鱼”按钮的显示."
L["Display salvage crates and garrison mining tools."] = "显示救助箱和驻军采矿工具."
L["Toggles the display of clickable salvage crate buttons when you're in your Salvage Yard, as well as various mining tools when visiting your Garrison Mine."] = "当您进入救助场时，切换可点击的救助板条按钮的显示，以及当您访问您的驻军时，可以使用各种采矿工具."
L["Enable Pet Bar"] = "启用宠物动作条"
L["Toggle the display of the pet bar. This is sometimes used for vehicles and temporary pets, and is at some point needed for all classes, not just the ones with pets. It is recommened to always have this enabled."] = "切换宠物动作条的显示。 这有时用于车辆和临时宠物，并且在某些时候需要所有课程，而不仅仅是宠物的宠物。 建议始终启用此功能."
L["Enable Stance Bar"] = "启用姿态条"
L["Toggle the display of the stance bar. This bar is also used for Druid forms, Rogue stealth, Death Knight presences, and so on."] = "切换立场栏的显示。 这个动作条也用于德鲁伊形式，潜行隐形，死亡骑士等等."
L["Actionbuttons come in two main sizes. The big buttons which is the default size for the five standard actionbars, and the small buttons which is the default for the pet- and stance bars. Click the buttons below or type |cff4488ff/smallbars|r or |cff4488ff/bigbars|r to toggle the sizes.|n|n"] = "Actionbuttons有两种主要尺寸。 大按钮是五个标准动作栏的默认大小，以及小按钮，它们是宠物和姿势栏的默认值。 点击下面的按钮或输入|cff4488ff / smallbars |r或|cff4488ff / bigbars |r来切换大小.|n|n"
L["Small Bars"] = "小动作条"
L["Display all bars with small buttons. This is the same as typing |cff4488ff/smallbars|r in the chat."] = "用小按钮显示所有栏。 这与在聊天中输入|cff4488ff / smallbars |r是一样的."
L["Big Bars (default)"] = "大动作条（默认）"
L["Display the five standard actionbars with large buttons, while keeping the pet- and stance bars small. This is the same as typing |cff4488ff/bigbars|r in the chat."] = "使用大按钮显示五个标准动作栏，同时保持宠物和姿势条小。 这与在聊天中键入|cff4488ff / bigbars |r是一样的."

L["The option to toggle whether spells are cast when you press the key down or when you release it still exists in-game, but was for reasons unknown removed from the normal user interface menu by Blizzard with the release of Legion.|n|n"] = "当你按下键或释放它时，法术是否被切换的选项仍然存在于游戏中，但是由于暴雪发布了Legion的普通用户界面菜单中未知的原因.|n|n"
L["Cast action keybinds on key down."] = "按下键放置动作键."
L["Cast spells when you push a button down. Uncheck to cast spells when you release the button instead."] = "当你按下一个按钮时施放法术。 当您释放按钮时，取消选中以施放法术."

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

L["Player Buffs"] = "玩家魔法增益"
L["Here you can change the settings for the benefitial player auras located next to the minimap by default."] = "默认情况下，您可以更改位于小地图旁边的有益玩家光环的设置."
L["Enable Player Buffs"] = "启用玩家魔法增益"
L["Toggle the display of benefitial player auras next to the minimap. Disable if you don't wish to track these, or have another way of tracking them that you prefer."] = "在小地图旁边切换有益玩家光环的显示。 如果您不希望跟踪这些，或者有其他方式跟踪您的偏好，请停用此功能."
L["Consolidate Buffs"] = "合并buff"
L["Consolidate long term buffs into a separate container."] = "将长期的buff加入到一个单独的容器中."

L["Player Debuffs"] = "玩家魔法减益"
L["Here you can change the settings for the harmful player auras located next to the minimap by default."] = "默认情况下，您可以更改位于小地图旁边的有害玩家光环的设置."
L["Enable Player Debuffs"] = "启用玩家魔法减益"
L["Toggle the display of harmful player auras next to the minimap. Disable if you don't wish to track these, or have another way of tracking them that you prefer."] = "切换小地图旁边的有害玩家光环的显示。 如果您不希望跟踪这些，或者有其他方式跟踪您的偏好，请停用此功能."
L["Color Debuff Borders"] = "DEBUFF边框颜色"
L["Enable to color the border of harmful auras in the color of their school of magic. Disable to color everything red."] = "使其在魔法学校的颜色有害光环的边框颜色。禁用所有红色的颜色."

L["Consolidated Auras"] = "合并的光环"
L["Click to toggle display of consolidated auras."] = "点击合并光环切换显示."



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's CastBars
-------------------------------------------------------
-------------------------------------------------------

L["Player"] = PLAYER
L["Focus"] = FOCUS
L["Target"] = TARGET
L["Vehicle"] = "下马"

L["Player CastBar"] = "玩家施法条"
L["Focus CastBar"] = "焦点 施法条"
L["Target CastBar"] = "目标 施法条"

L["Timers"] = "计时器"

L["d"] = "d" -- 'days' abbreviation
L["h"] = "h" -- 'hours' abbreviation
L["m"] = "m" -- 'minutes' abbreviation
L["s"] = "s" -- 'seconds' abbreviation

-- options menu
L["CastBars & Timers"] = "施法条s & 计时器"
L["CastBars"] = "施法条s"
L["Toggle the visibility of the on-screen floating castbars."] = "切换屏幕上的浮动施法条的可见性."
L["Enable the Player castbar"] = "启用玩家施法条"
L["Displays the your own castbar when you're casting a spell."] = "当你施放buff时，显示你自己的法术ID."
L["Enable the Target castbar"] = "启用目标施法条"
L["Displays the target's castbar when the target is casting a spell."] = "当目标投射法术时，显示目标的法术ID."
L["Enable the Focus Target castbar"] = "启用焦点施法条"
L["Displays the focus target's castbar when the focus target is casting a spell."] = "当目标投射法术时，显示焦点的法术ID."



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's Chat
-------------------------------------------------------
-------------------------------------------------------

-- keybinds
L["Goldpaw's Chat"] = "Goldpaw's 聊天"
L["Whisper your Target"] = "密语你的目标"
L["Whisper your Focus Target"] = "密语你的焦点"

-- options menu
L["Chat"] = "聊天"
L["General"] = "一般"
L["Here you can toggle what chat modules are enabled. Disabling a module will completely bypass its functionality."] = "在这里您可以切换启用聊天模块。 禁用模块将完全绕过其功能."

-- options menu, chat bubble module
L["Bubbles"] = "聊天泡泡"
L["|n|cffffd200" .. "Chat Bubbles" .. "|r"] = "|n|cffffd200" .. "聊天泡泡" .. "|r"
L["Goldpaw's Chat features custom chat bubbles. These bubbles were designed to be far less intrusive than the default chat bubbles, and meant to encourage a far more immersive gaming experience. Here you can toggle them or change their settings."] = "Goldpaw的聊天功能可以定制聊天气泡。 这些气泡被设计成比默认的聊天泡泡更少的侵入性，并且意味着鼓励更加身临其境的游戏体验。 在这里，您可以切换它们或更改其设置."
L["Use custom chat bubbles."] = "使用自定义聊天泡泡."
L["Replaces the default chat bubbles with a set of less intrusive bubbles, allowing for a far more immersive gaming experience."] = "取代默认的聊天气泡与一组较少侵入性的气泡，允许更加身临其境的游戏体验."
L["|n|cffffd200" .. "Opacity" .. "|r"] = "|n|cffffd200" .. "不透明度" .. "|r"
L["Set the opacity of the chat bubble background. A higher value makes the chat easier to read, but can also be more intrusive as it covers more of the background."] = "设置聊天泡泡背景的不透明度。 更高的价值使得聊天更容易阅读，但也可以更多的侵入性，因为它涵盖更多的背景."
L["|n|cffffd200" .. "Size" .. "|r"] = "|n|cffffd200" .. "大小" .. "|r"
L["Set the size of the font used within the chat bubbles. As with the opacity, a higher value makes it easier to read, but at the cost of immersion."] = "设置聊天气泡中使用的字体的大小。 与不透明度一样，更高的值使其更容易阅读，但以沉浸为代价."
L["Select the size of the font used within the chat bubbles."] = "选择聊天气泡中使用的字体的大小."

-- options menu, chat window module
L["Windows"] = "窗口"
L["|n|cffffd200" .. "Chat Windows" .. "|r"] = "|n|cffffd200" .. "聊天窗口" .. "|r"
L["|n|cffffd200" .. "Window Positioning" .. "|r"] = "|n|cffffd200" .. "窗口定位" .. "|r"
L["By default the chat frames are confined to the screen borders. Here you can change the settings for this.|n"] = "默认情况下，聊天框架仅限于屏幕边框。 在这里，您可以更改此设置.|n"
L["Clamp the chat windows to the screen."] = "将聊天窗口夹在屏幕上."
L["Uncheck to freely move the windows where you want, including to the very edges of the screen, or to other screens."] = "取消选中以自由移动所需的窗口，包括屏幕的边缘或其他屏幕."
L["|n|cffffd200" .. "Display" .. "|r"] = "|n|cffffd200" .. "显示" .. "|r"
L["Goldpaw's UI hides a lot of the graphics in the chat frames by default, to make them smoother and more immersive. Here you can toggle the visibility of these elements.|n"] = "默认情况下，Goldpaw的UI在聊天框架中隐藏了大量图形，以使它们更平滑，更加身临其境。 在这里，您可以切换这些元素的可见性.|n"
L["Hide the navigation buttons."] = "隐藏导航按钮."
L["The button frame is where the buttons to navigate within the chat frame resides. In Goldpaw's Chat you can use the mouse wheel to scroll up or down, and by holding down the Shift key you can move to the top or bottom of the frame."] = "按钮框是在聊天框架内导航的按钮所在的位置。 在Goldpaw的聊天中，您可以使用鼠标滚轮向上或向下滚动，通过按住Shift键可以移动到框架的顶部或底部."
L["Hide the chat tab background."] = "隐藏聊天选项卡背景."
L["Hides the chat tab backgrounds. Does not hide the actual tabs, as you can still mouse over them to see them."] = "隐藏聊天选项卡背景。 不隐藏实际选项卡，因为您仍然可以将鼠标悬停在其上以查看它们."
L["Hide the input box background."] = "隐藏输入框背景."
L["Hides the background and highlight textures of the input boxes."] = "隐藏背景并突出输入框的纹理."

-- options menu, chat filter & abbreviations module
L["Filters"] = "过滤器"
L["Filters & Smileys"] = "过滤器和表情"
L["Display smileys in chat."] = "在聊天中显示表情."

L["|n|cffffd200" .. "Chat Filters" .. "|r"] = "|n|cffffd200" .. "聊天过滤器" .. "|r"
L["|n|cffffd200" .. "Chat Abbreviations" .. "|r"] = "|n|cffffd200" .. "聊天缩写" .. "|r"
L["Show certain well known emoticons as icons instead of text."] = "将某些众所周知的表情符号显示为图标而不是文字."
L["Make URLs clickable."] = "使网址可点击."
L["Turn URLs into clickable hyperlinks that can be copied into a browser."] = "将URL转换为可以复制到浏览器中的可点击超链接."

-- options menu, sound module
L["Sounds"] = "声音"
L["|n|cffffd200" .. "Whisper Sounds" .. "|r"] = "|n|cffffd200" .. "密语声音" .. "|r"
L["Goldpaw's Chat plays a sound when you receive a whisper. Here you can toggle or modify that behavior to your liking."] = "当您收到密语时，Goldpaw的聊天会发出声音。 在这里，您可以根据自己的喜好切换或修改该行为."
L["|n|cffffd200" .. "Sound Channel" .. "|r"] = "|n|cffffd200" .. "声道" .. "|r"
L["Here you can choose which sound channel to send the whisper sound to. By choosing 'Master' the sound will be heard even when sound effects are turned off in the system settings. This is the default setting."] = "在这里，您可以选择发送密语声音的声道。 通过选择“主”，即使在系统设置中关闭声音效果时，也会听到声音。 这是默认设置."
L["Select the sound channel to send the whisper sound to. Choosing 'Master' will allow the whisper sound to be heard even with sound effects disabled."] = "选择发送密语声音的声道。 选择“主人”将允许密语声音，即使禁用声音效果."
L["Master"] = "主省道"
L["SFX"] = "Sound Effects"
L["Ambience"] = "Ambience"
L["Music"] = "Music"
L["Test Sound"] = "测试声音"
L["Test the whisper sound with your current settings."] = "用您当前的设置测试密语声音."
L["Play a sound when receiving a whisper."] = "收到密语时发出声音."
L["Play a sound when somebody sends you a private whisper."] = "当有人给你私人密语时，发出声音."
L["Play a sound when receiving a battle.net whisper."] = "在接收到战网密语时，发出声音。"
L["Play a sound when somebody sends you a private whisper through battle.net."] = "当有人通过battle.net向您发送私人密语时发出声音."

-- options menu, faq section
L["\n|cffffd200" .. "I can't see any public chat!" .. "|r"] = "\n|cffffd200" .. "我看不到任何公开聊天!" .. "|r"
L["This is because you allowed Goldpaw's UI to automatically set up the chat windows the way Goldpaw has them when you first ran the UI on this character. Your public chat should be in the 3rd chat tab now, in the window named 'General'. To change settings for this, you have to manually do it the same way it has always been done in WoW. You right click the chat tab, and use the Blizzard options from there."] = "这是因为当您第一次使用这个角色的UI时，Goldpaw的用户界面可以自动设置Goldpaw的方式。 您的公开聊天应该在第三个聊天选项卡中，在名为“常规”的窗口中。 要更改此设置，您必须以与WoW一直完成的方式手动进行操作。 您右键单击聊天选项卡，并从那里使用暴雪选项."
L["\n|cffffd200" .. "I can't see any loot!" .. "|r"] = "\n|cffffd200" .. "我看不到任何战利品!" .. "|r"
L["The answer to this is the same as the previous one, except that the loot has been moved to the 4th tab, and is called 'Loot'. This too is just a normal Blizzard chat window, and can be configured or removed through the normal Blizzard chat settings available by right clicking on its tab header, like anything else."] = "这个答案与前一个是一样的，除了战利品已经被移动到第4个选项卡，被称为'Loot'。 这也只是一个普通的Blizzard聊天窗口，可以通过右键点击它的标签头，通过一般的Blizzard聊天设置进行配置或删除."
L["\n|cffffd200" .. "How can I scroll to the top or bottom of the chat frames?" .. "|r"] = "\n|cffffd200" .. "如何滚动到聊天框架的顶部或底部？" .. "|r"
L["By holding down the Shift key while moving the mouse wheel upwards or downwards, the chat frame will scroll to the very top or bottom."] = "在向上或向下移动鼠标滚轮的同时按住Shift键，聊天框架将滚动到最上方或底部."
L["\n|cffffd200" .. "I can't click on any links in the chat frames!" .. "|r"] = "\n|cffffd200" .. "我无法点击聊天框架中的任何链接!" .. "|r"
L["You've probably made the window non-interactive. This is a Blizzard setting which can be changed by right clicking on the chat window's tab header, and selecting 'Make interactive'. Be more careful what you click in the future!"] = "你可能使窗口非互动。 这是一个暴雪设置，可以通过右键点击聊天窗口的标签页，并选择“Make interactive”来进行更改。 更加小心未来您点击的内容!"

-- options menu, chat fading
L["|n|cffffd200" .. "Chat Frame Fading" .. "|r"] = "|n|cffffd200" .. "聊天框架渐隐" .. "|r"
L["By default the messages in the chat frames fade out after a certain amount of time. Here you can toggle this behavior or change its settings.|n"] = "默认情况下，聊天框中的消息会在一定时间后淡出。 在这里，您可以切换此行为或更改其设置.|n"
L["Fade out the chat messages."] = "淡出聊天消息."
L["Fades out chat messages after a certain period of time. Uncheck to keep the chat visible at all times."] = "在一段时间后淡出聊天信息。 取消选中以保持聊天随时可见."
L["|n|cffffd200" .. "Display Duration" .. "|r"] = "|n|cffffd200" .. "显示持续时间" .. "|r"
L["Set how long in seconds the chat messages remain visible before fading out."] = "设置聊天消息在淡出之前保持可见的秒数."
L["|n|cffffd200" .. "Fade Duration" .. "|r"] = "|n|cffffd200" .. "褪色持续时间" .. "|r"
L["Set how much time the chat messages will spend fading out in seconds."] = "设置聊天消息在几秒钟内消失的时间."



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's DevTools
-------------------------------------------------------
-------------------------------------------------------

L["Goldpaw's Developer Tools"] = "Goldpaw的开发工具"
L["Reload the user interface"] = "重新加载用户界面"
L["Activate fullscreen mode"] = "激活全屏模式"
L["Activate windowed mode"] = "激活窗口模式"
L["Activating Primary Specialization"] = "激活主要专业"
L["Activating Secondary Specialization"] = "激活二级专业"



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's GroupFrames
-------------------------------------------------------
-------------------------------------------------------

-- system messages
L["You need to update to build r%s or higher of Goldpaw's UI(core) in order to use Goldpaw's GroupFrames!"] = "您需要更新以构建Goldpaw的UI（核心）的r%s或更高版本，才能使用Goldpaw的GroupFrames!"

-- /glock
L["Group Leader Tools"] = "组长工具|n|cffff0000锁定组框架固定于此!"
L["Group Leader Tools Toggle"] = "切换队长工具"

-- raid leader tools
L["Disband Group"] = "解散组"
L["This will disband your group. Are you sure?"] = "这将解散你的团队。 你确定?"
L["Group Members: |cffffffff%s|r"] = "小组成员: |cffffffff%s|r"
L["Group Members: |cffffffff%s|r/|cffffffff%s|r"] = "小组成员: |cffffffff%s|r/|cffffffff%s|r"

-- options menu
L["GroupFrames"] = "组框架"

-- options menu, auras
L["Display important auras on the Group Frames."] = "在群组框架上显示重要的光环."
L["Shows important auras such as boss debuffs, dispellable debuffs for dispellers  and Disc Priest Atonement on the Group Frames."] = "显示重要的光环，如BOSS debuffs，可拆卸的debuffs为驱散器和光盘牧师赎罪组框架."
L["5 Player Groups"] = "5 玩家组"
L["\n|cffffd200" .. "5 Player Group Aura Visibility" .. "|r"] = "\n|cffffd200" .. "5人小队光环可见性" .. "|r"
L["Select whether or not to show the 5 player group aura widgets. Deselecting a widget will override all other settings."] = "选择是否显示5个玩家组的光环小部件。 取消选择一个小部件将覆盖所有其他设置."
L["Display buffs and debuffs on the 5 Player Group Frames."] = "显示5 人组框架上的buff和debuff."
L["Shows the normal buffs and debuffs on the 5 Player Group Frames."] = "显示5 人组框架上的正常buff和debuff."

-- options menu, groups
L["General"] = "一般"

-- options menu, faq
L["\n|cffffd200" .. "How can I toggle the display of debuffs on the Group Frames?" .. "|r"] = "\n|cffffd200" .. "如何在组框架上切换debuffs的显示?" .. "|r"
L["To toggle this option, open the /gui options menu, go to the Auras submenu, and then choose the Group Frames tab."] = "要切换此选项，请打开/ gui选项菜单，转到光环子菜单，然后选择“组帧”选项卡."



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's Minimap
-------------------------------------------------------
-------------------------------------------------------

-- system messages
L["You need to update to build r133 or higher of Goldpaw's UI(core) in order to access the new Garrison Report button!"] = "您需要更新以构建rp313或更高版本的Goldpaw的UI（核心）才能访问新的“驻军报告”按钮！"

-- performance widget
L["Network Stats"] = "网络统计"
L["World latency %s:"] = "世界延迟 %s:"
L["(Combat, Casting, Professions, NPCs, etc)"] = "(战斗、施法、职业、NPC等)"
L["Home latency %s:"] = "本地延迟 %s:"
L["(Chat, Auction House, etc)"] = "(聊天，拍卖行等)"

-- mail widget
L["New Mail!"] = "新邮件!"

-- middle-click menu
L["Calendar"] = "日历"

-- options menu
L["Minimap"] = "小地图"
L["Use 24-hour clock."] = "使用24小时制."
L["Toggles the use of the normal 24-hour clock."] = "切换使用正常的24小时制."
L["Use realm time."] = "使用服务器时间."
L["Toggles the use of the time as reported by your current realm."] = "切换您当前领域报道的时间的使用."
L["Show Garrison Report button."] = "显示职业大厅按钮."
L["Toggles the display of the Garrison Report button."] = "切换“职业大厅”按钮的显示."



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

L["Objectives"] = "目标"
L["World Score"] = "世界得分"
L["Vehicle Seat"] = "马具座椅"
L["Graveyard Teleport"] = "墓地传送"
L["ZoneText"] = "区域文本"
L["Capture Bar"] = "捕获条"
L["Talking Head Frame"] = "NPC对话"



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's Tooltip
-------------------------------------------------------
-------------------------------------------------------

L["Ghost"] = "灵魂" -- refers to your spirit form when you're running towards your corpse after dying
L["Boss Debuff: "] = "Boss Debuff: " 
L["Caster: "] = "施法者: " -- as in "the caster of the buff"
L["Item ID: "] = "Item ID: "
L["Item Level: "] = "Item Level: "
L["Item Sets: "] = "Item Sets: "
L["Item crafter: "] = "Item crafter: "
L["Spell ID: "] = "Spell ID: "
L["Targeting: "] = "目标: " -- as in "Paul is targeting Vera"

L["Tooltip"] = "鼠标提示"

-- options menu
L["Tooltips"] = "鼠标提示"
L["General"] = "一般"
L["All Tooltips"] = "所有的提示"
L["Hide blank lines."] = "隐藏空行."
L["Removes blank or empty lines from the tooltip."] = "从工具提示中删除空行或空行."
L["Unit Tooltips"] = "单位工具提示"
L["|n|cffffd200" .. "Unit Names" .. "|r"] = "|n|cffffd200" .. "单位名字" .. "|r"
L["Select how a character's name is displayed in the tooltip and what elements are included.|n|n"] = "选择工具提示中显示一个字符的名称以及包含哪些元素.|n|n"
L["Show player realm."] = "显示玩家领域."
L["Displays the realm name of players next to their name."] = "显示名称旁边玩家的领域名称."
L["Show player title."] = "显示玩家标题."
L["Displays the currently selected title of players next to their name."] = "显示当前选中的名称旁边的玩家名称."
L["Show player gender."] = "显示玩家性别."
L["Displays the gender of player characters next to their level, race and class."] = "显示玩家角色在他们的等级，种族和类别旁边的性别。"
L["|n|cffffd200" .. "Additional Unit Info" .. "|r"] = "|n|cffffd200".."附加单位信息".."|r"
L["Choose whether or not to show additional unit info like who the unit is targeting, it's current power and so on.|n|n"] = "选择是否显示额外的单位信息，如单位所在的人，目前的权力等等。|n|n"
L["Show power bars."] = "显示电源杆”。"
L["Displays power bars below the unit health bar when available."] = "在可用时显示设备健康状况栏下方的电源线”。"
L["Show unit target."] = "显示单位目标”。"
L["Displays who or what the unit is currently targeting."] = "显示单位目前定位的人员或单位。"
L["Item Tooltips"] = "Item Tooltips"
L["|n|cffffd200" .. "Item Information" .. "|r"] = "|n|cffffd200".."项目信息".."|r"
L["Toggle general information about the item's power or price."] = "切换关于项目权力或价格的一般信息。"
L["Hide item level."] = "隐藏项目级别”。"
L["Hides the item level describing the overall power of this item from the tooltip."] = "隐藏从工具提示中描述此项目的总体权力的项目级别。"
L["Hide item ID."] = "隐藏项目ID”。"
L["Hides the item ID of this item from the tooltip. Item IDs are used to identify items by the game, as well as most fansites like www.wowhead.com and similar."] = "从工具提示中隐藏此项目的项目ID。项目ID用于识别游戏中的项目，以及像www.wowhead.com和类似的大多数球迷。"
L["Hide sell value."] = "隐藏卖出价值”。"
L["Hides the sell value of this item from the tooltip."] = "从工具提示中隐藏此项目的销售价值。"
L["Hide item crafter."] = "隐藏项目crafter”。"
L["Hides who the crafter of the current items is."] = "隐藏当前项目的手稿”。"
L["|n|cffffd200" .. "Item Sets & Bonuses" .. "|r"] = "|n|cffffd200".."项集和奖金".."|r"
L["Toggle information about what equipment manager sets you have included this item in, as well as what gear sets this item belongs to and what bonuses they bring."] = "切换关于您已经将此项目包含在哪些设备管理器中的信息，以及该项目所属的齿轮组以及它们带来的奖金。"
L["Hide Equipment Manager sets the item is part of."] = "隐藏设备管理器设置项目是”的一部分。"
L["Hides what Equipment Manager sets the item is a part of."] = "隐藏设备管理器设置项目的一部分。"
L["Hide the list of items in the current gear set."] = "隐藏当前齿轮组中的项目列表”。"
L["Hides the list of items in item sets such as Cenarion Rayment and Gladiator's Sanctuary. Only the set name and number of current items will be displayed."] = "隐藏Cenarion Rayment和Gladiator's Sanctuary等项目集中的项目列表，只显示当前项目的集合名称和数量。"
L["|n|cffffd200" .. "Item Transmogrification" .. "|r"] = "|n|cffffd200".."项目Transmogrification".."|r"
L["Item transmogrification is when an item is made to look like something else. This can also apply to illusions like custom weapon enchant glows created with the Enchanter's Study in your Garrison."] = "物品变化是当一个物品看起来像其他东西，这也可以应用于幻影，如用你的驻军的魔法学习研究创造的定制武器附魔光。"
L["Hide transmogrifications."] = "隐藏变异”。"
L["Hides the transmogrification description from items that have been transmogrified to look like something else."] = "把传播的东西隐藏起来，看起来像别的东西。"
L["Only hide the transmogrification labels."] = "只能隐藏变色标签”。"
L["Only hides the label indicating that an item has been transmogrified. Does not affect the transmogrification description itself."] = "只隐藏标签，表示一个项目已经发生变化，不影响变化描述本身。"
L["|n|cffffd200" .. "Item Enchantments" .. "|r"] = "|n|cffffd200".."项目附魔".."|r"
L["Item enchantments can refer to any sort added or created enhancement on an item."] = "项目附魔可以指在项目上添加或创建的任何排序。"
L["Hide enchantments."] = "隐藏附魔”。"
L["Hides all enchantments on this item."] = "隐藏此项目的所有附魔”。"
L["Only hide the enchantment label."] = "只隐藏附魔标签”。"
L["Only hides the label indicating that it's an enchantment, but displays the enchantment details."] = "只隐藏标签，表示它是一个附魔，但显示附魔细节。"
L["|n|cffffd200" .. "Item Requirements" .. "|r"] = "|n|cffffd200".."项目要求".."|r"
L["Some items have requirements in order to use them. This can include level, race, class, reputation and a variety of other things."] = "有些项目有要求使用它们，这可以包括水平，种族，阶级，声誉和各种其他的东西。"
L["Hide requirements."] = "隐藏要求"
L["Hides all requirements to wear this item, like race, class or level."] = "隐藏所有要求穿戴这个项目，比如种族，阶级或阶级。"
L["Only hide met requirements."] = "只隐藏满足要求”。"
L["Hides requirements to wear this item if they are met, but displays them otherwise."] = "如果符合要求，则隐藏该项目，否则会显示"
L["|n|cffffd200" .. "Item Requirements" .. "|r"] = "|n|cffffd200".."项目要求".."|r"
L["Some items have requirements in order to use them. This can include level, race, class, reputation and a variety of other things."] = "有些项目有要求使用它们，这可以包括水平，种族，阶级，声誉和各种其他的东西。"



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's Trade
-------------------------------------------------------
-------------------------------------------------------

-- merchant module
L["<Alt-Click to buy the maximum amount>"] = "<Alt-Click购买最大金额>"
L["-%s|cFF00DDDDx%d|r %s"] = " - %s |cFF00DDDDx%d |r%s"
L["Earned %s"] = "Earned%s"
L["You repaired your items for %s using Guild Bank funds"] = "您使用公会银行资金修复您的商品%s"
L["You repaired your items for %s"] = "您为%s修理了您的项目"
L["|cffff0000%s|r"] = "|cffff0000%s |r"
L["You haven't got enough available funds to repair!"] = "你还没有足够的可用资金来修复！"
L["Your profit is %s"] = "你的利润是%s"
L["Your expenses are %s"] = "你的开销是%s"

-- money module
L["Goldpaw's UI: Gold"] = "Goldpaw的UI：金"

-- durability module
L["Goldpaw's UI: Durability"] = "Goldpaw的UI：耐久度"

-- options menu
L["Merchants"] = "Merchants"
L["Merchants & Trade"] = "商户与贸易"
L["Automatically repair your equipment."] = "自动修理您的设备。"
L["Automatically repair your equipment when visiting a merchant with repair capabilities. This is limited by your available funds."] = "访问具有维修能力的商家时自动修理您的设备，这受到您可用资金的限制。"
L["Use guild funds to repair."] = "使用公会资金修复"
L["Use guild funds to repair your gear when available, instead of using your personal gold. This is limited by your daily available funds set by the guild master of your guild."] = "使用公会资金修复您的装备，而不是使用您的个人黄金，这受到公会公会大师设定的每日可用资金的限制。"
L["Automatically sell garbage."] = "自动出售垃圾”。"
L["Automatically sells gray quality loot in your inventory when visiting a merchant."] = "访问商家时，您的库存中会自动出售灰色质量战利品。"
L["Display a detailed sales report."] = "显示详细的销售报告”。"
L["Displays a detailed report of every item sold when enabled. Disabled to just show the profit or expenses as a total."] = "显示启用时销售的所有项目的详细报告。禁用以显示总体的利润或费用。"



-------------------------------------------------------
-------------------------------------------------------
-- Goldpaw's UnitFrames
-------------------------------------------------------
-------------------------------------------------------

-- system messages
L["You need to update to build r%s or higher of Goldpaw's UI(core) in order for the Boss frames to be shown!"] = "您需要更新以构建Goldpaw的UI（内核）的r%s或更高版本，以便显示Boss框架!"
L["You need to update to build r%s or higher of Goldpaw's UI(core) to use Goldpaw's UnitFrames!"] = "您需要更新以构建Goldpaw的UI（核心）的r%s或更高版本才能使用Goldpaw的UnitFrames！"

L["RP"] = "RP" -- display text button for MyRolePlay and totalRP2

-- module display names. the index is the actual module name, so don't change it. 
L["Player"] = "玩家"
L["AltPowerBar"] = "能量条"
L["ClassBar"] = "资源条"
L["Pet"] = "宠物"
L["PetTarget"] = "宠物目标"
L["Target"] = "目标"
L["ToT"] = "目标的目标"
L["ToTTarget"] = "目标的目标的目标"
L["Focus"] = "焦点"
L["FocusTarget"] = "焦点目标"
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
L["UnitFrames"] = "单位"

-- player aura options
L["\n|cffffd200" .. "Player Aura Visibility" .. "|r"] = "\n|cffffd200".."玩家光环可见性".."|r"
L["Select whether or not to show the player aura widgets. Deselecting a widget will override all other settings."] = "选择是否显示播放器光环小部件。取消选择小部件将覆盖所有其他设置。"
L["Display Player Buffs"] = "显示玩家增益"
L["Display benefitial auras"] = "显示有益光环"
L["Display Player Debuffs"] = "显示玩家减益"
L["Display harmful auras"] = "显示有害的无光"
L["\n|cffffd200" .. "Player Aura Filters" .. "|r"] = "\n|cffffd200".."玩家光环过滤器".."|r"
L["Toggle filters related to what auras are shown at what times."] = "切换过滤器与什么时候显示的是哪个光环有关"
L["Only apply filters while engaged in combat."] = "只在作战时应用过滤器”。"
L["Only apply the aura filters while you are engaged in combat, and show every aura unfiltered otherwise."] = "只有在你参与战斗时才应用光环过滤器，否则就会显示出没有过滤的每个光环。"
L["Hide auras not cast by the player"] = "隐藏光环不被演员投射"
L["Hide auras eligible for consolidation."] = "隐藏有资格进行合并的光环。"
L["Hide auras with a very long duration like Mark of the Wild or similar."] = "隐藏有很长一段时间的光环，如野马或类似的”。"
L["Hide long duration auras."] = "隐藏长时间的光环。"
L["Hide auras with a duration above 60 seconds. This includes food buffs."] = "隐藏超过60秒的光环，包括食物迷”。"
L["Hide static auras."] = "隐藏静音”。"
L["Hide static auras that lack a duration, like mounts, feral forms, auras from group members and so on."] = "隐藏缺乏持续时间的静态光环，如骑士，野蛮形式，小组成员的光环等等。"
L["Always Show Stealable Buffs"] = "始终显示可放置的buffs"
L["Always display buffs that can be stolen. Overrides other choices."] = "总是显示可以被盗的buff，覆盖其他选择。"
L["Always Show Boss Debuffs"] = "总是显示boss debuff"
L["Always display debuffs cast by a boss. Overrides other choices."] = "总是显示老板施放的debuff，覆盖其他选择。"

-- pet aura options
L["Display Pet Auras"] = "Display Pet Auras"
L["Display auras on the pet frame"] = "在宠物框架上显示光环"
L["\n|cffffd200" .. "Pet Aura Visibility" .. "|r"] = "\n|cffffd200".."宠物光环可见性".."|r"
L["Select whether or not to show the pet aura widget. Deselecting a widget will override all other settings."] = "选择是否显示宠物光环小部件。取消选择小部件将覆盖所有其他设置。"
L["\n|cffffd200" .. "Pet Aura Filters" .. "|r"] = "\n|cffffd200".."宠物光环过滤器".."|r"

-- target aura options
L["\n|cffffd200" .. "Target Aura Visibility" .. "|r"] = "\n|cffffd200".."目标光环可见性".."|r"
L["Select whether or not to show the target aura widgets. Deselecting a widget will override all other settings."] = "选择是否显示目标光环小部件。取消选择小部件将覆盖所有其他设置。"
L["Display Target Buffs"] = "显示目标增益"
-- L["Display benefitial auras"] = true
L["Display Target Debuffs"] = "显示目标Debuffs"
-- L["Display harmful auras"] = true
L["\n|cffffd200" .. "Target Aura Filters" .. "|r"] = "\n|cffffd200".."目标光环过滤器".."|r"
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
L["Display Target of Target Auras"] = "目标的目标光环"
L["Display auras on the target's target's frame"] = "在目标的目标帧上显示光环"
L["\n|cffffd200" .. "Target of Target Aura Visibility" .. "|r"] = "\n|cffffd200".."目标光环目标".."|r"
L["Select whether or not to show the target's target aura widget. Deselecting a widget will override all other settings."] = "选择是否显示目标的目标光环小部件。取消选择小部件将覆盖所有其他设置。"
L["\n|cffffd200" .. "Target of Target Aura Filters" .. "|r"] = "\n|cffffd200".."目标光环过滤器目标".."|r" 

-- focus aura options
L["Display Focus Target Auras"] = "显示焦点目标光环"
L["Display auras on the focus target's frame"] = "在焦点对象的框架上显示光环"
L["\n|cffffd200" .. "Focus Target Aura Visibility" .. "|r"] = "\n|cffffd200".."对焦目标光环可见性".."|r"
L["Select whether or not to show the focus target aura widget. Deselecting a widget will override all other settings."] = "选择是否显示对焦目标光环小部件。取消选择小部件将覆盖所有其他设置。"
L["\n|cffffd200" .. "Focus Target Aura Filters" .. "|r"] = "\n|cffffd200".."对焦目标光环滤波器".."|r"

-- unit visibility
L["Unit Visibility"] = "单位可见度"
L["Here you can manually decide whether or not to show specific units. But be aware that disabling an object such as the player or the target, may lead to connected unitframes changing positions."] = "这里你可以手动决定是否显示特定的单位，但请注意，禁用诸如播放器或目标的对象可能导致连接的单位框架更改位置。"
L["Enable Player Frame"] = "启用播放器帧"
L["Toggle the display of the player's unit frame."] = "切换播放器单位框架的显示。"
L["Enable Player Resource Bars"] = "启用播放器资源条"
L["Toggle the display of the player's resource bars."] = "切换播放器资源栏的显示。"
L["Enable Pet Frame"] = "启用宠物框"
L["Toggle the display of your pet's unit frame."] = "切换宠物单位框架的显示。"
L["Enable Pet Target Frame"] = "启用宠物目标帧"
L["Toggle the display of your pet's target's unit frame."] = "切换宠物目标单位框架的显示。"
L["Enable Target Frame"] = "启用目标帧"
L["Toggle the display of the target's unit frame."] = "切换目标单位框架的显示。"
L["Enable Target's Target Frame"] = "启用目标的目标帧"
L["Toggle the display of the target's target's unit frame."] = "切换目标的目标单位框架的显示。"
L["Enable Target's Target's Target Frame"] = "启用目标目标的目标帧"
L["Toggle the display of the target's target's target unit frame."] = "切换目标的目标单位框架的显示。"
L["Enable Focus Target Frame"] = "启用对焦框"
L["Toggle the display of the focus target's unit frame."] = "切换对焦目标单位框架的显示。"
L["Enable Focus Target's Target Frame"] = "启用焦点目标的目标帧"
L["Toggle the display of the focus target's target's unit frame."] = "切换对焦目标的单位框架的显示。"
L["Enable Boss Frames"] = "启用Boss框架"
L["Toggle the display of the boss frames."] = "切换boss框架的显示。"

