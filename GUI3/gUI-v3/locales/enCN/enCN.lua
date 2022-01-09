local L = LibStub("gLocale-2.0"):NewLocale((select(1, ...)), "enCN", false)
if not L then return end

--[[
	All Chinese locales by Banz Lin
]]--

--------------------------------------------------------------------------------------------------
--		Modules
--------------------------------------------------------------------------------------------------
-- ActionBars
do
	L["Layout '%s' doesn't exist, valid values are %s."] = "%s 样式不存在，错误代码为 %s."
	L["There is a problem with your ActionBars.|nThe user interface needs to be reloaded in order to fix it.|nReload now?"] = "动作条出现问题.|n要修正问题必须重新载入介面.|n现在重新载入?"
	L["<Left-Click> to show additional ActionBars"] = "左键点击显示额外的动作条"
	L["<Left-Click> to hide this ActionBar"] = "左键点击隐藏此动作条"
	L["PetBar"] = "宠物列" -- *v3
	L["StanceBar"] = "姿态列" -- *v3
	L["TotemBar"] = "图腾列" -- *v3
	L["MicroMenu"] = "微型选单" -- *v3
	L["ActionBar%s"] = "动作条 %s" -- *v3
	L["ExtraActionButton"] = "额外的动作条" -- *v3
	L["Set to vertical orientation"] = "垂直排列" -- *v3
	L["Set to horizontal orientation"] = "水平排列" -- *v3
	L["Set number of buttons on each row"] = "每一行按钮数量" -- *v3
	L["Show always"] = "总是显示" -- *v3
	L["Show on mouseover"] = "鼠标悬停显示" -- *v3
	L["Hide always"] = "总是隐藏" -- *v3
end

-- ActionBars: micromenu
do
	L["Achievements"] = "成就"
	L["Character Info"] = "角色信息"
	L["Customer Support"] = "客服支持"
	L["Dungeon Finder"] = "地城搜寻器"
	L["Dungeon Journal"] = "地城导览手册"
	L["Game Menu"] = "游戏菜单"
	L["Guild"] = "公会"
	L["Guild Finder"] = "公会搜寻器"
	L["You're not currently a member of a Guild"] = "你当前并非公会成员"
	L["Player vs Player"] = "PVP"
	L["Quest Log"] = "任务纪录"
	L["Raid"] = "团队搜寻器"
	L["Spellbook & Abilities"] = "法术书和技能"
	L["Starter Edition accounts cannot perform that action"] = "体验帐号无法执行此动作"
	L["Talents"] = "天赋"
	L["This feature becomes available once you earn a Talent Point."] = "你一但获得天赋点数，才能使用此功能。"
end

-- ActionBars: menu
do
	L["ActionBars are banks of hotkeys that allow you to quickly access abilities and inventory items. Here you can activate additional ActionBars and control their behaviors."] = "动作条是一个存放热键的工具列，可让你更快速地使用技能与物品栏的物品。你可以在这里启用额外的动作条并控制它们的功能。"
	L["Secure Ability Toggle"] = "切换技能触发保险"
	L["When selected you will be protected from toggling your abilities off if accidently hitting the button more than once in a short period of time."] = "若你不慎在短时间内按到按键，将防止关闭技能。"
	L["Lock ActionBars"] = "锁定动作条"
	L["Prevents the user from picking up/dragging spells on the action bar. This function can be bound to a function key in the keybindings interface."] = "使玩家无法拖曳动作条上的技能图标，这项功能可以透过按键设定介面来设定对应的快速键。"
	L["Pick Up Action Key"] = "拖曳动作键"
	L["ALT key"] = "ALT键"
	L["Use the \"ALT\" key to pick up/drag spells from locked actionbars."] = "配合「ALT」键从锁定的动作条上拖曳技能图标"
	L["CTRL key"] = "CTRL键"
	L["Use the \"CTRL\" key to pick up/drag spells from locked actionbars."] = "配合「CTRL」键从锁定的动作条上拖曳技能图标"
	L["SHIFT key"] = "SHIFT键"
	L["Use the \"SHIFT\" key to pick up/drag spells from locked actionbars."] = "配合「SHIFT」键从锁定的动作条上拖曳技能图标"
	L["None"] = "无"
	L["No key set."] = "未设定按键"
	L["Visible ActionBars"] = "显示动作条"
	
	-- v3 layout 1, treating the bars as separate ones
	L["Micro Menu"] = "微型菜单" -- *v3
	L["Shapeshift/Aspect/Stance Bar"] = "姿态条" -- *v3
	L["Pet ActionBar"] = "宠物条" -- *v3
	L["Leftmost Side ActionBar [5]"] = "右侧动作条 [5]" -- *v3
	L["Rightmost Side ActionBar [4]"] = "右侧动作条 [4]" -- *v3
	L["Bottom Right ActionBar [3b]"] = "底部右边动作条 [3b]" -- *v3
	L["Bottom Left ActionBar [3a]"] = "底部左边动作条 [3a]" -- *v3
	L["Bottom ActionBar [2]"] = "底部动作条 [2]" -- *v3
	L["Main ActionBar [1]"] = "主要动作条 [1]" -- *v3
	
	L["Show the bottom ActionBar [2]"] = "显示底部动作条 [2]" -- *v3
	L["Show the bottom left ActionBar [3a]"] = "显示底部左边动作条 [3a]" -- *v3
	L["Show the bottom right ActionBar [3b]"] = "显示底部右边动作条 [3b]" -- *v3
	L["Show the rightmost side ActionBar [4]"] = "显示右侧动作条 [4]"
	L["Show the leftmost side ActionBar [5]"] = "显示右侧动作条 [5]"
	L["Show the Pet ActionBar"] = "显示宠物动作条"
	L["Show the Shapeshift/Stance/Aspect Bar"] = "显示姿态条"
	L["Show the Micro Menu"] = "显示微型选单"

	L["Show the secondary ActionBar"] = "显示第二动作条"
	L["Show the third ActionBar"] = "显示第三动作条"

	L["VehicleExitButton"] = "离开载具按钮" -- *v3

	-- L["Show the Totem Bar"] = "显示图腾动作条" -- doesn't exist anymore
	-- L["ActionBar Layout"] = "动作条样式"
	-- L["Sort ActionBars from top to bottom"] = "从上到下排列动作条"
	-- L["This displays the main ActionBar on top, and is the default behavior of the UI. Disable to display the main ActionBar at the bottom."] = "在上方显示主要动作条，这是UI默认，取消选择则显示在下方。"

	L["Button Size"] = "按钮大小"
	L["Set the size of the bar's buttons"] = "设定动作条按钮大小"
	L["Bar Width"] = "动作条宽度" -- *v3
	L["Choose the size of the buttons in your ActionBars"] = "设定动作条按钮的大小"
	L["Sets the size of the buttons in your ActionBars. Does not apply to the TotemBar."] = "设定动作条按钮的大小，但此设定并不套用到图腾动作条上。"


	L["Page Switching"] = "切换主要动作条" -- *v3
	L["Here you can enable extra pageswitching for the main ActionBar for some classes."] = "你可以启用在某些职业下切换主要动作条" -- *v3
	L["Use Druid Prowl Bar"] = "使用德鲁依潜行动作条" -- *v3
	L["Enabling this will switch to a separate bar when you use Prowl"] = "独立的潜行动作条" -- *v3
	L["Use Warlock Metamorphosis Bar"] = "使用术士恶魔化身动作条" -- *v3
	L["Enabling this will switch to a separate bar when Metamorphosis is active"] = "独立的恶魔化身动作条" -- *v3
	L["Use Rogue Shadow Dance Bar"] = "使用盗贼暗影之舞动作条" -- *v3
	L["Enabling this will switch to a separate bar when Shadow Dance is active"] = "独立的暗影之舞动作条" -- *v3
	L["Use Warrior Stance Bars"] = "使用战士姿态动作条" -- *v3
	L["Enabling this will switch to a separate bar for each of your stances"] = "每个姿态都有独立的动作条" -- *v3

end

-- ActionBars: Install
do
	L["Select Visible ActionBars"] = "选择要显示的动作条"
	L["Here you can decide what actionbars to have visible. Most actionbars can also be toggled by clicking the arrows located next to their edges which become visible when hovering over them with the mouse cursor. This does not work while engaged in combat."] = "你可以选择要显示的动作条，透过用鼠标游标悬停在动作条旁，并点击显示的箭头切换。战斗中不可使用此功能。"
	L["You can try out different layouts before proceding!"] = "继续下一步前，你可以尝试不同样式!"

	L["Toggle Bar 2"] = "第二动作条"
	L["Toggle Bar 3"] = "第三动作条"
	L["Toggle Bar 4"] = "第四动作条"
	L["Toggle Bar 5"] = "第五动作条"
	L["Toggle Pet Bar"] = "宠物动作条"
	L["Toggle Shapeshift/Stance/Aspect Bar"] = "姿态列"
	L["Toggle Totem Bar"] = "图腾动作条"
	L["Toggle Micro Menu"] = "微型选单列"
	
	L["Select Main ActionBar Position"] = "选择主要动作条位置"
	L["When having multiple actionbars visible, do you prefer to have the main actionbar displayed at the top or at the bottom? The default setting is top."] = "当有多个动作条显示时，你希望主要动作条显示在上方或下方? 默认是上方。"
end

-- ActionButtons: Keybinds (displayed on buttons)
do
	L["A"] = true -- Alt
	L["C"] = true -- Ctrl
	L["S"] = true -- Shift
	L["M"] = true -- Mouse Button
	L["M3"] = true -- Middle/Third Mouse Button
	L["N"] = true -- Numpad
	L["NL"] = true -- Numlock
	L["CL"] = true -- Capslock
	L["Clr"] = true -- Clear
	L["Del"] = true -- Delete
	L["End"] = true -- End
	L["Home"] = true -- Home
	L["Ins"] = true -- Insert
	L["Tab"] = true -- Tab
	L["Bs"] = true -- Backspace
	L["WD"] = true -- Mouse Wheel Down
	L["WU"] = true -- Mouse Wheel Up
	L["PD"] = true -- Page Down
	L["PU"] = true -- Page Up
	L["SL"] = true -- Scroll Lock
	L["Spc"] = true -- Spacebar
	L["Dn"] = true -- Down Arrow
	L["Lt"] = true -- Left Arrow
	L["Rt"] = true -- Right Arrow
	L["Up"] = true -- Up Arrow
end

-- ActionButtons: menu
do
	L["ActionButtons are buttons allowing you to use items, cast spells or run a macro with a single keypress or mouseclick. Here you can decide upon the styling and visible elements of your ActionButtons."] = "动作按钮允许您透过单一按键或是鼠标点击使用物品，法术或执行一个巨集，在这里你可以决定动作按钮的视觉样式。"
	L["Button Styling"] = "按钮样式"
	L["Button Text"] = "按钮文字"
	L["Show hotkeys on the ActionButtons"] = "在按钮上显示热键"
	L["Show Keybinds"] = "显示按键绑定"
	L["This will display your currently assigned hotkeys on the ActionButtons"] = "这会在按钮上显示你当前绑定的热键"
	L["Show macro names on the ActionButtons"] = "在按钮上显示巨集名称"
	L["Show Names"] = "显示巨集"
	L["This will display the names of your macros on the ActionButtons"] = "这会在按钮上显示巨集名称"
	L["Show gloss layer on ActionButtons"] = "在按钮上显示渐层"
	L["Show Gloss"] = "显示渐层"
	L["This will display the gloss overlay on the ActionButtons"] = "这会在按钮上显示渐层"
	L["Show shade layer on ActionButtons"] = "在按钮上显示遮罩"
	L["This will display the shade overlay on the ActionButtons"] = "这会在按钮上显示遮罩"
	L["Show Shade"] = "显示遮罩"
	--L["Set amount of gloss"] = true
	--L["Set amount of shade"] = true
end

-- Auras
do
	L["Player Buffs"] = "玩家增益" -- *v3
	L["Player Debuffs"] = "玩家减益" -- *v3
	L["These options allow you to control how buffs and debuffs are displayed. If you wish to change the position of the buffs and debuffs, you can unlock them for movement with |cFF4488FF/glock|r."] = "这些选项可控制增益与减益效果的显示方式。如果你想移动位置，你可以使用 |cFF4488FF/glock|r 指令解除锁定。"
	L["Aura Styling"] = "样式"
	L["Show gloss layer on Auras"] = "在增益减益图标上显示渐层"
	L["Show Gloss"] = "显示渐层"
	L["This will display the gloss overlay on the Auras"] = "这会在增益减益图标上显示渐层"
	L["Show shade layer on Auras"] = "在增益减益图标上显示遮罩"
	L["This will display the shade overlay on the Auras"] = "这会在增益减益图标上显示遮罩"
	L["Show Shade"] = "显示遮罩"
	L["Time Display"] = "时间显示"
	L["Show remaining time on Auras"] = "显示剩余时间"
	L["Show Time"] = "显示时间"
	L["This will display the currently remaining time on Auras where applicable"] = "这会显示当前增益减益剩余时间"
	L["Display remaining time as a timer bar instead of text"] = "使用时钟样式替代文字显示剩余时间" -- *v3
	L["Consolidate Buffs"] = "整合增减益图标" -- *v3
	L["Show cooldown spirals on Auras"] = "在增益减益图标上显示旋转倒数"
	L["Show Cooldown Spirals"] = "显示旋转倒数"
	L["This will display cooldown spirals on Auras to indicate remaining time"] = "这会在增益减益图标上显示旋转倒数"
end

-- Bags
do
	L["Gizmos"] = "小玩意" -- used for "special" things like the toy train set
	L["Equipment Sets"] = "自订套装" -- used for the stored equipment sets
	L["New Items"] = "新物品" -- used for the unsorted new items category in the bags
	L["Click to sort"] = "点击排序"
	L["<Left-Click to toggle display of the Bag Bar>"] = "<左键点击切换显示背包列>"
	L["<Left-Click to open the currency frame>"] = "<左键点击显示货币面版>"
	L["<Left-Click to open the category selection menu>"] = "<左键点击开启分类选单>"
	L["<Left-Click to search for items in your bags>"] = "<左键点击搜寻背包物品>"
	L["Close all your bags"] = "关闭所有背包"
	L["Close this category and keep it hidden"] = "关闭此分类并隐藏"
	L["Close this category and show its contents in the main container"] = "关闭此分类并将它所有物品显示在主分类中"
end

-- Bags: menus 
do
	L["A character can store items in its backpack, bags and bank. Here you can configure the appearance and behavior of these."] = "每个人物可以将物品存放在背包或银行，这里你可以设定背包的外观和行为。"
	L["Container Display"] = "显示背包"
	L["Show this category and its contents"] = "显示此分类和它的物品"
	L["Hide this category and all its contents completely"] = "隐藏此分类和它的物品"
	L["Bypass"] = "略过"
	L["Hide this category, and display its contents in the main container instead"] = "隐藏此分类并将它所有物品显示在主分类中"
	L["Choose the minimum item quality to display in this category"] = "选择此分类要显示的最小物品品质"
	L["Bag Width"] = "背包宽度"
	L["Sets the number of horizontal slots in the bag containers. Does not apply to the bank."] = "设定背包水平物品数量，此设定不会套用到银行。"
	L["Bag Scale"] = "大小比例"
	L["Sets the overall scale of the bags"] = "设定背包整体大小比例"
	L["Restack"] = "重新堆叠"
	L["Automatically restack items when opening your bags or the bank"] = "当你打开背包或银行时自动重新堆叠"
	L["Automatically restack when looting or crafting items"] = "当你获得战利品或制作物品时自动重新堆叠"
	L["Sorting"] = "排序"
	L["Sort the items within each container"] = "排序物品"
	L["Sorts the items inside each container according to rarity, item level, name and quanity. Disable to have the items remain in place."] = "依据物品稀有程度、等级、名称、数量排序。取消则不排序。"
	L["Compress empty bag slots"] = "压缩背包可用空间"
	L["Compress empty slots down to maximum one row of each type."] = "压缩背包最多显示一行可用空间"
	L["Lock the bags into place"] = "锁定背包"
	L["Slot Button Size"] = "储存格大小"
	L["Choose the size of the slot buttons in your bags."] = "设定背包储存格的大小"
	L["Sets the size of the slot buttons in your bags. Does not affect the overall scale."] = "设定背包储存格大小，此设定不覆盖背包整体大小比例设定值。"
	L["Bag scale"] = "大小比例"
	L["Button Styling"] = "储存格样式"
	L["Show gloss layer on buttons"] = "在储存格上显示渐层"
	L["Show Gloss"] = "显示渐层"
	L["This will display the gloss overlay on the buttons"] = "这会在储存格上显示渐层"
	L["Show shade layer on buttons"] = "在储存格上显示遮罩"
	L["This will display the shade overlay on the buttons"] = "这会在储存格上显示遮罩"
	L["Show Shade"] = "显示遮罩"
	L["Show Durability"] = "显示耐久度"
	L["This will display durability on damaged items in your bags"] = "这会在物品上显示耐久度"
	L["Color unequippable items red"] = "将无法装备物品显示成红色"
	L["This will color equippable items in your bags that you are unable to equip red"] = "这会将你背包里你无法装备的物品显示成红色"
	L["Layout Presets"] = "内建版面" -- *v3
	L["Apply 'All In One' Layout"] = "套用整合样式背包"
	L["Click here to automatically configure the bags and bank to be displayed as large unsorted containers."] = "点击此处自动将背包及银行设定成显示成整合样式背包"
	L["Apply %s's Layout"] = "套用 %s 的版面"
	L["Click here to apply the default layout with categories, sorting and empty space compression."] = "点击这里套用默认版面，依照分类排序及压缩可用空间" -- *v3
	L["The bags can be configured to work as one large 'all-in-one' container, with no categories, no sorting and no empty space compression. If you wish to have that type of layout, click the button:"] = "背包可设定成无分类、无排序、无空间压缩之整合样式背包，如果你想要这种样式背包，点击这个按钮："
	L["The 'New Items' category will display newly acquired items if enabled. Here you can set which categories and rarities to include."] = "如果启用此设定，新获得的物品会显示在新物品分类，你可以设定要包含哪种类别及稀有程度。"
	L["Minimum item quality"] = "最低物品品质"
	L["Choose the minimum item rarity to be included in the 'New Items' category."] = "选择在新物品类别中要显示的最低物品品质"
end

-- Bags: Install
do
	L["Select Layout"] = "选择样式"
	L["The %s bag module has a variety of configuration options for display, layout and sorting."] = "%s 背包模块有不同显示样式及排序设定选项。"
	L["The two most popular has proven to be %s's default layout, and the 'All In One' layout."] = "两种常用模式：默认的 %s 背包及整合式背包"
	L["The 'All In One' layout features all your bags and bank displayed as singular large containers, with no categories, no sorting and no empty space compression. This is the layout for those that prefer to sort and control things themselves."] = "整合模式将你身上及银行所有包包整合成一超大包包，不做分类、不排序、不压缩空格，此模式是给喜欢自己排列及控制物品位置的玩家。"
	L["%s's layout features the opposite, with all categories split into separate containers, and sorted within those containers by rarity, item level, stack size and item name. This layout also compresses empty slots to take up less screen space."] = "%s 模式则相反，将物品分类，每个分类依物品品质、等级、堆叠数量、名称排序，并压缩背包空间以节省屏幕空间。"
	L["You can open your bags to test out the different layouts before proceding!"] = "继续下一步前，你可以开启背包测试不同样式!"
	L["Apply %s's Layout"] = "套用 %s 样式"
end

-- Bags: chat commands
do
	L["Empty bag slots will now be compressed"] = "背包空间将会被压缩"
	L["Empty bag slots will no longer be compressed"] = "背包空间不会被压缩"
end

-- Bags: restack
do
	L["Restack is already running, use |cFF4488FF/restackbags resume|r if stuck"] = "重新堆叠已在执行，如果无动作，使用 |cFF4488FF/restackbags resume|r 指令"
	L["Resuming restack operation"] = "重启重新堆叠作业"
	L["No running restack operation to resume"] = "不，执行重新堆叠作业"
	L["<Left-Click to restack the items in your bags>"] = "<左键点击重新堆叠物品>"
	L["<Left-Click to restack the items in your bags>|n<Right-Click for options>"] = "<左键点击重新堆叠物品>|n<右键开启选单>"
end

-- Castbars: menu
do
	L["Here you can change the size and visibility of the on-screen castbars. If you wish to change their position, you can unlock them for movement with |cFF4488FF/glock|r."] = "你可以改变施法条的大小及外观，如果你想改变施法条的位置，你可以使用 |cFF4488FF/glock|r 指令解除锁定"
	L["Show the player castbar"] = "显示玩家施法条"
	L["Show for tradeskills"] = "显示专业技能"
	L["Show the pet castbar"] = "显示宠物施法条"
	L["Show the target castbar"] = "显示目标施法条"
	L["Show the focus target castbar"] = "显示专注目标施法条"
	L["Set Width"] = "宽度设定"
	L["Set the width of the bar"] = "设定施法条的宽度"
	L["Set Height"] = "高度设定"
	L["Set the height of the bar"] = "设定施法条的高度"
end

-- Chat: timestamp settings tooltip (http://www.lua.org/pil/22.1.html)
do
	L["|cFFFFD100%a|r abbreviated weekday name (e.g., Wed)"] = "|cFFFFD100%a|r 星期缩写 (e.g., Wed)"
	L["|cFFFFD100%A|r full weekday name (e.g., Wednesday)"] = "|cFFFFD100%A|r 星期全名 (e.g., Wednesday)"
	L["|cFFFFD100%b|r abbreviated month name (e.g., Sep)"] = "|cFFFFD100%b|r 月份缩写 (e.g., Sep)"
	L["|cFFFFD100%B|r full month name (e.g., September)"] = "|cFFFFD100%B|r 月份全名 (e.g., September)"
	L["|cFFFFD100%c|r date and time (e.g., 09/16/98 23:48:10)"] = "|cFFFFD100%c|r 日期与时间 (e.g., 09/16/98 23:48:10)"
	L["|cFFFFD100%d|r day of the month (16) [01-31]"] = "|cFFFFD100%d|r 日期 (16) [01-31]"
	L["|cFFFFD100%H|r hour, using a 24-hour clock (23) [00-23]"] = "|cFFFFD100%H|r 小时, 24时制 (23) [00-23]"
	L["|cFFFFD100%I|r hour, using a 12-hour clock (11) [01-12]"] = "|cFFFFD100%I|r 小时, 12时制 (11) [01-12]"
	L["|cFFFFD100%M|r minute (48) [00-59]"] = "|cFFFFD100%M|r 分 (48) [00-59]"
	L["|cFFFFD100%m|r month (09) [01-12]"] = "|cFFFFD100%m|r 月份数字 (09) [01-12]"
	L["|cFFFFD100%p|r either 'am' or 'pm'"] = "|cFFFFD100%p|r am 或 pm"
	L["|cFFFFD100%S|r second (10) [00-61]"] = "|cFFFFD100%S|r 秒 (10) [00-61]"
	L["|cFFFFD100%w|r weekday (3) [0-6 = Sunday-Saturday]"] = "|cFFFFD100%w|r weekday (3) [0-6 = Sunday-Saturday]"
	L["|cFFFFD100%x|r date (e.g., 09/16/98)"] = "|cFFFFD100%x|r 日期 (e.g., 09/16/98)"
	L["|cFFFFD100%X|r time (e.g., 23:48:10)"] = "|cFFFFD100%X|r 时间 (e.g., 23:48:10)"
	L["|cFFFFD100%Y|r full year (1998)"] = "|cFFFFD100%Y|r 四位数年份 (1998)"
	L["|cFFFFD100%y|r two-digit year (98) [00-99]"] = "|cFFFFD100%y|r 二位数年份 (98) [00-99]"
	L["|cFFFFD100%%|r the character `%´"] = "|cFFFFD100%%|r 字符 %" -- 'character' here refers to a letter or number, not a game character...
end

-- Chat: names of the chat frames handled by the addon
do
	L["Main"] = "综合"
	L["Loot"] = "战利品"
	L["Log"] = "战斗纪录"
	L["Public"] = "公用"
end

-- Chat: abbreviated channel names
do
	L["G"] = true -- Guild
	L["O"] = true -- Officer
	L["P"] = true -- Party
	L["PL"] = true -- Party Leader
	L["DG"] = true -- Dungeon Guide
	L["R"] = true -- Raid
	L["RL"] = true -- Raid Leader
	L["RW"] = true -- Raid Warning
	L["I"] = true -- Instance (new in 5.1)
	L["IL"] = true -- Instance Leader (new in 5.1)
	L["BG"] = true -- Battleground (deprecated in 5.1)
	L["BGL"] = true -- Battleground Leader (deprecated in 5.1)
	L["GM"] = true -- Game Master
end

-- Chat: various abbreviations
do
	L["Guild XP"] = "公会经验值" -- Guild Experience
	L["HK"] = "荣誉击杀" -- Honorable Kill
	L["XP"] = "经验值" -- Experience
end

-- Chat: menu
do
	L["Here you can change the settings of the chat windows and chat bubbles. |n|n|cFFFF0000If you wish to change visible chat channels and messages within a chat window, background color, font size, or the class coloring of character names, then Right-Click the chat tab located above the relevant chat window instead.|r"] = "你可以改变聊天窗口及对话泡泡的设定。 |n|n|cFFFF0000如果你想要改变聊天窗口所显示的频道、讯息、背景、字体大小和职业颜色，右键点击聊天窗口上方的页签。|r"
	L["Enable sound alerts when receiving whispers or private Battle.net messages."] = "当收到密语或是 Battle.net 讯息时启用声音警示"

	L["Chat Display"] = "显示设定"
	L["Abbreviate channel names."] = "频道名称缩写"
	L["Abbreviate global strings for a cleaner chat."] = "通用名称缩写"
	L["Display brackets around player- and channel names."] = "将玩家及频道名称括号显示"
	L["Use emoticons in the chat"] = "聊天窗口中使用表情符号"
	L["Auto-align the text depending on the chat window's position."] = "依聊天窗口窗位置自动对齐文字"
	L["Auto-align the main chat window to the bottom left panel/corner."] = "自动将主要窗口对齐左下方面版"
	L["Auto-size the main chat window to match the bottom left panel size."] = "自动缩放主要窗口大小符合左下方面版大小"

	L["Timestamps"] = "时间标记"
	L["Show timestamps."] = "显示时间标记"
	L["Timestamp color:"] = "时间标记颜色："
	L["Timestamp format:"] = "时间标记格式"

	L["Chat Bubbles"] = "对话泡泡"
	L["Collapse chat bubbles"] = "关闭对话泡泡"
	L["Collapses the chat bubbles to preserve space, and expands them on mouseover."] = "收起对话泡泡以节省空间，将游标移至上方则展开。"
	L["Display emoticons in the chat bubbles"] = "在对话泡泡中显示表情符号"

	L["Loot Window"] = "战利品窗口"
	L["Create 'Loot' Window"] = "建立战利品窗口"
	L["Enable the use of the special 'Loot' window."] = "启用战利品窗口"
	L["Maintain the channels and groups of the 'Loot' window."] = "维持战利品窗口的频道和群组"
	L["Auto-align the 'Loot' chat window to the bottom right panel/corner."] = "自动将战利品窗口对齐右下方面版"
	L["Auto-size the 'Loot' chat window to match the bottom right panel size."] = "自动缩放战利品窗口大小符合右下方面版大小"
end

-- Chat: Install
do
	L["Public Chat Window"] = "公共频道窗口"
	L["Public chat like Trade, General and LocalDefense can be displayed in a separate tab in the main chat window. This will keep your main chat window free from intrusive spam, while still having all the relevant public chat available. Do you wish to do so now?"] = "公共频道窗就如同交易、一般及本地防务频道一样可以个别显示在聊天窗口的页签中。可避免垃圾讯息占据你主要的聊天窗口，同时仍可以使用所有相关频道。你想要这样吗?"

	L["Loot Window"] = "战利品窗口"
	L["Information like received loot, crafted items, experience, reputation and honor gains as well as all currencies and similar received items can be displayed in a separate chat window. Do you wish to do so now?"] = "就像获得战利品、制作的物品、经验、声望及荣誉值以及所有货币和收到类似物品可以显示在单一窗口，你希望要这样做吗?"
	
	L["Initial Window Size & Position"] = "重置窗口大小及位置"
	L["Your chat windows can be configured to match the unitframes and the bottom UI panels in size and position. Do you wish to do so now?"] = "聊天窗口可以设置成对齐单位框架和符合下面UI面版的大小及位置，你希望这样做吗?"
	L["This will also dock any additional chat windows."] = "这会锁定其他聊天窗口"	
	
	L["Window Auto-Positioning"] = "自动调整窗口位置"
	L["Your chat windows will slightly change position when you change UI scale, game window size or screen resolution. The UI can maintain the position of the '%s' and '%s' chat windows whenever you log in, reload the UI or in any way change the size or scale of the visible area. Do you wish to activate this feature?"] = "当你改变UI的缩放比例、游戏窗口大小或是屏幕分辨率，聊天窗口会稍微改变位置，每当你登入、重载介面或是以任何方式改变可视区域的大小或缩放比例时时，UI可以维持 %s 和 %s 窗口的位置。你希望启用这项功能吗?"
	
	L["Window Auto-Sizing"] = "自动缩放窗口"
	L["Would you like the UI to maintain the default size of the chat frames, aligning them in size to visually fit the unitframes and bottom UI panels?"] = "你希望UI维持聊天窗口的默认大小，调整它们的大小并对齐单位框架和下面的UI面版?"
	
	L["Channel & Window Colors"] = "频道及窗口颜色"
	L["Would you like to change chatframe colors to what %s recommends?"] = "你希望将聊天窗口的颜色设定成 %s 建议值吗?"
end

-- Combat
do
	L["dps"] = true -- Damage Per Second
	L["hps"] = true -- Healing Per Second
	L["tps"] = true -- Threat Per Second
	L["Last fight lasted %s"] = "上次战斗持续 %s"
	L["You did an average of %s%s"] = "平均 %s%s"
	L["You are overnuking!"] = "火力过大!"
	L["You have aggro, stop attacking!"] = "仇恨值过高，停止攻击!"
	L["You are tanking!"] = "坦怪中"
	L["You are losing threat!"] = "丧失怪物仇恨中!"
	L["You've lost the threat!"] = "已无仇恨值!"
end

-- Combat: menu
do
	L["Simple DPS/HPS Meter"] = "简易 DPS/HPS 计量器"
	L["Enable simple DPS/HPS meter"] = "启用简易 DPS/HPS 计量器"
	L["Show DPS/HPS when you are solo"] = "单人时显示 DPS/HPS"
	L["Show DPS/HPS when you are in a PvP instance"] = "PvP时显示 DPS/HPS"
	L["Display a simple verbose report at the end of combat"] = "战斗结束时显示简易报告"
	L["Minimum DPS to display: "] = "显示 DPS 最少："
	L["Minimum combat duration to display: "] = "显示战斗时间最少："
	L["Simple Threat Meter"] = "简易威胁计量器"
	L["Enable simple Threat meter"] = "启用简易威胁计量器"
	L["Use the Focus target when it exists"] = "计算专注目标"
	L["Enable threat warnings"] = "启用威胁警示"
	L["Show threat when you are solo"] = "单人时显示威胁"
	L["Show threat when you are in a PvP instance"] = "PvP时显示威胁"
	L["Show threat when you are a healer"] = "当你是补职时显示威胁"
	L["Enable simple scrolling combat text"] = "启用简易卷动式战斗文字"
end

-- Combatlog
do
	L["GUIS"] = true -- the visible name of our custom combat log filter, used to identify it
	L["Show simplified messages of actions done by you and done to you."] = "显示你所做过及别人对你做过的简易讯息" -- the description of this filter
end

-- Combatlog: menu
do
	L["Maintain the settings of the GUIS filter so that they're always the same"] = "保留 GUIS 过滤器的设定"
	L["Keep only the GUIS and '%s' quickbuttons visible, with GUIS at the start"] = "GUIS 启动时显示 GUIS 及 %s 快速键"
	L["Autmatically switch to the GUIS filter when you log in or reload the UI"] = "当你登入或是重新载入介面时，自动切换至 GUIS 过滤器。"
	L["Autmatically switch to the GUIS filter whenever you see a loading screen"] = "每当进入载入画面时，自动切换至 GUIS 过滤器。"
	L["Automatically switch to the GUIS filter when entering combat"] = "每当进入战斗时，自动切换至 GUIS 过滤器。"
end

-- Loot
do
	L["BoE"] = "装绑" -- Bind on Equip
	L["BoP"] = "拾绑" -- Bind on Pickup
end

-- Merchant
do
	L["Selling Poor Quality items:"] = "贩售粗糙等级物品"
	L["-%s|cFF00DDDDx%d|r %s"] = true -- nothing to localize in this one, unless you wish to change the formatting
	L["Earned %s"] = "获得：%s"
	L["You repaired your items for %s"] = "修理装备：%s"
	L["You repaired your items for %s using Guild Bank funds"] = "使用公会银行修理装备：%s"
	L["You haven't got enough available funds to repair!"] = "你没有足够金币修理装备!"
	L["Your profit is %s"] = "净赚：%s"
	L["Your expenses are %s"] = "费用：%s"
	L["Poor Quality items will now be automatically sold when visiting a vendor"] = "开启自动贩售粗糙等级物品"
	L["Poor Quality items will no longer be automatically sold"] = "关闭自动贩售粗糙等级物品"
	L["Your items will now be automatically repaired when visiting a vendor with repair capabilities"] = "开启自动修理装备"
	L["Your items will no longer be automatically repaired"] = "关闭自动修理装备"
	L["Your items will now be repaired using the Guild Bank if the options and the funds are available"] = "开启自动使用公会银行修理装备"
	L["Your items will now be repaired using your own funds"] = "使用自己金币修理装备"
	L["Detailed reports for autoselling of Poor Quality items turned on"] = "启用自动贩售粗糙等级物品详细报告"
	L["Detailed reports for autoselling of Poor Quality items turned off, only summary will be shown"] = "关闭自动贩售粗糙物品报告，只显示总额。"
	L["Toggle autosell of Poor Quality items"] = "启用自动贩售粗糙物品"
	L["Toggle display of detailed sales reports"] = "启用贩售详细报告"
	L["Toggle autorepair of your armor"] = "启用自动修理装备"
	L["Toggle Guild Bank repairs"] = "启用公会银行修理装备"
	L["<Alt-Click to buy the maximum amount>"] = "<Alt 点击以购买最大数量>"
end

-- Merchant: Menu
do
	L["Here you can configure the options for automatic actions upon visiting a merchant, like selling junk and repairing your armor."] = "这里你可以设定开启商店时自动操作的选项，如贩卖粗糙等级物品和修理你的装备。"
	L["Automatically repair your armor and weapons"] = "自动修理装备和武器"
	L["Enabling this option will show a detailed report of the automatically sold items in the default chat frame. Disabling it will restrict the report to gold earned, and the cost of repairs."] = "开启此选项将在默认的聊天窗口中显示自动贩售的详细报告，关闭它则不显示获得的金钱及修理装备的花费。"
	L["Automatically sell poor quality items"] = "自动贩卖粗糙等级物品"
	L["Enabling this option will automatically sell poor quality items in your bags whenever you visit a merchant."] = "开启此选项会在你开启商店时自动贩售你背包中粗糙等级物品。"
	L["Show detailed sales reports"] = "显示贩售详细报告"
	L["Enabling this option will automatically repair your items whenever you visit a merchant with repair capability, as long as you have sufficient funds to pay for the repairs."] = "当你有足够的金钱时，启用此选项会在你开启商店时自动修理装备。"
	L["Use your available Guild Bank funds to when available"] = "如果可以，使用公会银行的资金。"
	L["Enabling this option will cause the automatic repair to be done using Guild funds if available."] = "启用此选项将会使用公会银行修理装备。"
end

-- Minimap
do
	L["Calendar"] = "行事历"
	L["New Event!"] = "新事件"
	L["New Mail!"] = "新邮件"
	
	L["Raid Finder"] = "团队搜寻器"
	
	L["(Sanctuary)"] = "(避难所)"
	L["(PvP Area)"] = "(PVP区域)"
	L["(%s Territory)"] = "(%s 领地)"
	L["(Contested Territory)"] = "(争夺中的领地)"
	L["(Combat Zone)"] = "(战斗区域)"
	L["Social"] = "好友名单"
	
	L["<Left-Click to toggle the Calendar>"] = "<左键点击开启行事历>" -- *v3
end

-- Minimap: menu
do
	L["The Minimap is a miniature map of your closest surrounding areas, allowing you to easily navigate as well as quickly locate elements such as specific vendors, or a herb or ore you are tracking. If you wish to change the position of the Minimap, you can unlock it for movement with |cFF4488FF/glock|r."] = "小地图是显示你周边地区的小型地图，让您轻松导航以及快速定位如商人，或你正追踪的药草或矿石。如果你想改变当前小地图的位置，你可以使用 |cFF4488FF/glock|r 指令解除锁定。"
	L["Display the clock"] = "显示时钟"
	L["Display the current player coordinates on the Minimap when available"] = "在小地图上显示当前所在座标"
	L["Show seconds"] = "显示秒"
	L["Use 24 hour time"] = "24小时制"
	L["Display the server time instead of the local time"] = "显示服务器时间而非本地时间" -- *v3
	L["Use the Mouse Wheel to zoom in and out"] = "使用鼠标滚轮缩放"
	L["Display the difficulty of the current instance when hovering over the Minimap"] = "当鼠标游标移至小地图上方，显示当前副本困难度。"
	L["Display the shortcut menu when clicking the middle mouse button on the Minimap"] = "在小地图上按鼠标中键显示快速选单"
	L["Rotate Minimap"] = "旋转小地图"
	L["Check this to rotate the entire minimap instead of the player arrow."] = "勾选此选项来旋转整个小地图而不是玩家箭头"
	L["Only show the clock when hovering over the Minimap"] = "只有在鼠标旋停小地图上才显示时钟" -- *v3
	L["Display the current location"] = "显示当前地区" -- *v3
	L["Only show the current location when hovering over the Minimap"] = "只有在鼠标旋停小地图上才显示当前地区" -- *v3
	L["Display the calendar button"] = "显示行事历按钮" -- *v3
	L["Only show the calendar button when hovering over the Minimap"] = "只有在鼠标旋停小地图上才显示行事历按钮" -- *v3
end

-- Nameplates: menu
do
	L["Nameplates are small health- and castbars visible over a character or NPC's head. These options allow you to control which Nameplates are visible within the game field while you play."] = "单位名条在人物或NPC头上显示血量及施法条，这些选项可控制你想在游戏主画面中显示的名称。"
	L["Automatically enable nameplates based on your current specialization"] = "根据你的天赋自动显示NPC"
	L["Automatically enable friendly nameplates for repeatable quests that require them"] = "自动显示任务NPC"
	L["Only show friendly nameplates when engaged in combat"] = "战斗中只显示友方单位"
	L["Only show enemy nameplates when engaged in combat"] = "战斗中只显示敌方单位"
	L["Use a blacklist to filter out certain nameplates"] = "使用黑名单过滤单位名条"
	L["Display character level"] = "显示人物等级"
	L["Hide for max level characters when you too are max level"] = "当你满级时隐藏人物最高等级"
	L["Display character names"] = "显示人物名称"
	L["Display combo points on your target"] = "显示你目标的连击点数"
	L["Show Class Colors in Unit Nameplates for enemies"] = "在敌方的名条上显示职业颜色" -- *v3	
	L["Nameplate Motion Type"] = "名条排列类型"
	L["Overlapping Nameplates"] = "重叠名条"
	L["Stacking Nameplates"] = "堆叠名条"
	L["Spreading Nameplates"] = "分散名条"
	L["This method will allow nameplates to overlap."] = "这种方式会让名条重叠"
	L["This method avoids overlapping nameplates by stacking them vertically."] = "这种方式会让名条呈垂直堆叠以避免重叠"
	L["This method avoids overlapping nameplates by spreading them out horizontally and vertically."] = "这种方式会让名条呈水平和垂直分散以避免重叠"
	
	L["Friendly Units"] = "友方单位"
	L["Friendly Players"] = "友方玩家"
	L["Turn this on to display Unit Nameplates for friendly units."] = "开启此选项可显示友方单位的名条"
	L["Enemy Units"] = "敌方单位"
	L["Enemy Players"] = "敌方玩家"
	L["Turn this on to display Unit Nameplates for enemies."] = "开启此选项可显示敌方单位的名条"
	L["Pets"] = "宠物"
	L["Turn this on to display Unit Nameplates for friendly pets."] = "开启此选项可显示友方宠物的名条"
	L["Turn this on to display Unit Nameplates for enemy pets."] = "开启此选项可显示敌方宠物的名条"
	L["Totems"] = "图腾"
	L["Turn this on to display Unit Nameplates for friendly totems."] = "开启此选项可显示友方图腾的名条"
	L["Turn this on to display Unit Nameplates for enemy totems."] = "开启此选项可显示敌方图腾的名条"
	L["Guardians"] = "守护者"
	L["Turn this on to display Unit Nameplates for friendly guardians."] = "开启此选项可显示友方守护者的名条"
	L["Turn this on to display Unit Nameplates for enemy guardians."] = "开启此选项可显示敌方守护者的名条"
end

-- Panels & Backdrops
do
	L["Here you can set the visibility and behaviour of various objects like the XP and Reputation Bars, the Battleground Capture Bars and more. If you wish to change their position, you can unlock them for movement with |cFF4488FF/glock|r."] = "这个选项可以设定显示经验条、声望条、战场等物件，如果你想改变它的位置，你可以使用 |cFF4488FF/glock|r 指令解除锁定。"
	L["Panel Styles"] = "面板样式" -- *v3
	L["Color borders in the color of your class"] = "边框颜色依照你的职业类型显示" -- *v3

	L["StatusBars"] = "状态列"
	L["Show the player experience bar."] = "显示玩家经验条"
	L["Show when you are at your maximum level or have turned off experience gains."] = "当你满级或是不再获得经验值时显示"
	L["Show the currently tracked reputation."] = "显示当前追踪的声望"
	L["Show the capturebar for PvP objectives."] = "显示 PVP 物品的占领状态列"
	L["XP-, Rep- & Capture Bars"] = "经验、声望、占领条" -- *v3
	
	L["Panels & Backdrops"] = "面板及动作条边框" -- *v3
	L["Left Infopanel"] = "左侧信息面板" -- *v3
	L["Right Infopanel"] = "右侧信息面板" -- *v3
	L["Bottom Backdrop"] = "底部动作条边框" -- *v3
	L["Bottom Left Backdrop"] = "底部左侧动作条边框" -- *v3
	L["Bottom Right Backdrop"] = "底部右侧动作条边框" -- *v3
	L["Side Backdrop"] = "右侧动作条边框" -- *v3

	L["<Left-Click to open all bags>"] = "<左键点击开启所有背包>"
	L["<Left-Click to toggle backpack>"] = "<左键点击开启背包>"
	L["<Right-Click for options>"] = "<右键开启选项>"
	L["Guild: %s"] = "公会：%s"
	L["No Guild"] = "无公会"
	L["New Mail!"] = "有新邮件"
	L["No Mail"] = "无新邮件"
	L["Total Usage"] = "插件内存："
	L["Tracked Currencies"] = "追踪的货币"
	L["Additional AddOns"] = "额外的插件"
	L["Network Stats"] = "网路"
	L["World latency:"] = "世界延迟："
	L["World latency %s:"] = "世界延迟 %s："
	L["(Combat, Casting, Professions, NPCs, etc)"] = "(战斗、施法、专业、NPC等)"
	L["Home latency:"] = "本地延迟："
	L["Home latency %s:"] = "本地延迟 %s："
	L["Realm latency:"] = "本地延迟："
	L["Realm latency %s:"] = "本地延迟 %s："
	L["(Chat, Auction House, etc)"] = "(聊天、拍卖场等)"
	L["Display World Latency %s"] = "显示世界延迟 %s"
	L["Display Home Latency %s"] = "显示本地延迟 %s"
	L["Display Framerate"] = "显示帧数"

	L["Incoming bandwidth:"] = "下载带宽"
	L["Outgoing bandwidth:"] = "上传带宽"
	L["KB/s"] = true
	L["<Left-Click for more>"] = "<左键点击显示更多信息>"
	L["<Left-Click to toggle Friends pane>"] = "<左键显示好友名单>"
	L["<Left-Click to toggle Guild pane>"] = "<左键点及开启公会面版>"
	L["<Left-Click to toggle Reputation pane>"] = "<左键点及开启声望面版>"
	L["<Left-Click to toggle Currency frame>"] = "<左键点及开启货币面版>"
	L["%d%% of normal experience gained from monsters."] = "从怪物身上获得平时 %d%% 的经验值 "
	L["You should rest at an Inn."] = "你必须在旅店休息"
	L["Hide copper when you have at least %s"] = "隐藏铜币显示当超过 %s"
	L["Hide silver and copper when you have at least %s"] = "隐藏铜币及银币当超过 %s"
	L["Invite a member to the Guild"] = "邀请加入公会"
	L["Change the Guild Message Of The Day"] = "修改公会今日讯息"
	L["Select currencies to always watch:"] = "选择要显示的货币"
	L["Select how your gold is displayed:"] = "选择如何显示你的金币："
	
	L["No container equipped in slot %d"] = "插槽 %d 无装备任何背包"
end

-- Panels: menu
do
	L["Here you can change the settings and visibility of the various info panels and backdrops in the UI."] = "这里你可以设定及显示UI各种信息面板及背景。" -- *v3
	L["UI Panels are special frames providing information about the game as well allowing you to easily change settings. Here you can configure the visibility and behavior of these panels. If you wish to change their position, you can unlock them for movement with |cFF4488FF/glock|r."] = "UI面版是提供游戏信息的特殊框架，以及让你容易地改变设定。这个选项可以让你设定这些面版的外观和行为，如果你想改变它的位置，你可以使用 |cFF4488FF/glock|r 指令解除锁定。"
	L["Visible Panels"] = "显示面板"
	L["Here you can decide which of the UI panels should be visible. They can still be moved with |cFF4488FF/glock|r when hidden."] = "这里你可以设定是否显示 UI 面板，它们仍然可以在隐藏状态下透过 |cFF4488FF/glock|r 指令移动。"
	L["Show the bottom right UI panel"] = "显示右下角面板"
	L["Show the bottom left UI panel"] = "显示左下角面板"
	L["Bottom Right Panel"] = "右下角面板"
	L["Bottom Left Panel"] = "左下角面板"
	L["Visible Backdrops"] = "显示动作条边框" -- *v3
	L["Here you can decide which of the backdrops should be visible."] = "这里你可以设定要显示哪个动作条的边框。" -- *v3
	L["Bottom Backdrop"] = "底部动作条边框" -- *v3
	L["Bottom Left Backdrop"] = "底部左侧动作条边框" -- *v3
	L["Bottom Right Backdrop"] = "底部右侧动作条边框" -- *v3
	L["Side Backdrop"] = "侧边动作条边框" -- *v3
end

-- Quest: menu
do
	L["QuestLog"] = "任务纪录"
	L["These options allow you to customize how game objectives like Quests and Achievements are displayed in the user interface. If you wish to change the position of the ObjectivesTracker, you can unlock it for movement with |cFF4488FF/glock|r."] = "这些选项让你可以自行设定如任务或成就等游戏目标在用户端介面中显示的方式，如果你想要改变任务追踪的位置，你可以使用 |cFF4488FF/glock|r 指令解除锁定。"
	L["Display quest level in the QuestLog"] = "显示任务等级"
	L["Objectives Tracker"] = "任务追踪"
	L["Autocollapse the WatchFrame"] = "自动隐藏任务追踪窗口"
	L["Autocollapse the WatchFrame when a boss unitframe is visible"] = "出现首领框架时自动隐藏任务追踪窗口"
	L["Automatically align the WatchFrame based on its current position"] = "依任务追踪窗口当前位置自动对齐"
	L["Align the WatchFrame to the right"] = "任务追踪窗口靠右对齐"
end

-- Tooltips
do
	L["Tooltip"] = "提示讯息" -- *v3
	L["Here you can change the settings for the game tooltips"] = "你可以改变游戏提示设定"
	L["Hide while engaged in combat"] = "战斗中隐藏"
	L["Color unit tooltips borders and healthbars according to player class or NPC reaction"] = "根据玩家职业或NPC状态用颜色显示在提示边框及单位血条。" -- *v3
	L["Show values on the tooltip healthbar"] = "显示血量数值"
	L["Show player titles in the tooltip"] = "显示玩家头衔"
	L["Show player realms in the tooltip"] = "显示玩家服务器类型"
	L["Positioning"] = "定位"
	L["Choose what tooltips to anchor to the mouse cursor, instead of displaying in their default positions:"] = "选择哪些提示要启用鼠标游标跟随，而非显示在默认的位置："
	L["All tooltips will be displayed in their default positions."] = "在默认的位置显示所有提示"
	L["All tooltips will be anchored to the mouse cursor."] = "所有提示启用鼠标游标跟随"
	L["Only Units"] = "只有单位框架"
	L["Only unit tooltips will be anchored to the mouse cursor, while other tooltips will be displayed in their default positions."] = "只有单位框架启用鼠标游标跟随，其他则显示在默认的位置"
end

-- worldmap and zonemap
do
	L["ZoneMap"] = "区域地图" -- *v3
end

-- UnitFrames
do
	L["Due to entering combat at the worst possible time the UnitFrames were unable to complete the layout change.|nPlease reload the user interface with |cFF4488FF/rl|r to complete the operation!"] = "因进入战斗导致无法完成单位框架设定 |n请使用 |cFF4488FF/rl|r 重新载入用户端介面。"
	L["Can't change the Set Focus key while engaged in combat!"] = "战斗中无法更改专注目标快速键设定"
end

-- UnitFrames: oUF_Trinkets
do
	L["Trinket ready: "] = "饰品就绪："
	L["Trinket used: "] = "饰品已使用："
	L["WotF used: "] = "亡灵意志已使用："
end

-- UnitFrames: menu
do
	L["These options can be used to change the display and behavior of unit frames within the UI. If you wish to change their position, you can unlock them for movement with |cFF4488FF/glock|r."] = "这些选项可以用来设定单位框架的显示方式，如果你想要改变单位框架的位置，你可以使用 |cFF4488FF/glock|r 指令解除锁定。"

	L["Choose what unit frames to load"] = "选择载入哪种单位框架"
	L["Enable Party Frames"] = "启用队伍框架"
	L["Enable Arena Frames"] = "启用竞技场框架"
	L["Enable Boss Frames"] = "启用首领框架"
	L["Enable Raid Frames"] = "启用团队框架"
	L["Enable MainTank Frames"] = "启用主坦框架"
	L["Enable ClassBar"] = "启用职业专属动作条"
	
	L["Set Focus"] = "专注设定"
	L["Here you can enable and define a mousebutton and optional modifier key to directly set a focus target from clicking on a frame."] = "此处你可以启用并指定一组鼠标按键及额外的辅助键，透过鼠标点击设定专注目标。"
	L["Enable Set Focus"] = "启用专注目标设定"
	L["Enabling this will allow you to quickly set your focus target by clicking the key combination below while holding the mouse pointer over the selected frame."] = "启用此功能可以让你使用下列辅助键快速地将鼠标箭头悬停的目标设定为专注目标"
	L["Modifier Key"] = "辅助键"

	L["Enable indicators for HoTs, DoTs and missing buffs."] = "启用HoTs、DoTs及增益监视器"
	L["This will display small squares on the party- and raidframes to indicate your active HoTs and missing buffs."] = "这会在队伍及团队框架上显示你身上的HoTs、DoTs及增益。"

	--L["Auras"] = "光环"
	L["Here you can change the settings for the auras displayed on the player- and target frames."] = "你可以设定如何显示玩家及目标身上增益减益效果。"
	L["Filter the target auras in combat"] = "战斗中过滤增益减益效果"
	L["This will filter out auras not relevant to your role from the target frame while engaged in combat, to make it easier to track your own debuffs."] = "战斗中过滤与你角色和目标无关的增益减益效果，让你更容易监视你所施放的法术。"
	L["Desature target auras not cast by the player"] = "将目标身上不是玩家施放的增益减益效果法术去色"
	L["This will desaturate auras on the target frame not cast by you, to make it easier to track your own debuffs."] = "这会将目标身上不是玩家所施放的增益减益效果法术去色，让你更容易地监视你所施放的法术。"
	L["Texts"] = "文字"
	L["Show values on the health bars"] = "在血量条上显示数值"
	L["Show values on the power bars"] = "在能量条上显示数值"
	L["Show values on the Feral Druid mana bar (when below 100%)"] = "当野性德鲁伊法力条小於100%，在上面显示数值。"
	
	L["Groups"] = "群组"
	L["Here you can change what kind of group frames are used for groups of different sizes."] = "你可以设定不同群组大小要使用何种群组框架"

	L["5 Player Party"] = "5人队伍"
	L["Use the same frames for parties as for raid groups."] = "将此框架当作是团队框架"
	L["Enabling this will show the same types of unitframes for 5 player parties as you currently have chosen for 10 player raids."] = "启用此选项会将你当前选的10人团队框架显示成5人的队伍框架"
	
	L["10 Player Raid"] = "10人团队"
	L["Use same raid frames as for 25 player raids."] = "将此框架当作是25人团队框架"
	L["Enabling this will show the same types of unitframes for 10 player raids as you currently have chosen for 25 player raids."] = "启用此选项会将你当前选的25人团队框架显示成10人的团队框架"

	L["25 Player Raid"] = "25人团队"
	L["Automatically decide what frames to show based on your current specialization."] = "自动根据你的天赋决定显示何种框架"
	L["Enabling this will display the Grid layout when you are a Healer, and the smaller DPS layout when you are a Tank or DPSer."] = "启用此选项将会自动切换成治疗者的Grid版面，或是伤害输出及坦克的DPS版面"
	L["Use Healer/Grid layout."] = "使用治疗者Grid版面"
	L["Enabling this will use the Grid layout instead of the smaller DPS layout for raid groups."] = "启用此选项将在团队中使用Grid版面而非DPS版面"
	
	L["Player"] = "玩家"
	L["ClassBar"] = "职业专属资源列"
	L["The ClassBar is a larger display of class related information like Holy Power, Runes, Eclipse and Combo Points. It is displayed close to the on-screen CastBar and is designed to more easily track your most important resources."] = "职业专属资源列显示职业相关如圣能、符文，蚀星蔽月及连击点数。它显示在施法条附近用来更轻松地监视你重要的资源。"
	L["Enable large movable classbar"] = "使用大型可移动的职业专属资源列"
	L["This will enable the large on-screen classbar"] = "这会启用大型职业专属资源列"
	L["Only in Combat"] = "只在战斗中显示"
	L["Disable integrated classbar"] = "关闭整合式资源列"
	L["This will disable the integrated classbar in the player unitframe"] = "这会在玩家头像UI中关闭整合式资源列。"
	L["Show player auras"] = "显示玩家光环"
	L["This decides whether or not to show the auras next to the player frame"] = "这里设定是否在玩家头像旁显示光环"
	
	L["Target"] = "目标"
	L["Show target auras"] = "显示目标光环"
	L["This decides whether or not to show the auras next to the target frame"] = "这里设定是否在目标头像旁显示光环"
end

-- UnitFrames: Movable Frame Anchors
do
	L["Player"] = "玩家" -- *v3
	L["Target"] = "目标" -- *v3
	L["Pet"] = "宠物" -- *v3
	L["Target of Target"] = "目标的目标" -- *v3
	L["Focus"] = "专注目标" -- *v3
	L["Party"] = "队伍" -- *v3
	L["15 Player Raid"] = "15人团队" -- *v3
	L["40 Player Raid Healer"] = "40人团队 Healer" -- *v3
	L["40 Player Raid DPS"] = "40人团队 DPS" -- *v3
	L["Arena"] = "增减益" -- *v3
	L["Boss"] = true -- *v3
end

-- UnitFrames: GroupPanel
do
	-- party
	L["Show the player along with the Party Frames"] = "在队伍框架中显示玩家"
	L["Use Raid Frames instead of Party Frames"] = "使用团队风格的队伍框架"
	
	-- raid
	L["Use the grid layout for all Raid sizes"] = "所有团队都使用 grid 风格"
	
	L["Group Structure"] = true
	L["Group Roles"] = true
	L["World Markers"] = "世界标记"
	L["Raid Target Icon"] = "团队目标图标"
end


--------------------------------------------------------------------------------------------------
--		FAQ
--------------------------------------------------------------------------------------------------
-- 	Even though most of these strings technically belong to their respective modules,
--	and not the FAQ interface, we still gather them all here for practical reasons.
do
	-- general
	L["FAQ"] = true
	L["Frequently Asked Questions"] = "常见问题"
	L["Clear All Tags"] = "清除所有标签"
	L["Show the current FAQ"] = "显示当前FAQ"
	L["Return to the listing"] = "返回清单"
	L["Go to the options menu"] = "移至选单"
	L["Select categories from the list on the left. |nYou can choose multiple categories at once to narrow down your search.|n|nSelected categories will be displayed on top of the listing, |nand clicking them again will deselect them!"] = "从左侧列表中选择所需的类别。|n您可以一次选择多个类别来缩小您的搜索结果。|n|n已选择的类别会显示在最上层|n再点及一次会取消选取。"
	
	-- core
	L["I wish to move something! How can I change frame positions?"] = "我想移动某些东西，我要如何改变框架的位置?"
	L["A lot of frames can be moved to custom positions. You can unlock them all for movement by typing |cFF4488FF/glock|r followed by the Enter key, and lock them with the same command. There are also multiple options available when right-clicking on the overlay of the movable frame."] = "有很多框架可以移到指定的位置，你可以输入 |cFF4488FF/glock|r 指令并按确认键解除锁定，并使用相同的指令锁定它们。当你右键点击可移动的框架时也有多种选项可使用。"

	-- actionbars
	L["How do I change the currently active Action Page?"] = "如何切换当前的动作条?"
	L["There are no on-screen buttons to do this, so you will have to use keybinds. You can set the relevant keybinds in the Blizzard keybinding interface."] = "画面上没有任何按钮可供切换，你必须使用快速键，你可以在游戏按键设定画面中设定。"
	L["How can I change the visible actionbars?"] = "如何切换显示动作条?"
	L["You can toggle most actionbars by clicking the arrows located close to their corners. These arrows become visible when hovering over them with the mouse if you're not currently engaged in combat. You can also toggle the actionbars from the options menu, or by running the install tutorial by typing |cFF4488FF/install|r followed by the Enter key."] = "如果你不在战斗中，当你将鼠标游标悬停在动作条旁，这些箭头会显示，你可以点击动作条角边的箭头来切换显示动作条。你也可以从选单中或是输入 |cFF4488FF/install|r 指令执行安装教学来切换动作条。"
	L["How do I toggle the MiniMenu?"] = "如何切换微型选单列?"
	L["The MiniMenu can be displayed by typing |cFF4488FF/showmini|r followed by the Enter key, and |cFF4488FF/hidemini|r to hide it. You can also toggle it from the options menu or by running the install tutorial by typing |cFF4488FF/install|r."] = "输入 |cFF4488FF/showmini|r 指令显示微型选单，输入 |cFF4488FF/hidemini|r 指令则隐藏，你也可以从选单中或是输入 |cFF4488FF/install|r 指令执行安装教学来切换微型选单。"
	L["How can I move the actionbars?"] = "如何移动动作条?"
	L["Not all actionbars can be moved, as some are an integrated part of the UI layout. Most of the movable frames in the UI can be unlocked by typing |cFF4488FF/glock|r followed by the Enter key."] = "并非所有的动作条可以被移动，像是一些是UI组成的一部份就不行，UI中大部分可移动的框架可以输入 |cFF4488FF/glock|r 指令锁定。"
	
	-- actionbuttons
	L["How can I toggle keybinds and macro names on the buttons?"] = "如何在按钮上切换显示快速键和巨集名称?"
	L["You can enable keybind display on the actionbuttons by typing |cFF4488FF/showhotkeys|r followed by the Enter key, and disable it with |cFF4488FF/hidehotkeys|r. Macro names can be toggled with the |cFF4488FF/shownames|r and |cFF4488FF/hidenames|r commands. All settings can also be changed in the options menu."] = "你可以输入 |cFF4488FF/showhotkeys|r 指令在动作按钮上显示热键，|cFF4488FF/hidehotkeys|r 则是关闭显示。输入 |cFF4488FF/shownames|r 指令在动作按钮上显示巨集名称，|cFF4488FF/hidenames|r 则是关闭显示。"
	
	-- auras
	L["How can I change how my buffs and debuffs look?"] = "如何改变增益减益的显示方式?"
	L["You can change a lot of settings like the time display and the cooldown spiral in the options menu."] = "你可以在选单上改变很多设定如时间显示以及在图标上显示冷却倒数。"
	L["Sometimes the weapon buffs don't display correctly!"] = "有时候武器效果并未正确显示!"
	L["Correct. Sadly this is a bug in the tools Blizzard has given to us addon developers, and not something that is easily fixed. You'll simply have to live with it for now."] = "没错，可悲的是，这是暴雪提供给我们这些插件开发者的工具的bug，而且不是那麽容易地修正，现在只能这样。"
	
	-- bags
	L["Sometimes when I choose to bypass a category, not all items are moved to the '%s' container, but some appear in others?"] = "有时候当我选择略过某个分类时，不是所有物品都会移到 %s 类别，有些则是移到其他类别?"
	L["Some items are put in the 'wrong' categories by Blizzard. Each category in the bag module has its own internal filter that puts these items in their category of they are deemed to belong there. If you bypass this category, the filter is also bypassed, and the item will show up in whatever category Blizzard originally put it in."] = "有些物品是暴雪搞错分类了，背包模块中每个分类内部都有自己的过滤器，将属於该分类的物品纳入，如果你略过某个分类，也就略过该分类的过滤器，因此该物品会以暴雪原先方式进行分类。"
	L["How can I change what categories and containers I see? I don't like the current layout!"] = "如何改变我所看到的背包及分类的外观? 我不喜欢当前这样!"
	L["Categories can be quickly selected from the quickmenu available by clicking at the arrow next to the '%s' or '%s' containers."] = "可以透过点击 %s 或是 %s 旁边的箭头所出现的快速选单来切换分类的显示方式。"
	L["You can change all the settings in the options menu as well as activate the 'all-in-one' layout easily!"] = "你可以选项设定中改变所有设定，以及启用整合式背包样式。"
	L["How can I disable the bags? I don't like them!"] = "如何禁用背包? 我不喜欢它!"
	L["All the modules can be enabled or disabled from within the options menu. You can locate the options menu from the button on the Game Menu, or by typing |cFF4488FF/gui|r followed by the Enter key."] = "从介面选单中可以启用或是禁用所有模块，你可以在游戏选单或是输入 |cFF4488FF/gui|r 指令找到选项。"
	L["I can't close my bags with the 'B' key!"] = "我按 B 键无法关闭背包!"
	L["This is because you probably have bound the 'B' key to 'Open All Bags', which is a one way function. To have the 'B' key actually toggle the containers, you need to bind it to 'Toggle Backpack'. The UI can reassign the key for you automatically. Would you like to do so now?"] = "这是因为你已绑定 B 键打开所有背包，这是一个单向函数。你需要将 B 键绑定切换背包，才能用它切换开启及关闭。你希望UI自动帮你重新绑定吗?"
	L["Let the 'B' key toggle my bags"] = "使用 B 键开启背包"
	
	-- castbars
	L["Player Castbar"] = "玩家施法条" -- *v3
	L["Target Castbar"] = "目标施法条" -- *v3
	L["Focus Castbar"] = "专注目标施法条" -- *v3
	L["Pet Castbar"] = "宠物施法条" -- *v3
	L["How can I toggle the castbars for myself and my pet?"] = "如何切换显示我和宠物的施法条?"
	L["The UI features movable on-screen castbars for you, your target, your pet, and your focus target. These bars can be positioned manually by typing |cFF4488FF/glock|r followed by the Enter key. |n|nYou can change their settings, size and visibility in the options menu."] = "UI提供你、你的目标、你的宠物、以及你的专注目标可移动的施法条，输入 |cFF4488FF/glock|r 可以手动调整位置。|n|n你可以在介面选单中改变它的大小和外观。"
	
	-- minimap
	L["I can't find the Calendar!"] = "我找不到行事历!"
	L["You can open the calendar by clicking the middle mouse button while hovering over the Minimap, or by assigning a keybind to it in the Blizzard keybinding interface avaiable from the GameMenu. The Calendar keybind is located far down the list, along with the GUIS keyinds."] = "你可以将鼠标停在小地图上，并点击鼠标中键开启行事历，或是在游戏选单中按键设定指定快速键。行事历按键设定位在选单底部的 GUIS 按键绑定。"
	L["Where can I see the current dungeon- or raid difficulty and size when I'm inside an instance?"] = "当我进入副本时，如何看出当前地城难度或是团队人数?"
	L["You can see the maximum size of your current group by hovering the cursor over the Minimap while being inside an instance. If you currently have activated Heroic mode, a skull will be visible next to the size display as well."] = "进入副本后，当鼠标游标停在小地图上时，你可以看到当前团队最大人数。如果是英雄模式，同时会在人数旁边显示一个骷髅头。"
	L["How can I move the Minimap?"] = "如何移动小地图?"
	L["You can manually move the Minimap as well as many other frames by typing |cFF4488FF/glock|r followed by the Enter key."] = "你可以输入 |cFF4488FF/glock|r 指令像移动其他框架一样手动移动小地图。"
	
	-- quests
	L["How can I move the quest tracker?"] = "如何移动任务追踪窗口?"
	L["My actionbars cover the quest tracker!"] = "我的动作条盖到了任务追踪窗口!"
	L["You can manually move the quest tracker as well as many other frames by typing |cFF4488FF/glock|r followed by the Enter key. If you wish the quest tracker to automatically move in relation to your actionbars, then reset its position to the default. |n|nWhen a frame is unlocked with the |cFF4488FF/glock|r command, you can right click on its overlay and select 'Reset' to return it to its default position. For some frames like the quest tracker, this will allow the UI to decide where it should be put."] = "你可以输入 |cFF4488FF/glock|r 指令像移动其他框架一样手动移动任务追踪窗口。如果你希望任务追踪窗口自动紧邻动作条，将它重置成默认值。|n|n当使用 |cFF4488FF/glock|r 指令解除锁定框架时，你可以右键点击并选择重置，回到默认位置。对於某些框架如任务追踪窗口，这个动作会让UI自行决定要放置的位置。"
	
	-- talents
	L["I can't close the Talent Frame when pressing 'N'"] = "我按 N 键无法关闭天赋面版!"
	L["But you can still close it!|n|nYou can close it with the Escacpe key, or the closebutton located in he upper right corner of the Talent Frame.|n|nWhen closing the Talent Frame with the original keybind to toggle it, it becomes 'tainted'. This means that the game considers it to be 'insecure', and you won't be allowed to do actions like for example changing your glyphs. This only happens when closed with the hotkey, not when it's closed by the Escape key or the closebutton.|n|nBy reassigning your Talent Frame keybind to a function that only opens the frame, not toggles it, we have made sure that it gets closed the proper way, and you can continue to change your glyphs as intended."] = "但你仍然可以关掉它!|n|n你可以使用 Esc 键或是右上角关闭按钮关掉它。|n|n当你用原来绑定的按键关闭时，游戏视为是不安全的，而且不允许你执行如改变雕文。这只会发生在使用快速键关闭的时候，而非在使用 Esc 键或是关闭按钮的时候。|n|n当绑定只能开启而非切换天赋面版的按键时，我们保证它可以正确地被关闭，而且你可以继续改变你的雕文。"
	
	-- tooltips
	L["How can I toggle the display of player realms and titles in the tooltips?"] = "如何切换提示中玩家服务器类型及头衔的显示方式?"
	L["You can change most of the tooltip settings from the options menu."] = "你可以在介面选单中改变提示设定"
	
	-- unitframes
	L["My party frames aren't showing!"] = "无法显示我的队伍框架!"
	L["My raid frames aren't showing!"] = "无法显示我的团队框架!"
	L["You can set a lot of options for the party- and raidframes from within the options menu."] = "你可以在介面选单中设定许多有关队伍及团队的设定。"
	
	-- worldmap
	L["Why do the quest icons on the WorldMap disappear sometimes?"] = "为何有时候世界地图上的任务图标消失了?"
	L["Due to some problems with the default game interface, these icons must be hidden while being engaged in combat."] = "由於游戏默认介面的一些问题，这些图标必须在战斗中隐藏。"
end

--------------------------------------------------------------------------------------------------
--		Keybinds Menu (Blizzard)
--------------------------------------------------------------------------------------------------
do
	L["Toggle Calendar"] = "显示行事历"
	L["Whisper focus"] = "密语给专注目标"
	L["Whisper target"] = "密语给目标"
end


--------------------------------------------------------------------------------------------------
--		Error Messages 
--------------------------------------------------------------------------------------------------
do
	L["Can't toggle Action Bars while engaged in combat!"] = "战斗中无法切换动作条"
	L["Can't change Action Bar layout while engaged in combat!"] = "战斗中无法更改动作条样式"
	L["Frames cannot be moved while engaged in combat"] = "战斗中无法移动框架"
	L["Hiding movable frame anchors due to combat"] = "战斗中隐藏可移动式框架"
	L["UnitFrames cannot be configured while engaged in combat"] = "战斗中无法设定单位框架"
	L["Can't initialize bags while engaged in combat."] = "战斗中无法初始化背包"
	L["Please exit combat then re-open the bags!"] = "请离开战斗并重新开启背包"
end


--------------------------------------------------------------------------------------------------
--		Core Messages
--------------------------------------------------------------------------------------------------
do
	L["Copy settings between characters"] = "角色间复制设定" -- *v3
	L["Save"] = "储存" -- *v3
	L["Restore"] = "回复" -- *v3

	L["Goldpaw"] = "|cFFFF7D0AGoldpaw|r" -- my class colored name. no changes needed here.
	L["%s loaded and ready"] = "%s 已载入备妥" -- *v3
	L["|cFF4488FF/glock|r to activate config mode"] = "|cFF4488FF/glock|r 开启设定模式" -- *v3
	L["|cFF4488FF/bind|r to activate binding mode"] = "|cFF4488FF/bind|r 开启按键绑定" -- *v3
	L["|cFF4488FF/gui|r for additional options"] = "|cFF4488FF/gui|r 开启选项" -- *v3

	-- options menu
	L["The user interface needs to be reloaded for the changes to take effect. Do you wish to reload it now?"] = "用户端介面须重新载入让新的设定生效，你要现在重载吗?"
	L["You can reload the user interface at any time with |cFF4488FF/rl|r or |cFF4488FF/reload|r"] = "你可以使用 |cFF4488FF/rl|r 或 |cFF4488FF/reload|r 指令随时重载用户端介面。"
	L["Can not apply default settings while engaged in combat."] = "战斗中无法套用默认值"
	
	-- keybind stuff
	L["Show Talent Pane"] = "显示天赋面版"
	L["Reload the user interface"] = "重新载入用户端介面" -- *v3
	L["Blizzard Customer Support"] = "暴雪客服" -- *v3
	L["Toggle movable frames"] = "开启可移动式框架" -- *v3
	L["Toggle hover keybind mode"] = "启用鼠标悬停绑定快速键模式" -- *v3
	L["Additional Keybinds"] = "额外的快速键绑定" -- *v3
	L["TSM Post/Cancel"] = true -- *v3

	-- chat commands
	L["Activating Primary Specialization"] = "启用主要天赋" -- *v3
	L["Activating Secondary Specialization"] = "启用第二天赋" -- *v3
	L["%s has been temporarily disabled. Type /enablegui to enable it."] = "%s 已被暂时禁用，输入 /enablegui 启用。" -- *v3
	
	-- frame groups (objects movable with /glock)
	L["Unitframes"] = "单位框架" -- *v3
	L["Frames like the player, target, raid, focus, pet etc"] = "如玩家、目标、团队、专注目标、宠物等框架。" -- *v3
	L["Actionbars"] = "动作条" -- *v3
	L["Frames containing shortcut buttons to abilities, macros etc"] = "含有技能、巨集等快速键的框架。" -- *v3
	L["Panels"] = "面板" -- *v3
	L["Various UI panels providing information, |rincluding the minimap and bottom left and right infopanels"] = "各种提供讯息的 UI 面板|r包含小地图和左右两边底部的信息面板。" -- *v3
	L["Floaters"] = "浮动框架" -- *v3
	L["Various uncategorized elements like the objective tracker, |rthe durability frame, the vehicle seat indicator etc"] = "各种未分类的元件如目标追踪器|r装备耐久度、车辆载具座位等。" -- *v3
	L["Auras"] = "光环" -- *v3
	L["Your buffs and debuffs"] = "玩家增益及减益图标" -- *v3
	L["Castbars"] = "施法条" -- *v3
	L["Unit castbars, mirror timers, BG timers, etc"] = "单位施法条、小时钟、战场计时等。" -- *v3
	
	-- floaters (various movable frame names)
	L["Vehicle"] = "载具" -- *v3
	L["Objectives"] = "任务清单" -- *v3
	L["Alternate Power"] = "能量条" -- *v3
	L["Tickets"] = true -- *v3
	L["Durability"] = "耐久度" -- *v3
	L["Ghost"] = "鬼魂" -- *v3
	L["WorldStateScore"] = "战场" -- *v3
	L["ExtraActionButton"] = "额外的动作条" -- *v3
	L["Achievement and Dungeon Alert Frame"] = "成就及副本警示框架" -- *v3
	
	-- auto disable
	L["The '%s' module was disabled due to the addon '%s' being loaded."] = "%s 模块因 %s 插件已载入而关闭" -- *v3
	
	-- skin names and descriptions
	L["Skins"] = "外观" -- *v3
	L["Skins the '%s' addon"] = "改变 %s 插件外观" -- *v3
	L["Here you can decide which elements should be skinned to match the rest of the UI, and which should keep their default appearance."] = "你可以决定要改变哪些元件的外观以搭配其他UI，而哪些则保留其默认的外观。" -- *v3
	L["Debug Tools"] = "除错工具" -- *v3
	L["Debug tools such as the /framestack or /eventtrace frames"] = "如 /framestack 或是 /eventtrace 框架" -- *v3
	L["MovePad"] = true -- *v3
	L["The movepad which allows you to move and jump with your mouse"] = "让你用鼠标控制人物移动和跳跃的插件" -- *v3
	L["Alert Frames"] = "警告框架" -- *v3
	L["General alerts such as new achievements, dungeons completed, etc"] = "一般警示如完成新的成就或副本等等" -- *v3
	L["Color Picker"] = "颜色选择" -- *v3
	L["The color wheel"] = "色盘" -- *v3
	L["GameMenu"] = "游戏选单" -- *v3
	L["The main game menu"] = "主要的游戏选单" -- *v3
	L["Ghost"] = true -- *v3
	L["The button returning you to a graveyard as a ghost"] = "将你的鬼魂传回墓地的按钮" -- *v3
	L["Quest Gossip"] = "任务信息" -- *v3
	L["General gossip when talking to quest givers"] = "与任务NPC交谈时显示的任务信息" -- *v3
	L["Merchant"] = "商店" -- *v3
	L["The buy/sell window when talking to merchants"] = "与商人交谈时显示的买卖窗口" -- *v3
	L["Opacity"] = "透明度" -- *v3
	L["The opacity selector"] = "透明度选择器" -- *v3
	L["Quest Log"] = "任务纪录" -- *v3
	L["Main quest log"] = "主要的任务纪录" -- *v3
	L["Quest Greeting"] = "任务欢迎" -- *v3
	L["The greeting window when talking to quest givers"] = "与任务NPC交谈时显示的任务欢迎窗口" -- *v3
	L["Ready Check"] = "团队确认" -- *v3
	L["The ready check popup when in a group"] = "组队时准备就绪的弹跳窗口" -- *v3
	L["Roll Poll"] = true -- *v3
	L["The roll poll popup when in a group"] = "团队中骰取装备的介面" -- *v3
	L["Stack Split"] = "堆叠分割" -- *v3
	L["The stack split frame when splitting stacks in your bank or bags"] = "银行或背包堆叠框架" -- *v3
	L["Popups"] = "弹跳窗口" -- *v3
	L["The popup windows with yes/no or other queries"] = "显示yes/no或是其他问题的窗口" -- *v3
	L["Taxi"] = "飞行地图" -- *v3
	L["The flight map when talking to flight masters"] = "与飞行管理员交谈时显示的地图" -- *v3
	L["Ticket Status"] = true -- *v3
	L["The ticket status button for active support tickets"] = true -- *v3
	L["Objectives Tracker"] = "任务追踪" -- *v3
	L["The quest- and achievement tracker"] = "任务及成就追踪器" -- *v3
	L["World Score"] = "世界积分" -- *v3
	L["The on-screen score (battlegrounds, dungeon waves, world PvP objectives etc)"] = true -- *v3
	L["Battleground Score"] = "战场比数" -- *v3
	L["The Battleground score frame"] = "战场双方阵营比数" -- *v3
	L["Achievements"] = "成就" -- *v3
	L["The achievement- and statistic frames"] = "成就及统计框架" -- *v3
	L["Archeology"] = "考古" -- *v3
	L["The Archeology UI"] = "考古界面" -- *v3
	L["Auction House"] = "拍卖场" -- *v3
	L["The Auction House Interface"] = "拍卖场介面" -- *v3
	L["Barber Shop"] = "理发店" -- *v3
	L["The Barber Shop Interface, where you change your hair, facial hair and markings."] = "当你改变你的发型、胡须及装扮时显示的介面" -- *v3
	L["Mailbox"] = "信箱" -- *v3
	L["Your Mail Inbox and Send Mail windows."] = "收信与寄信窗口" -- *v3
	L["Character"] = "角色信息" -- *v3
	L["The window where you see your currently equipped gear, set your title and manage your equipment sets."] = "显示你当前装备，设定头衔及套装管理的窗口" -- *v3
	L["Guild Bank"] = "公会银行" -- *v3
	L["The Guild Bank window with your guild's gold and items."] = "公会银行窗口" -- *v3
	L["Calendar"] = "行事历" -- *v3
	L["The in-game calendar"] = "游戏里的行事历" -- *v3
	L["Dressing Room"] = "试衣间" -- *v3
	L["The dressing room where your character can try on other gear and weapons."] = "可以预览装备及武器的试衣间" -- *v3
	L["Autocomplete"] = "自动完成" -- *v3
	L["The autocomplete box that pops up when you send mail, invite people to a group etc."] = "当你寄信或是邀请某人组队时弹出的窗口" -- *v3
	L["TradeSkill"] = "专业技能" -- *v3
	L["The tradeskill windows where you craft items."] = "制作物品窗口" -- *v3
	L["ItemText"] = true -- *v3
	L["The itemtext frame for books, signs, etc."] = true -- *v3
	L["Trade"] = "交易" -- *v3
	L["The trade window when trading with another player."] = "与他人交易时显示的窗口" -- *v3
	L["Void Storage UI"] = "虚空仓库" -- *v3
	L["The Void Storage interface"] = "虚空仓库界面" -- *v3
	L["Tutorials"] = "新手教学" -- *v3
	L["The game tutorials for new players"] = "游戏新手教学界面" -- *v3
	L["Transmogrification UI"] = "塑形" -- *v3
	L["The item transmogrification window where you style your items to look like other items"] = "将你的装备塑造成其他装备外观的窗口" -- *v3
	L["Trainers"] = "训练员" -- *v3
	L["The trainer interface where you learn new skills and abilities from"] = "学习职业技能或专业技能的窗口" -- *v3
	L["Tabard UI"] = "外袍" -- *v3
	L["The tabard designer interface"] = "外袍设计界面" -- *v3
	L["Socketing UI"] = "宝石插槽" -- *v3
	L["The item socketing UI where you add or remove gems from your gear"] = "让你在装备上嵌入或移除宝石的界面" -- *v3
	L["Reforging UI"] = "重铸" -- *v3
	L["The reforging UI where you redistribute secondary stats on your gear"] = "让你的装备重新分配次要属性的界面" -- *v3
	L["PvP"] = true -- *v3
	L["The PvP window where you queue up for Battlegrounds and Arenas, and manage your teams"] = "排队等候战场、竞技场及团队管理" -- *v3
	L["Petitions"] = true -- *v3
	L["Petition request such as Guild- and Arena charters"] = true -- *v3
	L["Macro UI"] = "巨集" -- *v3
	L["The window where you manage your macros"] = "管理你巨集的界面" -- *v3
	L["Dungeon Journal"] = "地城导览手册" -- *v3
	L["Instance descriptions, boss abilities and loot tables"] = "副本说明、王的技能及掉落物品清单" -- *v3
	L["Dungeon Finder"] = "地城搜寻器" -- *v3
	L["Where you browse available dungeons, raids, scenarios and challenges"] = "浏览可用的副本、团队情境及挑战模式。" -- *v3
	L["Friends"] = "好友" -- *v3
	L["The friends frame"] = "好友窗口" -- *v3
	L["Guild UI"] = "公会 UI" -- *v3
	L["The main guild interface"] = "主要的公会界面" -- *v3
	L["Guild Control UI"] = "公会管理 UI" -- *v3
	L["The window where you create, modify and delete the guild ranks and their permissions"] = "创建、修改、删除公会及权限的窗口" -- *v3
	L["Guild Finder UI"] = "搜寻公会 UI" -- *v3
	L["The window where you browser for guilds"] = "让你浏览所有公会的窗口" -- *v3
	L["Guild Registrar"] = "公会登记" -- *v3
	L["The guild registrar interface where you buy petitions and create new guilds"] = true -- *v3
	L["Guild Invite"] = "工会邀请" -- *v3
	L["The guild invite frame where you accept or decline a guild invitation"] = "让你接受或拒绝工会邀请的窗口" -- *v3
	L["Inspect UI"] = "查看人物 UI" -- *v3
	L["The window where you inspect another player's gear, talents and PvP teams"] = "让你查看其他人物的装备、天赋、PVP 团队的窗口" -- *v3
	L["Black Market UI"] = "黑市 UI" -- *v3
	L["The black market interface"] = "黑市界面" -- *v3
	L["Item Upgrade UI"] = "装备升级 UI" -- *v3
	L["The window where you upgrade the item level of your gear"] = "升级装备等级的窗口" -- *v3
end

-- menu
do
	L["Copy settings from another character"] = "从其他角色复制设定"
	L["This will copy all settings for the addon and all its sub-modules from the selected character to your currently active character"] = "这将从选定的角色复制所有包含子模块的设定到当前角色"
	L["This will only copy the settings for this specific sub-module from the selected character to your currently active character"] = "这只会从选定的角色复制该子模块的设定到当前角色"
	L["UI Scale"] = "介面缩放比例"
	L["Use UI Scale"] = "使用介面缩放比例"
	L["Check to use the UI Scale Slider, uncheck to use the system default scale."] = "勾选使用介面缩放，取消勾选则使用系统大小。"
	L["Changes the size of the game’s user interface."] = "改变游戏用户端介面大小"
	L["Using custom UI scaling is not recommended. It will produce fuzzy borders and incorrectly sized objects."] = "不建议使用自定介面大小，这会造成边框碎裂及物件大小错误。"
	L["Apply the new UI scale."] = "套用新的介面比例"
	L["Global Styles"] = "全局样式" -- *v3
	L["Backdrop Opacity"] = "背景透明度" -- *v3
	L["Set the level of transparency for all backdrops"] = "设定背景透明度" -- *v3
	L["Load Module"] = "载入模块"
	L["Module Selection"] = "模块选择"
	L["Choose which modules that should be loaded"] = "选择要载入的模块"
	L["Never load this module"] = "从不载入此模块"
	L["Load this module unless an addon with similar functionality is detected"] = "除非侦测到类似功能的插件，否则载入此模块。"
	L["Settings"] = "设定" -- *v3
	L["Adjust the settings for this module"] = "调整模块设定" -- *v3
	L["(In Development)"] = "(开发中)"
end

-- install tutorial
do
	-- general install tutorial messages
	L["Skip forward to the next step in the tutorial."] = "在教学中向前转跳到下一步骤"
	L["Previous"] = "前一步"
	L["Go backwards to the previous step in the tutorial."] = "在教学中倒退回到上一步骤"
	L["Skip this step"] = "跳过这一步骤"
	L["Apply the currently selected settings"] = "套用所选择的设定"
	L["Procede with this step of the install tutorial."] = "在教学中执行此步骤"
	L["Cancel the install tutorial."] = "取消安装教学"
	L["Setup aborted. Type |cFF4488FF/install|r to restart the tutorial."] = "安装终止，输入 |cFF4488FF/install|r 重新进入安装教学"
	L["Setup aborted because of combat. Type |cFF4488FF/install|r to restart the tutorial."] = "因战斗导致安装终止，输入 |cFF4488FF/install|r 重新进入安装教学。"
	L["This is recommended!"] = "推荐!"

	-- core module's install tutorial
	L["This is the first time you're running %s on this character. Would you like to run the install tutorial now?"] = "这是你这个角色首次执行 %s，你想要进行安装教学吗?"
	L["Using custom UI scaling will distort graphics, create fuzzy borders, and otherwise ruin frame proportions and positions. It is adviced to always leave this off, as it will seriously affect the entire layout of the UI in unpredictable ways."] = "使用自订UI缩放，将会扭曲图形，产生边框碎裂，并且破坏框架的比例和位置。建议不要使用UI缩放，因为这将严重影响整个UI产生无法预期的错误。"
	L["UI scaling is currently activated. Do you wish to disable this?"] = "UI缩放已启用，你想要关闭它吗?"
	L["|cFFFF0000UI scaling is currently deactivated, which is the recommended setting, so we are skipping this step.|r"] = "|cFFFF0000UI缩放已关闭，这是建议的设定，跳过这一步骤|r"
end

-- general 
-- basically a bunch of very common words, phrases and abbreviations
-- that several modules might have need for
do
	L["R"] = true -- R as in Red
	L["G"] = true -- G as in Green
	L["B"] = true -- B as in Blue
	L["A"] = true -- A as in Alpha (for opacity/transparency)

	L["m"] = true -- minute
	L["s"] = true -- second
	L["h"] = true -- hour
	L["d"] = true -- day

	L["Alt"] = true -- the ALT key
	L["Ctrl"] = true -- the CTRL key
	L["Shift"] = true -- the SHIFT key
	L["Mouse Button"] = "鼠标按键"

	L["Always"] = "总是"
	L["Apply"] = "套用"
	L["Bags"] = "背包"
	L["Bank"] = "银行" 
	L["Bottom"] = "下"
	L["Cancel"] = "取消"
	L["Categories"] = "分类"
	L["Close"] = "关闭"
	L["Continue"] = "继续"
	L["Copy"] = "复制" -- to copy. the verb.
	L["Default"] = "默认"
	L["Elements"] = "元件" -- like elements in a frame, not as in fire, ice etc
	L["Free"] = "空间" -- free space in bags and bank
	L["General"] = "一般" -- general as in general info
	L["Ghost"] = "鬼魂" -- when you are dead and have released your spirit
	L["Hide"] = "隐藏" -- to hide something. not hide as in "thick hide".
	L["Lock"] = "锁定" -- to lock something, like a frame. the verb.
	L["Main"] = true -- used for Main chat frame, Main bag, etc
	L["Next"] = "下一个"
	L["Never"] = "从不"
	L["No"] = "否"
	L["Okay"] = "确定"
	L["Open"] = "开启"
	L["Paste"] = "贴上" -- as in copy & paste. the verb.
	L["Reset"] = "重置"
	L["Rested"] = "充分休息" -- when you are rested, and will recieve 200% xp from kills
	L["Scroll"] = "附魔" -- "Scroll" as in "Scroll of Enchant". The noun, not the verb.
	L["Show"] = "显示"
	L["Skip"] = "跳过"
	L["Top"] = "上"
	L["Total"] = "总共"
	L["Visibility"] = "透明度"
	L["Yes"] = "是"

	L["Requires the UI to be reloaded!"] = "需要重新载入UI"
	L["Changing this setting requires the UI to be reloaded in order to complete."] = "更改此设定需要重新载入UI以完成设定"
	L["Changing these settings requires the UI to be reloaded in order to complete."] = "更改这些设定需要重新载入UI以完成设定" -- *v3
end

-- gFrameHandler (/glock)
do
	L["<Left-Click and drag to move the frame>"] = "<左键点击并拖曳来移动窗框>"
	L["<Left-Click+Shift to lock into position>"] = "<左键+Shift以锁定位置>"
	-- L["<Right-Click for options>"] = "<右键点击开启选项>" -- the panel module supplies this one
	-- L["Lock"] = "锁定"
	L["Center horizontally"] = "水平置中"
	L["Center vertically"] = "垂直置中"
	L["Cancel current position changes"] = "取消当前位置变更" -- *v3
	L["Reset to default position"] = "回复默认位置" -- *v3
	L["<Left-Click to toggle this category>"] = "<左键点击开启此分类>" -- *v3
	L["<Shift-Click to reset all frames in this category>"] = "<Shift键重置此分类所有框架>" -- *v3
	L["The frame '%s' is now locked"] = "%s 框架已锁定" -- *v3
	L["The group '%s' is now locked"] = "%s 群组已锁定" -- *v3
	L["All frames '%s' are now locked"] = "所有 %s 框架已锁定" -- *v3
	L["The frame '%s' is now unlocked"] = "%s 框架已解除锁定" -- *v3
	L["The group '%s' is now unlocked"] = "%s 群组已解除锁定" -- *v3
	L["All frames are now unlocked"] = "所有框架已解除锁定" -- *v3
	L["All frames are now locked"] = "所有框架已锁定" -- *v3
	L["No registered frames to unlock"] = "所有框架已解除锁定" -- *v3
	L["The group '%s' is empty"] = "%s 群组是空的" -- *v3
	L["Configuration Mode"] = "设定" -- *v3
	L["Frames are now unlocked for movement."] = "框架已解锁可移动" -- *v3
	L["<Left-Click once to raise a frame to the front>"] = "<左键点击一次将框架移到前景>" -- *v3
	L["<Left-Click and drag to move a frame>"] = "<左键点击并拖曳移动框架>" -- *v3
	L["<Left-Click+Shift to lock a frame into position>"] = "<左键+Shift在此位置锁定框架>" -- *v3
	L["<Right-Click a frame for additional options>"] = "<右键点击开启额外的选项>" -- *v3
	L["Reset all frames to their default positions"] = "回复所有框架默认位置" -- *v3
	L["Cancel all current position changes"] = "取消所有位置变更" -- *v3
	L["Lock all frames"] = "锁定所有框架" -- *v3
end

-- visible module names
do
	L["ActionBars"] = "动作条"
	L["ActionButtons"] = "动作按钮"
	L["Auras"] = "光环"
	L["Bags"] = "背包"
	L["Buffs & Debuffs"] = "增益减益效果"
	L["Castbars"] = "施法条"
	L["Core"] = "核心模块"
	L["Chat"] = "聊天"
	L["Combat"] = "战斗"
	L["CombatLog"] = "战斗纪录"
	L["CombatLogs"] = "战斗纪录" -- *v3
	L["Developer Tools"] = "开发用工具" -- *v3
	L["Errors"] = "错误讯息"
	L["Fonts"] = "字型" -- *v3
	L["Loot"] = "战利品"
	L["Map"] = "地图" -- *v3
	L["Merchants"] = "交易"
	L["Minimap"] = "小地图"
	L["Nameplates"] = "名条"
	L["Panels & Backdrops"] = "面板及动作条边框"
	L["Quests"] = "任务"
	L["Timers"] = "计时器"
	L["Tooltips"] = "提示说明"
	L["UI Panels"] = "面版"
	L["UI Skinning"] = "介面美化"
	L["UnitFrames"] = "单位框架"
		L["PartyFrames"] = "队伍框架"
		L["ArenaFrames"] = "竞技场框架"
		L["BossFrames"] = "首领框架"
		L["RaidFrames"] = "团队框架"
		L["MainTankFrames"] = "主坦框架"
	L["World Status"] = "世界状态"
end

-- various stuff used in the install tutorial's intro screen
do
	L["Credits to: "] = true
	L["Web: "] = true
	L["Download: "] = true
	L["Twitter: "] = true
	L["Facebook: "] = true
	L["YouTube: "] = true
	L["Contact: "] = true 

	L["_ui_description_"] = "%s 是一个取代暴雪魔兽世界默认游戏介面的用户端介面。它支持屏幕分辨率至少为1280像素宽度，但建议1440像素宽度|n|n此 UI 是欧洲 Draenor PVE 服务器一位联盟玩家 Lars Norberg 所撰写及维护，他的职业是野性德鲁伊叫 %s。"
	
	L["_install_guide_"] = "接下来几个步骤，会带你安装一些用户端介面模块。你稍后可以随时从游戏主菜单的选项中或输入|cFF4488FF/gui|r 指令改变设定。"
	
	L["_ui_credited_"] = "Banz Lin and various others(zhCN, zhTW), UnoPrata(ptBR, ptPT), Zork (for amazing tutorials and forum posts @ WoWInterface) and Kkthnxbye(compability and testing)"

	L["_ui_copyright_"] = "Copyright (c) 2013, Lars %s Norberg. All rights reserved."
end
