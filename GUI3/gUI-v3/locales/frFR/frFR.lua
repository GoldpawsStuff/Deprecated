local L = LibStub("gLocale-2.0"):NewLocale((select(1, ...)), "frFR", false)
if not L then return end

--[[
	frFR.lua edited by Wauk (EU-Varimathras)
]]--

--------------------------------------------------------------------------------------------------
--		Modules
--------------------------------------------------------------------------------------------------
-- ActionBars
do
	L["Layout '%s' doesn't exist, valid values are %s."] = "La disposition '%s' n'existe pas. Les valeurs autorisées sont %s"
	L["There is a problem with your ActionBars.|nThe user interface needs to be reloaded in order to fix it.|nReload now?"] = "il y a un problème avec vos barres d'actions. L'interface utilisateur doit être rechargée.|nLe faire maintenant?"
	L["<Left-Click> to show additional ActionBars"] = "<Click gauche pour afficher des barres d'actions supplémentaires>"
	L["<Left-Click> to hide this ActionBar"] = "<Click gauche pour masquer cette barre d'actions>"
	L["PetBar"] = "Barre du famillier" -- *v3
	L["StanceBar"] = "Barre de Postures" -- *v3
	L["TotemBar"] = "Barre de totems" -- *v3
	L["MicroMenu"] = "Micro-menu" -- *v3
	L["ActionBar%s"] = "Barre d'actions %s" -- *v3
	L["ExtraActionButton"] = "Bouton d'action supplémentaire" -- *v3
	L["Set to vertical orientation"] = "Orientation verticale" -- *v3
	L["Set to horizontal orientation"] = "Orientation horizontale" -- *v3
	L["Set number of buttons on each row"] = "Défini le nombre de boutons sur chaque rangée." -- *v3
	L["Show always"] = "Toujours afficher" -- *v3
	L["Show on mouseover"] = "Afficher au survol du curseur de la souris" -- *v3
	L["Hide always"] = "Ne jamais afficher" -- *v3
end

-- ActionBars: micromenu
do
	L["Achievements"] = "Haut-faits"
	L["Character Info"] = "Informations du personnage"
	L["Customer Support"] = "Support client"
	L["Dungeon Finder"] = "Recherche de donjon"
	L["Dungeon Journal"] = "Codex des donjons"
	L["Game Menu"] = "Menu du jeu"
	L["Guild"] = "Guilde"
	L["Guild Finder"] = "Recherche de guilde"
	L["You're not currently a member of a Guild"] = "Vous ne faites partie d'aucune guilde"
	L["Player vs Player"] = "Joueur contre joueur"
	L["Quest Log"] = "Journal de quêtes"
	L["Raid"] = true
	L["Spellbook & Abilities"] = "Grimoire et techniques"
	L["Starter Edition accounts cannot perform that action"] = "Un compte en édition découverte ne peut faire cela"
	L["Talents"] = true
	L["This feature becomes available once you earn a Talent Point."] = "Cette fonctionalité sera disponible quand vous obtiendrez un point de talent"
end

-- ActionBars: menu
do
	L["ActionBars are banks of hotkeys that allow you to quickly access abilities and inventory items. Here you can activate additional ActionBars and control their behaviors."] = "Les barres d'actions sont un regroupement de raccourcis vers vos techniques et objets dans l'inventaire. Vous pourrez activer içi des barres supplémentaires et les configurer"
	L["Secure Ability Toggle"] = "Activation sécurisée des techniques"
	L["When selected you will be protected from toggling your abilities off if accidently hitting the button more than once in a short period of time."] = "Si activé, empêchera d'activer/désactiver une technique si vous appuyez de nouveau sur le bouton dans un court laps de temps"
	L["Lock ActionBars"] = "Verrouiller les barres d'actions"
	L["Prevents the user from picking up/dragging spells on the action bar. This function can be bound to a function key in the keybindings interface."] = "Empêche d'ajouter/déplacer/supprimer un élément des barres d'action. Cette fonction peut être assignée à une touche dans l'interface de raccourcis (/bind)"
	L["Pick Up Action Key"] = "Touche de déverrouillage"
	L["ALT key"] = "Touche ALT"
	L["Use the \"ALT\" key to pick up/drag spells from locked actionbars."] = "Utiliser la touche \"ALT\" pour déplacer les éléments de la barre d'action verrouillée" 
	L["CTRL key"] = "Touche CTRL"
	L["Use the \"CTRL\" key to pick up/drag spells from locked actionbars."] = "Utiliser la touche \"CTRL\" pour déplacer les éléments de la barre d'action verrouillée" 
	L["SHIFT key"] = "Touche SHIFT"
	L["Use the \"SHIFT\" key to pick up/drag spells from locked actionbars."] = "Utiliser la touche \"SHIFT\" pour déplacer les éléments de la barre d'action verrouillée" 
	L["None"] = "Aucune"
	L["No key set."] = "Pas de touche assignée"
	L["Visible ActionBars"] = "Barres d'actions visibles"
	
	-- v3 layout 1, treating the bars as separate ones
	L["Micro Menu"] = true -- *v3
	L["Shapeshift/Aspect/Stance Bar"] = "Barre de Changeforme/Aspect/posture" -- *v3
	L["Pet ActionBar"] = "Barre d'actions du famillier" -- *v3
	L["Leftmost Side ActionBar [5]"] = "Barre d'actions la plus à gauche [5]" -- *v3
	L["Rightmost Side ActionBar [4]"] = "Barre d'actions la plus à droite [4]" -- *v3
	L["Bottom Right ActionBar [3b]"] = "Barre d'action bas-droite [3b]" -- *v3
	L["Bottom Left ActionBar [3a]"] = "Barre d'actions bas-gauche [3a]" -- *v3
	L["Bottom ActionBar [2]"] = "Barre d'action du bas [2]" -- *v3
	L["Main ActionBar [1]"] = "Barre d'actions principale [1]" -- *v3
	
	L["Show the bottom ActionBar [2]"] = "Afficher la Barre d'action du bas [2]" -- *v3
	L["Show the bottom left ActionBar [3a]"] = "Afficher la barre d'action bas-gauche [3a]" -- *v3
	L["Show the bottom right ActionBar [3b]"] = "Afficher la barre d'action bas-droite [3b]" -- *v3
	L["Show the rightmost side ActionBar [4]"] = "Afficher la barre d'action la plus à droite [4]"
	L["Show the leftmost side ActionBar [5]"] = "Afficher la barre d'action la plus à gauche [5]"
	L["Show the Pet ActionBar"] = "Afficher la barre d'action du famillier"
	L["Show the Shapeshift/Stance/Aspect Bar"] = "Afficher la barre de Changeforme/Aspect/Posture"
	L["Show the Micro Menu"] = "Afficher le micro-menu"

	L["Show the secondary ActionBar"] = "Afficher la barre d'actions secondaire"
	L["Show the third ActionBar"] = "Afficher la troisième barre d'actions"

	L["VehicleExitButton"] = "Bouton de sortie du véhicule" -- *v3

	-- L["Show the Totem Bar"] = "Afficher la barre de totems" -- doesn't exist anymore
	-- L["ActionBar Layout"] = "Disposition"
	-- L["Sort ActionBars from top to bottom"] = "Trier de haut en bas"
	-- L["This displays the main ActionBar on top, and is the default behavior of the UI. Disable to display the main ActionBar at the bottom."] = "La barre d'action principale sera en haut, comportement par défaut de l'UI. Désactiver pour afficher la barre d'action principale en bas"

	L["Button Size"] = "Taille des boutons"
	L["Set the size of the bar's buttons"] = "Défini la taille des boutons"
	L["Bar Width"] = "Largeur de la barre" -- *v3
	L["Choose the size of the buttons in your ActionBars"] = "Choisissez la taille des boutons de vos barres d'actions"
	L["Sets the size of the buttons in your ActionBars. Does not apply to the TotemBar."] = "Défini la taille des boutons de vos barres d'actions. Ne s'applique pas à la barre de totems"
	
	
	L["Page Switching"] = "Défilement de barres d'actions" -- *v3
	L["Here you can enable extra pageswitching for the main ActionBar for some classes."] = "Içi vous pourrez configurer les défilements de barre d'actions pour certaines classes" -- *v3
	L["Use Druid Prowl Bar"] = "Utiliser la barre d'action de Rôder du Druide" -- *v3
	L["Enabling this will switch to a separate bar when you use Prowl"] = "Si activé, utilisera une barre d'actions différente quand Rôder est activé" -- *v3
	L["Use Warlock Metamorphosis Bar"] = "Utiliser la barre d'action de Métamorphose du Démoniste" -- *v3
	L["Enabling this will switch to a separate bar when Metamorphosis is active"] = "Si activé, utilisera une barre d'action différente quand Métamorphose est activé" -- *v3
	L["Use Rogue Shadow Dance Bar"] = "Utiliser la barre de Danse de l'ombre du Voleur" -- *v3
	L["Enabling this will switch to a separate bar when Shadow Dance is active"] = "Si activé, utilisera une barre d'action différente quand Danse de l'ombre est activé" -- *v3
	L["Use Warrior Stance Bars"] = "Utiliser la barre de posture du Guerrier" -- *v3
	L["Enabling this will switch to a separate bar for each of your stances"] = "Si activé, chaque posture utilisera une barre d'action différente" -- *v3
end

-- ActionBars: Install
do
	L["Select Visible ActionBars"] = "Choix des barres d'actions visibles"
	L["Here you can decide what actionbars to have visible. Most actionbars can also be toggled by clicking the arrows located next to their edges which become visible when hovering over them with the mouse cursor. This does not work while engaged in combat."] = "Içi vous pourrez décider quelles barres d'actions seront visibles. La plupart des barres d'actions peuvent également s'activer/se désactiver en cliquant sur les fléches visibles sur les bords quand le curseur de la souris passe au dessus. Ne fonctionne pas en combat"
	L["You can try out different layouts before proceding!"] = "Vous pouvez essayer différentes dispositions avant de valider"

	L["Toggle Bar 2"] = "Activer la barre 2"
	L["Toggle Bar 3"] = "Activer la barre 3"
	L["Toggle Bar 4"] = "Activer la barre 4"
	L["Toggle Bar 5"] = "Activer la barre 5"
	L["Toggle Pet Bar"] = "Activer la barre du famillier"
	L["Toggle Shapeshift/Stance/Aspect Bar"] = "Activer la barre de Changeforme/Aspect/Posture"
	L["Toggle Totem Bar"] = "Activer la barre de totems"
	L["Toggle Micro Menu"] = "Activer le micro-menu"
	
	L["Select Main ActionBar Position"] = "Choisir l'emplacement de la barre d'actions principale"
	L["When having multiple actionbars visible, do you prefer to have the main actionbar displayed at the top or at the bottom? The default setting is top."] = "Quand plusieures barres d'actions sont visibles, placer la barre d'actions principale en haut (réglage par défaut) ou en bas?"
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
	L["ActionButtons are buttons allowing you to use items, cast spells or run a macro with a single keypress or mouseclick. Here you can decide upon the styling and visible elements of your ActionButtons."] = "Les boutons d'actions vous permettent d'utiliser des objets, de lancer des sorts ou une macro d'un simple appui sur une touche ou d'un click de souris. Vous pourrez les personnaliser içi"
	L["Button Styling"] = "Personnalisation"
	L["Button Text"] = "Texte"
	L["Show hotkeys on the ActionButtons"] = "Afficher le raccourcis sur le bouton"
	L["Show Keybinds"] = "Afficher la touche associée"
	L["This will display your currently assigned hotkeys on the ActionButtons"] = "Affichera le raccourcis actuel sur le bouton d'action"
	L["Show macro names on the ActionButtons"] = "Afficher le nom des macros"
	L["Show Names"] = "Afficher les noms"
	L["This will display the names of your macros on the ActionButtons"] = "Affichera le nom des macros sur les boutons d'actions"
	L["Show gloss layer on ActionButtons"] = "Afficher une couche brillante sur les boutons"
	L["Show Gloss"] = "Afficher la brillance"
	L["This will display the gloss overlay on the ActionButtons"] = "Affichera une couche brillante sur les boutons d'actions"
	L["Show shade layer on ActionButtons"] = "Afficher une couche d'ombre sur les boutons d'actions"
	L["This will display the shade overlay on the ActionButtons"] = "Affichera une couche d'ombre sur les boutons d'actions"
	L["Show Shade"] = "Afficher les ombres"
	--L["Set amount of gloss"] = "Définir la brillance"
	--L["Set amount of shade"] = "Définir les ombres"
end

-- Auras
do
	L["Player Buffs"] = "Buffs du joueur" -- *v3
	L["Player Debuffs"] = "Debuffs du joueur" -- *v3
	L["These options allow you to control how buffs and debuffs are displayed. If you wish to change the position of the buffs and debuffs, you can unlock them for movement with |cFF4488FF/glock|r."] = "Ces options vous permettent de contrôler la façon dont les buffs/debuffs sont affichés. Si vous désirez changer leur emplacement, utilisez la commande |cFF4488FF/glock|r"
	L["Aura Styling"] = "Personnalisation des auras"
	L["Show gloss layer on Auras"] = "Afficher une couche brillante sur les auras"
	L["Show Gloss"] = "Afficher la brillance" 
	L["This will display the gloss overlay on the Auras"] = "Ceci affichera la couche brillante sur les auras"
	L["Show shade layer on Auras"] = "Afficher la couche d'ombre sur les auras"
	L["This will display the shade overlay on the Auras"] = "Ceci afficher une couche d'ombre sur les auras"
	L["Show Shade"] = "Afficher les ombres" 
	L["Time Display"] = "Affichage du temps restant"
	L["Show remaining time on Auras"] = "Afficher le temps restant sur les auras"
	L["Show Time"] = "Montrer le temps restant"
	L["This will display the currently remaining time on Auras where applicable"] = "Ceci affichera le temps restant sur les auras, si applicable"
	L["Display remaining time as a timer bar instead of text"] = "Affiche le temps restant sous la forme d'une barre au lieu de texte" -- *v3
	L["Consolidate Buffs"] = "Rendre plus visible les buffs" -- *v3
	L["Show cooldown spirals on Auras"] = "Afficher la spirale de cooldown sur les auras"
	L["Show Cooldown Spirals"] = "Afficher les spirales de cooldown"
	L["This will display cooldown spirals on Auras to indicate remaining time"] = "Ceci affichera la spirale de cooldown sur les auras"
end

-- Bags
do
	L["Gizmos"] = "Divers" -- used for "special" things like the toy train set
	L["Equipment Sets"] = "Ensembles d'équipement" -- used for the stored equipment sets
	L["New Items"] = "Nouveaux objets" -- used for the unsorted new items category in the bags
	L["Click to sort"] = "Cliquer pour trier"
	L["<Left-Click to toggle display of the Bag Bar>"] = "<Click gauche pour afficher/masquer la barre des sacs>"
	L["<Left-Click to open the currency frame>"] = "<Click gauche pour ouvrir la fenêtre des devises>"
	L["<Left-Click to open the category selection menu>"] = "<Click gauche pour ouvrir le menu de selection des catégories>"
	L["<Left-Click to search for items in your bags>"] = "<Click gauche pour rechercher des objets dans vos sacs>"
	L["Close all your bags"] = "Fermer tous vos sacs."
	L["Close this category and keep it hidden"] = "Fermer cette catégorie et la masquer"
	L["Close this category and show its contents in the main container"] = "Fermer cette catégorie et afficher son contenu dans le sac principal"
end

-- Bags: menus 
do
	L["A character can store items in its backpack, bags and bank. Here you can configure the appearance and behavior of these."] = "Un personnage peut stocker des objets dans son sac à dos, dans des sacs et à la banque. Vous pourrez changer l'apparence et le comportement de ceux-ci içi"
	L["Container Display"] = "Afficher le conteneur"
	L["Show this category and its contents"] = "Afficher cette catégorie et son contenu"
	L["Hide this category and all its contents completely"] = "Cacher cette catégorie et son contenu"
	L["Bypass"] = "Ignorer"
	L["Hide this category, and display its contents in the main container instead"] = "Cacher cette catégorie, et afficher son contenu dans le conteneur principal"
	L["Choose the minimum item quality to display in this category"] = "Choisissez la qualité d'objet minimum à afficher dans cette catégorie"
	L["Bag Width"] = "Largeur du sac"
	L["Sets the number of horizontal slots in the bag containers. Does not apply to the bank."] = "Défini le nombre de slots horizontaux dans le conteneur des sacs. Ne s'applique pas à la banque"
	L["Bank Column %d Width"] = "Largeur de la colonne %d de la banque"
	L["Sets the number of horizontal slots in the given column of bank containers."] = "Défini le nombre de slots horizontaux dans la colonne tant du conteneur Banque"
	L["Bag Scale"] = "Echelle du sac"
	L["Sets the overall scale of the bags"] = "Défini l'echelle globale des sacs"
	L["Restack"] = "Réempiler"
	L["Automatically restack items when opening your bags or the bank"] = "Réempiler automatiquement les objets en ouvrant vos sacs ou la banque"
	L["Automatically restack when looting or crafting items"] = "Réempiler automatiquement les objets en lootant ou à la création (métiers)" 
	L["Sorting"] = "Triage"
	L["Sort the items within each container"] = "Trier les objets dans chaque conteneur"
	L["Sorts the items inside each container according to rarity, item level, name and quanity. Disable to have the items remain in place."] = "Trier les objets dans chaque conteneur selon la rareté, le niveau d'objet, le nom et la quantité. Désactiver pour empêcher le triage"
	L["Compress empty bag slots"] = "Compresser les slots vides"
	L["Compress empty slots down to maximum one row of each type."] = "Compresser les slots libres jusqu'a une ligne de chaque type"
	L["Lock the bags into place"] = "Vérrouiller l'emplacement des sacs"
	L["Slot Button Size"] = "Taille des emplacements"
	L["Choose the size of the slot buttons in your bags."] = "Choisissez la taille des slots dans les sacs"
	L["Sets the size of the slot buttons in your bags. Does not affect the overall scale."] = "Défini la taille des slots dans les sacs. Sans effet sur l'echelle globale de ceux-ci"
	L["Bag scale"] = "Echelle"
	L["Button Styling"] = "Personnalisation des boutons" 
	L["Show gloss layer on buttons"] = "Afficher une couche brillante sur les boutons"
	L["Show Gloss"] = "Afficher la brillance" 
	L["This will display the gloss overlay on the buttons"] = "Affichera une couche brillante sur les boutons"
	L["Show shade layer on buttons"] = "Afficher une couche d'ombre sur les boutons"
	L["This will display the shade overlay on the buttons"] = "Affichera une couche d'ombre sur les boutons"
	L["Show Shade"] = "Afficher l'ombre" 
	L["Show Durability"] = "Afficher la durabilité"
	L["This will display durability on damaged items in your bags"] = "Affichera la durabilité des objets endommagés dans vos sacs"
	L["Color unequippable items red"] = "Colorier en rouge les objets inéquipables"
	L["This will color equippable items in your bags that you are unable to equip red"] = "Affichera en rouge les objets que vous ne pouvez pas équiper"
	L["Layout Presets"] = "Pré-réglage de la disposition" -- *v3
	L["Apply 'All In One' Layout"] = "Appliquer la disposition 'Tout en un'"
	L["Click here to automatically configure the bags and bank to be displayed as large unsorted containers."] = "Cliquer içi pour configurer automatiquement les sacs et la banque en un seul conteneur"
	L["Apply %s's Layout"] = "Appliquer la disposition de %s"
	L["Click here to apply the default layout with categories, sorting and empty space compression."] = "Cliquer pour utiliser la disposition par défaut avec tri des objets et compression des slots libres dans les sacs" -- *v3
	L["The bags can be configured to work as one large 'all-in-one' container, with no categories, no sorting and no empty space compression. If you wish to have that type of layout, click the button:"] = "Les sacs peuvent être configurés en un seul conteneur 'Tout en un' sans catégories ni triage ni compression des slots libres. Si vous souhaitez cette disposition, cliquez sur le bouton"
	L["The 'New Items' category will display newly acquired items if enabled. Here you can set which categories and rarities to include."] = "La catégorie 'Nouveaux objets' affichera les objets fraichements acquis si activé. Vous pourrez choisir içi quelles catégories ainsi que la rareté à afficher"
	L["Minimum item quality"] = "Qualité minimum des objets"
	L["Choose the minimum item rarity to be included in the 'New Items' category."] = "Choisissez la qualité minimum des objets inclus dans la catégorie 'Nouveaux objets'"
end

-- Bags: Install
do
	L["Select Layout"] = "Choix de la disposition"
	L["The %s bag module has a variety of configuration options for display, layout and sorting."] = "Le module de sacs de %s posséde une varieté d'options d'affichage, de disposition, et de tri"
	L["The two most popular has proven to be %s's default layout, and the 'All In One' layout."] = "Les deux plus populaires à ce jour sont la disposition par défaut de %s, et la disposition 'Tout en un'"
	L["The 'All In One' layout features all your bags and bank displayed as singular large containers, with no categories, no sorting and no empty space compression. This is the layout for those that prefer to sort and control things themselves."] = "Dans la disposition 'Tout en un', les sacs peuvent être configurés en un seul conteneur 'Tout en un' sans catégories ni triage ni compression des slots libres. C'est la disposition de ceux qui préfèrent gérer les choses eux-mêmes"
	L["%s's layout features the opposite, with all categories split into separate containers, and sorted within those containers by rarity, item level, stack size and item name. This layout also compresses empty slots to take up less screen space."] = "Dans la disposition de %s au contraire, le tri des objets se fait par catégories, rareté, niveaux d'objets, taille des piles, et nom des objets. Une compression des slots libres dans les sacs pour économiser l'espace libre sur l'écran est également effectuée"
	L["You can open your bags to test out the different layouts before proceding!"] = "Vous pouvez ouvrir vos sacs pour essayer les différentes dispositions avant de valider votre choix"
end

-- Bags: chat commands
do
	L["Empty bag slots will now be compressed"] = "Les slots libres dans les sacs vont maintenant êtres compressés"
	L["Empty bag slots will no longer be compressed"] = "Les slots libres dans les sacs ne seront plus compressés"
end

-- Bags: restack
do
	L["Restack is already running, use |cFF4488FF/restackbags resume|r if stuck"] = "Le réempilage des objets est en cours, utilisez |cFF4488FF/restackbags resume|r si l'opération se bloque en cours"
	L["Resuming restack operation"] = "Reprise de l'opération de réempilage"
	L["No running restack operation to resume"] = "Aucune opération en cours à relancer"
	L["<Left-Click to restack the items in your bags>"] = "<Click gauche pour réempiler les objets dans vos sacs"
	L["<Left-Click to restack the items in your bags>|n<Right-Click for options>"] = "<Click gauche pour réempiler les objets dans vos sacs>.|n<Click droit pour les options>"
end

-- Castbars: menu
do
	L["Here you can change the size and visibility of the on-screen castbars. If you wish to change their position, you can unlock them for movement with |cFF4488FF/glock|r"] = true
	L["Show the player castbar"] = "Afficher la barre de sorts du joueur"
	L["Show for tradeskills"] = "Afficher pour les métiers"
	L["Show the pet castbar"] = "Afficher la barre de sorts du famillier"
	L["Show the target castbar"] = "Afficher la barre de sorts de la cible"
	L["Show the focus target castbar"] = "Afficher la barre de sorts du focus"
	L["Set Width"] = "Largeur"
	L["Set the width of the bar"] = "Défini la largeur de la barre"
	L["Set Height"] = "Hauteur"
	L["Set the height of the bar"] = "Défini la hauteur de la barre"
end

-- Chat: timestamp settings tooltip (http://www.lua.org/pil/22.1.html)
do
	L["|cFFFFD100%a|r abbreviated weekday name (e.g., Wed)"] = true
	L["|cFFFFD100%A|r full weekday name (e.g., Wednesday)"] = true
	L["|cFFFFD100%b|r abbreviated month name (e.g., Sep)"] = true
	L["|cFFFFD100%B|r full month name (e.g., September)"] = true
	L["|cFFFFD100%c|r date and time (e.g., 09/16/98 23:48:10)"] = true
	L["|cFFFFD100%d|r day of the month (16) [01-31]"] = true
	L["|cFFFFD100%H|r hour, using a 24-hour clock (23) [00-23]"] = true
	L["|cFFFFD100%I|r hour, using a 12-hour clock (11) [01-12]"] = true
	L["|cFFFFD100%M|r minute (48) [00-59]"] = true
	L["|cFFFFD100%m|r month (09) [01-12]"] = true
	L["|cFFFFD100%p|r either 'am' or 'pm'"] = true
	L["|cFFFFD100%S|r second (10) [00-61]"] = true
	L["|cFFFFD100%w|r weekday (3) [0-6 = Sunday-Saturday]"] = true
	L["|cFFFFD100%x|r date (e.g., 09/16/98)"] = true
	L["|cFFFFD100%X|r time (e.g., 23:48:10)"] = true
	L["|cFFFFD100%Y|r full year (1998)"] = true
	L["|cFFFFD100%y|r two-digit year (98) [00-99]"] = true
	L["|cFFFFD100%%|r the character `%´"] = true -- 'character' here refers to a letter or number, not a game character...
end

-- Chat: names of the chat frames handled by the addon
do
	L["Main"] = "Principal"
	L["Loot"] = true
	L["Log"] = true
	L["Public"] = true
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
	L["Guild XP"] = "XP de guilde" -- Guild Experience / Expérience de guilde
	L["HK"] = "VH" -- Honorable Kill / Victoire Honorable
	L["XP"] = "XP" -- Experience / Expérience
end

-- Chat: menu
do
	L["Here you can change the settings of the chat windows and chat bubbles. |n|n|cFFFF0000If you wish to change visible chat channels and messages within a chat window, background color, font size, or the class coloring of character names, then Right-Click the chat tab located above the relevant chat window instead.|r"] = "Vous pourrez changer içi les réglages de la discussion et des bulles de discussion.|n|n|cFFFF0000Si vous désirez changer les canaux de discussion et les messages visibles au sein d'une fenêtre de discussion, la couleur de l'arrière-plan, la taille de la police d'écriture, ou la coloration des noms des joueurs selon leur classe, faites un click droit sur l'onglet de la fenêtre concernée|r"
	L["Enable sound alerts when receiving whispers or private Battle.net messages."] = "Activer les alertes sonores pour les messages privés ou Battle.net"

	L["Chat Display"] = "Afficher les discussions"
	L["Abbreviate channel names."] = "Abrèger les noms des canaux"
	L["Abbreviate global strings for a cleaner chat."] = "Abrèger les chaines globales pour une fenêtre plus lisible"
	L["Display brackets around player- and channel names."] = "Afficher des crochets ( [ ] ) autour du nom des joueurs et des canaux"
	L["Use emoticons in the chat"] = "Utiliser les émoticones dans la discussion"
	L["Auto-align the text depending on the chat window's position."] = "Aligner automatiquement le texte selon la position de la fenêtre de discussion"
	L["Auto-align the main chat window to the bottom left panel/corner."] = "Aligner automatiquement la fenêtre de discussion principale avec le panneau/coin inférieur gauche"
	L["Auto-size the main chat window to match the bottom left panel size."] = "Ajuster automatiquement la taille de la fenêtre de discussion à celle du panneau inférieur gauche"

	L["Timestamps"] = "Marqueurs temporels"
	L["Show timestamps."] = "Afficher"
	L["Timestamp color:"] = "Couleur"
	L["Timestamp format:"] = "Format"

	L["Chat Bubbles"] = "Bulles de discussion"
	L["Collapse chat bubbles"] = "Réduire"
	L["Collapses the chat bubbles to preserve space, and expands them on mouseover."] = "Réduire pour économiser de l'espace, et augmenter au survol du curseur de souris"
	L["Display emoticons in the chat bubbles"] = "Afficher les émoticones dans les bulles de discussion"

	L["Loot Window"] = "Fenêtre de loot"
	L["Create 'Loot' Window"] = "Créer la fenêtre de 'Loot'"
	L["Enable the use of the special 'Loot' window."] = "Autoriser l'utilisation de la fenêtre spéciale 'Loot'"
	L["Maintain the channels and groups of the 'Loot' window."] = "Conserver les canaux et groupes de la fenêtre 'Loot'"
	L["Auto-align the 'Loot' chat window to the bottom right panel/corner."] = "Aligner automatiquement la fenêtre 'Loot' avec le panneau/coin inférieur droit"
	L["Auto-size the 'Loot' chat window to match the bottom right panel size."] = "Ajuster automatiquement la taille de la fenêtre 'Loot' à celle du panneau inférieur droit"
end

-- Chat: Install
do
	L["Public Chat Window"] = "Fenêtre de discussion publique"
	L["Public chat like Trade, General and LocalDefense can be displayed in a separate tab in the main chat window. This will keep your main chat window free from intrusive spam, while still having all the relevant public chat available. Do you wish to do so now?"] = "Les discussions publiques telles que échanges, général et défense locale peuvent êtres affichés dans des onglets séparés. Cela gardera votre fenêtre de discussion principale libre de spam, tout en ayant toujours toutes les discussions publiques disponibles. Voulez-vous faire cela?"
	
	L["Loot Window"] = "Fenêtre de loot"
	L["Information like received loot, crafted items, experience, reputation and honor gains as well as all currencies and similar received items can be displayed in a separate chat window. Do you wish to do so now?"] = "Les loot, objets fabriqués, l'expérience, la réputation et les gains d'honneur ainsi que toutes les devises et objets similaires reçus peuvent êtres affichés dans une fenêtre de discussion séparée. Voulez-vous faire cela maintenant?"
	
	L["Initial Window Size & Position"] = "Taille et position initiale des fenêtres"
	L["Your chat windows can be configured to match the unitframes and the bottom UI panels in size and position. Do you wish to do so now?"] = "Votre fenêtre de discussion peut être configurée pour correspondre aux cadres d'unités et aux panneaux inférieurs de l'UI en taille et position. Voulez-vous faire cela maintenant?"
	L["This will also dock any additional chat windows."] = "Cela ajoutera également une fenêtre de discussion supplémentaire"	
	
	L["Window Auto-Positioning"] = "Positionnement automatique de la fenêtre"
	L["Your chat windows will slightly change position when you change UI scale, game window size or screen resolution. The UI can maintain the position of the '%s' and '%s' chat windows whenever you log in, reload the UI or in any way change the size or scale of the visible area. Do you wish to activate this feature?"] = "Votre fenêtre de discussion changera légérement de position quand vous changerez l'echelle de l'UI, la résolution de l'écran, ou la taille de la fenêtre de jeu. L'UI peut conserver la position des fenêtres de discussion %s et %s à chaque connection, rechargement de l'UI ou redimensionnement de l'espace visible. Voulez-vous activer cette fonctionnalité?"
	
	L["Window Auto-Sizing"] = "Ajustement automatique de la taille de la fenêtre"
	L["Would you like the UI to maintain the default size of the chat frames, aligning them in size to visually fit the unitframes and bottom UI panels?"] = "Voulez-vous que l'UI conserve la taille par défaut des fenêtres de discussion, en les redimensionnant pour correspondre aux cadres d'unités et aux panneaux du bas de l'UI?"
	
	L["Channel & Window Colors"] = "Couleur des canaux et fenêtres"
	L["Would you like to change chatframe colors to what %s recommends?"] = "Voulez-vous changer les couleurs de la fenêtre de discussion pour celles recommandées par %s?"
end

-- Combat
do
	L["dps"] = true -- Damage Per Second
	L["hps"] = true -- Healing Per Second
	L["tps"] = true -- Threat Per Second
	L["Last fight lasted %s"] = "Le dernier combat à duré %s"
	L["You did an average of %s%s"] = "Votre moyenne de %s est de %s"
	L["You are overnuking!"] = "Vous êtes en train de prendre l'aggro"
	L["You have aggro, stop attacking!"] = "Vous avez l'aggro, cessez d'attaquer!"
	L["You are tanking!"] = "Vous tankez!"
	L["You are losing threat!"] = "Vous perdez de la menace!"
	L["You've lost the threat!"] = "Vous avez perdu l'aggro!"
end

-- Combat: menu
do
	L["Simple DPS/HPS Meter"] = "Compteur DPS/HPS simple"
	L["Enable simple DPS/HPS meter"] = "Activer le compteur DPS/HPS simple"
	L["Show DPS/HPS when you are solo"] = "Afficher le DPS/HPS en solo"
	L["Show DPS/HPS when you are in a PvP instance"] = "Afficher le DPS/HPS en JcJ"
	L["Display a simple verbose report at the end of combat"] = "Afficher un bref rapport du combat à la fin de celui-ci"
	L["Minimum DPS to display: "] = "DPS minimum à afficher : "
	L["Minimum combat duration to display: "] = "Durée minimale de combat à afficher : "
	L["Simple Threat Meter"] = "Compteur de menace simple"
	L["Enable simple Threat meter"] = "Activer le compteur de menace simple"
	L["Use the Focus target when it exists"] = "Utiliser la cible du focus quand elle existe"
	L["Enable threat warnings"] = "ACtiver les alertes pour la menace"
	L["Show threat when you are solo"] = "Afficher la menace en solo"
	L["Show threat when you are in a PvP instance"] = "Afficher la menace en JcJ"
	L["Show threat when you are a healer"] = "Afficher la menace quand vous êtes soigneur"
	L["Enable simple scrolling combat text"] = "Activer le texte de combat défilant simple"
end

-- Combatlog
do
	L["GUIS"] = true -- the visible name of our custom combat log filter, used to identify it
	L["Show simplified messages of actions done by you and done to you."] = "Affiche des messages simplifiés des actions faites par vous et sur vous" -- the description of this filter
end

-- Combatlog: menu
do
	L["Maintain the settings of the GUIS filter so that they're always the same"] = "Conserver les réglages des filtres de GUI afins qu'ils ne changent pas"
	L["Keep only the GUIS and '%s' quickbuttons visible, with GUIS at the start"] = "Conserver seulement les boutons rapides de GUI et %s au démarrage"
	L["Autmatically switch to the GUIS filter when you log in or reload the UI"] = "Basculer automatiquement sur les filtres de GUI quand vous vous logguez ou rechargez l'UI"
	L["Autmatically switch to the GUIS filter whenever you see a loading screen"] = "Basculer automatiquement sur les filtres de GUI quand vous apercevez un écran de chargement"
	L["Automatically switch to the GUIS filter when entering combat"] = "Basculer automatiquement sur les filtres de GUI quand vous entrez en combat"
end

-- Loot
do
	L["BoE"] = "LQUE" -- Bind on Equip / Lié quand équipé
	L["BoP"] = "LQR" -- Bind on Pickup / Lié quand ramassé
end

-- Merchant
do
	L["Selling Poor Quality items:"] = "Vente des objets de mauvaise qualité"
	L["-%s|cFF00DDDDx%d|r %s"] = true -- nothing to localize in this one, unless you wish to change the formatting
	L["Earned %s"] = "Gagné : %s"
	L["You repaired your items for %s"] = "Vos réparations vous ont coutées %s"
	L["You repaired your items for %s using Guild Bank funds"] = "Vos réparations ont coutées %s à la banque de guilde"
	L["You haven't got enough available funds to repair!"] = "Vous n'avez pas assez d'argent pour payer vos réparations"
	L["Your profit is %s"] = "Vos profits sont de %s"
	L["Your expenses are %s"] = "Vos dépenses sont de %s"
	L["Poor Quality items will now be automatically sold when visiting a vendor"] = "Les objets de mauvaise qualité seront automatiquement vendus"
	L["Poor Quality items will no longer be automatically sold"] = "Les objets de mauvaise qualité ne seront plus automatiquement vendus"
	L["Your items will now be automatically repaired when visiting a vendor with repair capabilities"] = true
	L["Your items will no longer be automatically repaired"] = "vos objets ne seront plus réparés automatiquement"
	L["Your items will now be repaired using the Guild Bank if the options and the funds are available"] = "Vos objets ne seront plus réparés sur les fonds de la banque de guilde"
	L["Your items will now be repaired using your own funds"] = "Vos objets seront réparés sur vos propres fonds"
	L["Detailed reports for autoselling of Poor Quality items turned on"] = "Les rapports de ventes automatiques des objets de mauvaise qualité détaillés sont activés"
 	L["Detailed reports for autoselling of Poor Quality items turned off, only summary will be shown"] = "Les rapports de ventes automatiques des objets de mauvaise qualité détaillés sont désactivés, seul un résumé sera affiché"
	L["Toggle autosell of Poor Quality items"] = "Activer la vente automatique des objets de mauvaise qualité"
	L["Toggle display of detailed sales reports"] = "Activer les rapports de vente détaillés"
	L["Toggle autorepair of your armor"] = "Activer les réparations automatiques de votre armure"
	L["Toggle Guild Bank repairs"] = "Activer les réparatons de guilde"
	L["<Alt-Click to buy the maximum amount>"] = "<Alt-click pour en acheter la quantité maximum>"
end

-- Merchant: Menu
do
	L["Here you can configure the options for automatic actions upon visiting a merchant, like selling junk and repairing your armor."] = "Içi vous pourrez configurer les actions automatiques en visitant les marchands, telles que vendre les objets inutils et réparer votre armure"
	L["Automatically repair your armor and weapons"] = "Réparer automatiquement vos armes et armure"
	L["Enabling this option will show a detailed report of the automatically sold items in the default chat frame. Disabling it will restrict the report to gold earned, and the cost of repairs."] = "Activer cette option affichera un rapport détaillé de vos ventes dans la fenêtre de discussion. La désactiver n'afffichera plus qu'un rapport de l'argent gagné et des dépenses pour vos réparations"
	L["Automatically sell poor quality items"] = "Vendre automatiquement les objets de mauvaise qualité"
	L["Enabling this option will automatically sell poor quality items in your bags whenever you visit a merchant."] = "Cette option activera la vente automatique des objets de mauvaise qualité dans vos sacs lorsque vous visiterez un marchand"
	L["Show detailed sales reports"] = "Afficher un rapport de vente détaillé"
	L["Enabling this option will automatically repair your items whenever you visit a merchant with repair capability, as long as you have sufficient funds to pay for the repairs."] = "Cette option activera les réparations automatiques de votre équipement et de vos objets quand vous visiterez un marchand avec capacité de réparation, si vous avez les fonds disponibles"
	L["Use your available Guild Bank funds to when available"] = "Utilisez les fonds de la banque de guilde quand c'est possible"
	L["Enabling this option will cause the automatic repair to be done using Guild funds if available."] = "Cette option activera la réparation automatique de vos objets grace aux fonds de la banque de guidlde"
end

-- Minimap
do
	L["Calendar"] = "Calendrier"
	L["New Event!"] = "Nouvel événement"
	L["New Mail!"] = "Nouveau courrier"
	
	L["Raid Finder"] = "Recherche de Raid"
	
	L["(Sanctuary)"] = "(Sanctuaire)"
	L["(PvP Area)"] = "(Zone Jcj)"
	L["(%s Territory)"] = "(Territoire : %s)"
	L["(Contested Territory)"] = "(Territoire contesté)"
	L["(Combat Zone)"] = "(Zone de combats)"
	L["Social"] = true
	
	L["<Left-Click to toggle the Calendar>"] = "<Click gauche pour afficher le calendrier>" -- *v3
end

-- Minimap: menu
do
	L["The Minimap is a miniature map of your closest surrounding areas, allowing you to easily navigate as well as quickly locate elements such as specific vendors, or a herb or ore you are tracking. If you wish to change the position of the Minimap, you can unlock it for movement with |cFF4488FF/glock|r."] = "La mini-carte est une représentation miniature de la zone alentour, vous permettant de vous déplacer facilement et de localiser rapidement des éléments tels que certains vendeurs, les plantes, ou les minerais que vous cherchez. Vous pouvez changer sa position avec |cFF4488FF/glock|r." 
	L["Display the clock"] = "Afficher l'horloge"
	L["Display the current player coordinates on the Minimap when available"] = "Afficher les coordonées du joueur sur la mini-carte quand disponible"
	L["Show seconds"] = "Afficher les secondes" -- *v3
	L["Use 24 hour time"] = "Utiliser le format 24h" -- *v3
	L["Display the server time instead of the local time"] = "Afficher l'heure du serveur au lieu de l'heure locale" -- *v3
	L["Use the Mouse Wheel to zoom in and out"] = "Zoomer/dezoomer avec la molette de la souris"
	L["Display the difficulty of the current instance when hovering over the Minimap"] = "Afficher la difficulté de l'instance actuelle au survol de la mini-carte"
	L["Display the shortcut menu when clicking the middle mouse button on the Minimap"] = "Afficher le menu de raccourcis en cliquant sur la mini-carte avec le bouton du millieu de la souris"
	L["Rotate Minimap"] = "Rotation"
	L["Check this to rotate the entire minimap instead of the player arrow."] = "Cocher pour faire tourner la mini-carte plutôt que la flêche du joueur"
	L["Only show the clock when hovering over the Minimap"] = "Afficher l'horloge uniquement au survol de la mini-carte du curseur de la souris" -- *v3
	L["Display the current location"] = "Afficher le lieu actuel" -- *v3
	L["Only show the current location when hovering over the Minimap"] = "Afficher le lieu actuel uniquement au survol de la mini-carte du curseur de la souris" -- *v3
	L["Display the calendar button"] = "Afficher le bouton du calendrier" -- *v3
	L["Only show the calendar button when hovering over the Minimap"] = "Afficher le bouton du calendrier uniquement au survol de la mini-carte du curseur de la souris" -- *v3
end

-- Nameplates: menu
do
	L["Nameplates are small health- and castbars visible over a character or NPC's head. These options allow you to control which Nameplates are visible within the game field while you play."] = "Les plaques d'identification sont de petites barres de vie et de sorts visible au-dessus de certaines unités. Ces options vous permettent de définir lesquelles sont visibles sur le terrain en jeu"
	L["Automatically enable nameplates based on your current specialization"] = "Activation automatique des plaques d'identification basée sur votre spécialisation actuelle"
	L["Automatically enable friendly nameplates for repeatable quests that require them"] = "Activation automatique des plaques d'identification amicales pour les quêtes répétables"
	L["Only show friendly nameplates when engaged in combat"] = "Afficher les plaques d'identification des alliés seulement en combat"
	L["Only show enemy nameplates when engaged in combat"] = "Afficher les plaques d'identifications ennemies seulement en combat"
	L["Use a blacklist to filter out certain nameplates"] = "Utiliser une liste noire pour filtrer certaines plaques d'identification"
	L["Display character level"] = "Afficher le niveau du personnage"
	L["Hide for max level characters when you too are max level"] = "Masquer pour les personnages de niveau maximum quand vous êtes vous aussi au niveau maximum"
	L["Display character names"] = "Afficher le nom des personnages"
	L["Display combo points on your target"] = "Afficher les points de combo de la cible"
	L["Show Class Colors in Unit Nameplates for enemies"] = "Afficher les couleurs de classe dans les plaques d'identification des ennemis" -- *v3	
	L["Nameplate Motion Type"] = "Type de mouvement des plaques d'identification"
	L["Overlapping Nameplates"] = "Chevauchement des plaques d'identification"
	L["Stacking Nameplates"] = "Empiler les plaques d'identification"
	L["Spreading Nameplates"] = "Espacer les plaques d'identification"
	L["This method will allow nameplates to overlap."] = "Chevauchement autorisée"
	L["This method avoids overlapping nameplates by stacking them vertically."] = "Pas de chevauchement, espacement vertical"
	L["This method avoids overlapping nameplates by spreading them out horizontally and vertically."] = "Pas de chevauchement, espacement horizontal et vertical"
	
	L["Friendly Units"] = "Unités amicales"
	L["Friendly Players"] = "Joueur amical"
	L["Turn this on to display Unit Nameplates for friendly units."] = "Afficher les plaques d'identifaction des unités amicales"
	L["Enemy Units"] = "Unités ennemies"
	L["Enemy Players"] = "Joueurs ennemis"
	L["Turn this on to display Unit Nameplates for enemies."] = "Afficher les plaques d'identification des unités ennemies"
	L["Pets"] = "Familliers"
	L["Turn this on to display Unit Nameplates for friendly pets."] = "Afficher les plaques d'identifications des familliers amicaux"
	L["Turn this on to display Unit Nameplates for enemy pets."] = "Afficher les plaques d'identifications des familliers inamicaux"
	L["Totems"] = true
	L["Turn this on to display Unit Nameplates for friendly totems."] = "Afficher les plaques d'identifications des totems amicaux"
	L["Turn this on to display Unit Nameplates for enemy totems."] = "Afficher les plaques d'identifications des totems inamicaux"
	L["Guardians"] = "Gardiens"
	L["Turn this on to display Unit Nameplates for friendly guardians."] = "Afficher les plaques d'identifications des gardiens amicaux"
	L["Turn this on to display Unit Nameplates for enemy guardians."] = "Afficher les plaques d'identifications des gardiens inamicaux"
end

-- Panels & Backdrops
do
	L["Here you can set the visibility and behaviour of various objects like the XP and Reputation Bars, the Battleground Capture Bars and more. If you wish to change their position, you can unlock them for movement with |cFF4488FF/glock|r."] = "Içi vous pourrez changer le comportement et la visibilité de divers éléments, tels que les barres de réputation et d'XP, la barre de capture d'objectifs JcJ, et bien d'autres. Si vous désirez changer leur emplacement, utilisez |cFF4488FF/glock|r"

	L["StatusBars"] = "Barres de status"
	L["Show the player experience bar."] = "Afficher la barre d'expérience"
	L["Show when you are at your maximum level or have turned off experience gains."] = "Afficher même si les gains d'expériences sont stoppés ou que vous êtes au niveau maximum"
	L["Show the currently tracked reputation."] = "Afficher la réputation suivie"
	L["Show the capturebar for PvP objectives."] = "Afficher la barre de capture des objectifs JcJ"
	L["XP-, Rep- & Capture Bars"] = "Barres de captures, réputation & XP" -- *v3

	L["Panels & Backdrops"] = "Panneaux et arrière-plans" -- *v3
	L["Left Infopanel"] = "Panneau de gauche" -- *v3
	L["Right Infopanel"] = "Panneau de droite" -- *v3
	L["Bottom Backdrop"] = "Arrière-plan du bas" -- *v3
	L["Bottom Left Backdrop"] = "Arrière-plan bas-gauche" -- *v3
	L["Bottom Right Backdrop"] = "Arrière-plan bas-droite" -- *v3
	L["Side Backdrop"] = "Arrière-plan latéral" -- *v3

	L["<Left-Click to open all bags>"] = "<Click gauche pour ouvrir tous les sacs>"
	L["<Left-Click to toggle backpack>"] = "<Click gauche pour ouvrir le sac à dos>"
	L["<Right-Click for options>"] = "<Click droit pour les options>"
	L["Free/Max"] = "Libre/Max"
	L["Guild: %s"] = "Guilde : %s"
	L["No Guild"] = "Pas de guilde"
	L["New Mail!"] = "Nouveau courrier!"
	L["No Mail"] = "Pas de courrier"
	L["Total Usage"] = "Util. mémoire totale :"
	L["Tracked Currencies"] = "Devises suivies"
	L["Additional AddOns"] = "Autres Add-ons"
	L["Network Stats"] = "Etat du réseau"
	L["World latency:"] = "Latence Monde:"
	L["World latency %s:"] = "Latence Monde %s :" 
	L["(Combat, Casting, Professions, NPCs, etc)"] = "(Combat, sorts, métiers, NPC, etc)"
	L["Home latency:"] = "Latence locale :"
	L["Home latency %s:"] = "Latence locale %s :"
	L["(Chat, Auction House, etc)"] = "(Discussion, Hôtel des ventes, etc)"
	L["Display World Latency %s"] = "Afficher la latence mondiale"
	L["Display Home Latency %s"] = "Afficher la latence locale"
	L["Display Framerate"] = "Afficher les IPS"

	L["Incoming bandwidth:"] = "Bande passante entrante"
	L["Outgoing bandwidth:"] = "Bande passante sortante"
	L["KB/s"] = true
	L["<Left-Click for more>"] = "<Click gauche pour plus d'infos>"
	L["<Left-Click to toggle Friends pane>"] = "Click gauche pour afficher la fenêtre des amis>"
	L["<Left-Click to toggle Guild pane>"] = "<Click gauche pour afficher la fenêtre de guilde"
	L["<Left-Click to toggle Reputation pane>"] = "<Click gauche pour afficher la fenêtre des réputations>"
	L["<Left-Click to toggle Currency frame>"] = "<Click gauche pour afficher la fenêtre des devises>"
	L["%d%% of normal experience gained from monsters."] = "%d%% de l'expérience normale gagnée sur les monstres"
	L["You should rest at an Inn."] = "Vous devriez vous reposer à l'auberge"
	L["Hide copper when you have at least %s"] = "Masquer les pièces de cuivres quand vous avez au moins %s"
	L["Hide silver and copper when you have at least %s"] = "Masquer les pièces de cuivres et d'argent quand vous avez au moins %s"
	L["Invite a member to the Guild"] = "AJouter un membre à la guilde"
	L["Change the Guild Message Of The Day"] = "Changer le message du jour de la guilde"
	L["Select currencies to always watch:"] = "Choisir les devises à toujours afficher"
	L["Select how your gold is displayed:"] = "Choisir la façon dont votre or est affiché"
	
	L["No container equipped in slot %d"] = "Pas de conteneur équippé dans le slot %d"
end

-- Panels: menu
do
	L["Here you can change the settings and visibility of the various info panels and backdrops in the UI."] = "Içi vous pourrez changer les réglages et la visibilité de divers pannneaux d'informations et arrière-plans de l'UI" -- *v3
	L["UI Panels are special frames providing information about the game as well allowing you to easily change settings. Here you can configure the visibility and behavior of these panels. If you wish to change their position, you can unlock them for movement with |cFF4488FF/glock|r."] = "Les panneaux d'UI sont des cadres spéciaux fournissants diverses informations et permettant d'accèder rapidement à certains réglages. Içi vous pourrez changer leur visibilité et leur comportement. Si vous désirer changer leur emplacement, utilisez |cFF4488FF/glock|r"
	L["Visible Panels"] = "Panneaux visibles"
	L["Here you can decide which of the UI panels should be visible. They can still be moved with |cFF4488FF/glock|r when hidden."] = "Içi vous pourrez décider quels panneaux seront visibles. Ils peuvent toujours êtres déplacés avec |cFF4488FF/glock|r une fois masqués"
	L["Show the bottom right UI panel"] = "Afficher le panneau d'UI bas-droite"
	L["Show the bottom left UI panel"] = "Afficher le panneau d'UI bas-gauche"
	L["Bottom Right Panel"] = "Panneau bas-droite"
	L["Bottom Left Panel"] = "Panneau bas-gauche"
	L["Visible Backdrops"] = "Arrière-plans visibles" -- *v3
	L["Here you can decide which of the backdrops should be visible."] = "Içi vous pourrez choisir quels arrière-plans seront visibles" -- *v3
	L["Bottom Backdrop"] = "Arrière-plan du bas" -- *v3
	L["Bottom Left Backdrop"] = "Arrière-plan bas-gauche" -- *v3
	L["Bottom Right Backdrop"] = "Arrière-plan bas-droite" -- *v3
	L["Side Backdrop"] = "Arrière-plan latéral" -- *v3
end

-- Quest: menu
do
	L["QuestLog"] = "Journal de quête"
	L["These options allow you to customize how game objectives like Quests and Achievements are displayed in the user interface. If you wish to change the position of the ObjectivesTracker, you can unlock it for movement with |cFF4488FF/glock|r."] = "Ces options vous permettent de changer la façon dont les objectifs de quêtes ou de haut-faits sont affichés. Si vous désirez changer la position du suivi des objectifs, utlisez |cFF4488FF/glock|r"
	L["Display quest level in the QuestLog"] = "Afficher le niveau des quêtes"
	L["Objectives Tracker"] = "Suivi des objectifs"
	L["Autocollapse the WatchFrame"] = "Reduction automatique du suivi des quêtes"
	L["Autocollapse the WatchFrame when a boss unitframe is visible"] = "Réduction automatique en combat contre un boss"
	L["Automatically align the WatchFrame based on its current position"] = "Alignement automatique selon la position"
	L["Align the WatchFrame to the right"] = "Aligner vers la droite"
end

-- Tooltips
do
	L["Tooltip"] = "Info-bulle" -- *v3
	L["Here you can change the settings for the game tooltips"] = "Içi vous pourrez changer les réglages des info-bulles"
	L["Hide while engaged in combat"] = "Cacher en combat"
	L["Color unit tooltips borders and healthbars according to player class or NPC reaction"] = "Colorer les bordures d'info-bulles des unités selon la classe du joueur ou le comportement du NPC" -- *v3
	L["Show values on the tooltip healthbar"] = "Affcher les valeurs sur la barre de santé des info-bulles"
	L["Show player titles in the tooltip"] = "Afficher les titres des joueurs dans l'info-bulle"
	L["Show player realms in the tooltip"] = "Afficher le royaume des joueurs dans l'info-bulle"
	L["Positioning"] = "Positionnement"
	L["Choose what tooltips to anchor to the mouse cursor, instead of displaying in their default positions:"] = "Choisir quelles info-bulles ancrer au curseur de la souris, au lieu de les afficher à leurs emplacement d'origine"
	L["All tooltips will be displayed in their default positions."] = "Toutes les info-bulles seront affichés à leurs emplacement d'origine"
	L["All tooltips will be anchored to the mouse cursor."] = "Toutes les info-bulles seront ancrées au curseur de la souris"
	L["Only Units"] = "Seulement les unités"
	L["Only unit tooltips will be anchored to the mouse cursor, while other tooltips will be displayed in their default positions."] = "Seulement les info-bulles d'unités seront ancrées au curseur de la souris, les autres seront affichées à leurs emplacements d'origine"
end

-- worldmap and zonemap
do
	L["ZoneMap"] = "Carte de la zone" -- *v3
end

-- UnitFrames
do
	L["Due to entering combat at the worst possible time the UnitFrames were unable to complete the layout change.|nPlease reload the user interface with |cFF4488FF/rl|r to complete the operation!"] = "UnitFrames est incapable d'appliquer la disposition en combat. Recharger l'interface en utilsant |cFF4488FF/rl|r afin de terminer l'opération"
	L["Can't change the Set Focus key while engaged in combat!"] = "Impossible de changer la touche de définition du focus en combat!"
end

-- UnitFrames: oUF_Trinkets
do
	L["Trinket ready: "] = "Trinket prêt : "
	L["Trinket used: "] = "Trinket utilisé : "
	L["WotF used: "] = "WotF utilisé : "
end

-- UnitFrames: menu
do
	L["These options can be used to change the display and behavior of unit frames within the UI. If you wish to change their position, you can unlock them for movement with |cFF4488FF/glock|r."] = "Ces options peuvent être utilisées afin de changer l'apparence et le comportement des cadres d'unités dans l'UI. Si vous désirez changeur leur emplacement, utilisez |cFF4488FF/glock|r"

	L["Choose what unit frames to load"] = "Choisir les cadres d'unités à charger"
	L["Enable Party Frames"] = "Groupe"
	L["Enable Arena Frames"] = "Arène"
	L["Enable Boss Frames"] = "Boss"
	L["Enable Raid Frames"] = "Raid"
	L["Enable MainTank Frames"] = "Tank principal"
	L["Enable ClassBar"] = "Barre de classe"
	
	L["Set Focus"] = "Définir le focus"
	L["Here you can enable and define a mousebutton and optional modifier key to directly set a focus target from clicking on a frame."] = "Içi vous pourrez activer et définir un bouton de souris ainsi qu'une touche complémentaire pour définir un focus en cliquant sur un cadre"
	L["Enable Set Focus"] = "Activer la définition du focus"
	L["Enabling this will allow you to quickly set your focus target by clicking the key combination below while holding the mouse pointer over the selected frame."] = "Activer cela vous permettra de définir rapidement votre focus en utilisant la combinaison de touche ci-dessous tout en laissant le curseur de la souris au dessus du cadre d'unité concerné"
	L["Modifier Key"] = "Touche complémentaire"

	L["Enable indicators for HoTs, DoTs and missing buffs."] = "Activer les indications pour les HoTs, DoTs, et buffs manquants"
	L["This will display small squares on the party- and raidframes to indicate your active HoTs and missing buffs."] = "Affichera des petits carrés sur les cadres d'unités de groupe et raid pour indiquer vos HoTs actifs et vos buffs manquants"

	--L["Auras"] = true
	L["Here you can change the settings for the auras displayed on the player- and target frames."] = "Içi vous pourrez changer les réglages concernant les auras du joueur et des cibles"
	L["Filter the target auras in combat"] = "Filtrer les auras sur la cible en combat"
	L["This will filter out auras not relevant to your role from the target frame while engaged in combat, to make it easier to track your own debuffs."] = "N'affichera que les auras relatives à votre classe sur la cible en combat, afin de faciliter le suivi de vos debuffs sur elle"
	L["Desature target auras not cast by the player"] = "Aténuer les auras sur la cible n'appartenant pas au joueur"
	L["This will desaturate auras on the target frame not cast by you, to make it easier to track your own debuffs."] = "Attenuera les auras sur la cible ne provenant pas de vous, afin de faciliter le suivi de vos debuffs sur elle"	
	L["Texts"] = "Texte"
	L["Show values on the health bars"] = "Afficher les valeurs sur la barre de santé"
	L["Show values on the power bars"] = "Afficher les valeurs sur la barre de ressource"
	L["Show values on the Feral Druid mana bar (when below 100%)"] = "Afficher les valeurs sur la barre de mana du Druide (Quand < 100%)"
	L["Filter the player auras in combat"] = "Filtrer les auras du joueur en combat"
	L["This will filter out auras not relevant to your role from the player frame while engaged in combat, to make it easier to track your own auras."] = "N'affichera que les auras relatives à votre rôle sur le joueur en combat, afin d'en faciliter le suivi."
	
	L["Groups"] = "Groupe"
	L["Here you can change what kind of group frames are used for groups of different sizes."] = "Içi vous pourrez changer le type de cadre d'unité utilisé pour les différentes tailles de groupe"

	L["5 Player Party"] = "Groupe de 5 joueurs"
	L["Use the same frames for parties as for raid groups."] = "Utiliser les mêmes cadres d'unité qu'en raid à 10 joueurs"
	L["Enabling this will show the same types of unitframes for 5 player parties as you currently have chosen for 10 player raids."] = "Activera les mêmes cadres d'unités que pour les groupes de raid à 10 joueurs"
	
	L["10 Player Raid"] = "Raid à 10 joueurs"
	L["Use same raid frames as for 25 player raids."] = "Utiliser les mêmes cadres d'unité qu'en Raid à 25 joueurs"
	L["Enabling this will show the same types of unitframes for 10 player raids as you currently have chosen for 25 player raids."] = "Activera les mêmes cadres d'unité qu'en raid à 25 joueurs"

	L["25 Player Raid"] = "Raid à 25 joueurs"
	L["Automatically decide what frames to show based on your current specialization."] = "Choix automatique des cadres d'unités à afficher selon votre spécialisation de talents actuelle"
	L["Enabling this will display the Grid layout when you are a Healer, and the smaller DPS layout when you are a Tank or DPSer."] = "Utilisera la disposition en grille si vous êtes Soigneur, et la plus petite disposition si vous êtes DPS ou Tank"
	L["Use Healer/Grid layout."] = "Utiliser la disposition de Soigneur/en gille."
	L["Enabling this will use the Grid layout instead of the smaller DPS layout for raid groups."] = "Utilisera la disposition en grille au lieu de la plus petite utilisée pour les DPS et Tanks"
	
	L["Player"] = "Joueur"
	L["ClassBar"] = "Barre de classe"
	L["The ClassBar is a larger display of class related information like Holy Power, Runes, Eclipse and Combo Points. It is displayed close to the on-screen CastBar and is designed to more easily track your most important resources."] = "La barre de classe est une représantation plus visible de certaines ressources de classes telles que la puissance sacré, les runes, l'eclipse, ou les points de combo. Affichée prêt de la barre de cast à l'écran, elle est désignée afin de faciliter le suivi de ces ressources"
	L["Enable large movable classbar"] = "Activer la grande barre de classe déplacable"
	L["This will enable the large on-screen classbar"] = "Affichera la grande barre de classe à l'écran"
	L["Only in Combat"] = "Seulement en combat"
	L["Disable integrated classbar"] = "Désactiver la barre de classe intégrée"
	L["This will disable the integrated classbar in the player unitframe"] = "Désactivera la barre de classe intégrée dans le cadre d'unité du joueur"
	L["Show player auras"] = "Afficher les auras du joueur"
	L["This decides whether or not to show the auras next to the player frame"] = "Afficher ou non les auras à coté du cadre d'unité du joueur"
	
	L["Target"] = "Cible"
	L["Show target auras"] = "Afficher les auras sur la cible"
	L["This decides whether or not to show the auras next to the target frame"] = "Afficher ou non les auras sur la cible"
end

-- UnitFrames: Movable Frame Anchors
do
	L["Player"] = "Joueur" -- *v3
	L["Target"] = "Cible" -- *v3
	L["Pet"] = "Famillier" -- *v3
	L["Target of Target"] = "Cible de la cible" -- *v3
	L["Focus"] = "Focus" -- *v3
	L["Party"] = "Groupe" -- *v3
	L["15 Player Raid"] = "Raid 25 joueurs" -- *v3
	L["40 Player Raid Healer"] = "Raid 40 joueurs - Soigneur" -- *v3
	L["40 Player Raid DPS"] = "Raid 40 joueurs - DPS" -- *v3
	L["Arena"] = "Arène" -- *v3
	L["Boss"] = "Boss" -- *v3
	L["Player Class Bar"] = "Barre de classe du joueur" -- *v3
end

-- UnitFrames: GroupPanel
do
	-- party
	L["Show the player along with the Party Frames"] = "Afficher le joueur dans le groupe"
	L["Use Raid Frames instead of Party Frames"] = "Utiliser les cadres de raid"
	
	-- raid
	L["Use the grid layout for all Raid sizes"] = "Utiliser la disposition en grille pour toutes les tailles de raid"
	
	L["Group Structure"] = "Structure du groupe"
	L["Group Roles"] = "Rôles"
	L["World Markers"] = "Marqueurs"
	L["Raid Target Icon"] = "Icône de cible du raid"
end


--------------------------------------------------------------------------------------------------
--		FAQ
--------------------------------------------------------------------------------------------------
-- 	Even though most of these strings technically belong to their respective modules,
--		and not the FAQ interface, we still gather them all here for practical reasons.
do
	-- general
	L["FAQ"] = true
	L["Frequently Asked Questions"] = "Foire aux questions"
	L["Clear All Tags"] = true
	L["Show the current FAQ"] = true
	L["Return to the listing"] = true
	L["Go to the options menu"] = true
	L["Select categories from the list on the left. |nYou can choose multiple categories at once to narrow down your search.|n|nSelected categories will be displayed on top of the listing, |nand clicking them again will deselect them!"] = true
	
	-- 
	L["I wish to move something! How can I change frame positions?"] = true
	L["A lot of frames can be moved to custom positions. You can unlock them all for movement by typing |cFF4488FF/glock|r followed by the Enter key, and lock them with the same command. There are also multiple options available when right-clicking on the overlay of the movable frame."] = true

	-- actionbars
	L["How do I change the currently active Action Page?"] = true
	L["There are no on-screen buttons to do this, so you will have to use keybinds. You can set the relevant keybinds in the Blizzard keybinding interface."] = true
	L["How can I change the visible actionbars?"] = true
	L["You can toggle most actionbars by clicking the arrows located close to their corners. These arrows become visible when hovering over them with the mouse if you're not currently engaged in combat. You can also toggle the actionbars from the options menu, or by running the install tutorial by typing |cFF4488FF/install|r followed by the Enter key."] = true
	L["How do I toggle the MiniMenu?"] = true
	L["The MiniMenu can be displayed by typing |cFF4488FF/showmini|r followed by the Enter key, and |cFF4488FF/hidemini|r to hide it. You can also toggle it from the options menu or by running the install tutorial by typing |cFF4488FF/install|r."] = true
	L["How can I move the actionbars?"] = true
	L["Not all actionbars can be moved, as some are an integrated part of the UI layout. Most of the movable frames in the UI can be unlocked by typing |cFF4488FF/glock|r followed by the Enter key."] = true
	
	-- actionbuttons
	L["How can I toggle keybinds and macro names on the buttons?"] = true
	L["You can enable keybind display on the actionbuttons by typing |cFF4488FF/showhotkeys|r followed by the Enter key, and disable it with |cFF4488FF/hidehotkeys|r. Macro names can be toggled with the |cFF4488FF/shownames|r and |cFF4488FF/hidenames|r commands. All settings can also be changed in the options menu."] = true
	
	-- auras
	L["How can I change how my buffs and debuffs look?"] = true
	L["You can change a lot of settings like the time display and the cooldown spiral in the options menu."] = true
	L["Sometimes the weapon buffs don't display correctly!"] = true
	L["Correct. Sadly this is a bug in the tools Blizzard has given to us addon developers, and not something that is easily fixed. You'll simply have to live with it for now."] = true
	
	-- bags
	L["Sometimes when I choose to bypass a category, not all items are moved to the '%s' container, but some appear in others?"] = true
	L["Some items are put in the 'wrong' categories by Blizzard. Each category in the bag module has its own internal filter that puts these items in their category of they are deemed to belong there. If you bypass this category, the filter is also bypassed, and the item will show up in whatever category Blizzard originally put it in."] = true
	L["How can I change what categories and containers I see? I don't like the current layout!"] = true
	L["Categories can be quickly selected from the quickmenu available by clicking at the arrow next to the '%s' or '%s' containers."] = true
	L["You can change all the settings in the options menu as well as activate the 'all-in-one' layout easily!"] = true
	L["How can I disable the bags? I don't like them!"] = true
	L["All the modules can be enabled or disabled from within the options menu. You can locate the options menu from the button on the Game Menu, or by typing |cFF4488FF/gui|r followed by the Enter key."] = true
	L["I can't close my bags with the 'B' key!"] = true
	L["This is because you probably have bound the 'B' key to 'Open All Bags', which is a one way function. To have the 'B' key actually toggle the containers, you need to bind it to 'Toggle Backpack'. The UI can reassign the key for you automatically. Would you like to do so now?"] = true
	L["Let the 'B' key toggle my bags"] = true
	
	-- castbars
	L["Player Castbar"] = true -- *v3
	L["Target Castbar"] = true -- *v3
	L["Focus Castbar"] = true -- *v3
	L["Pet Castbar"] = true -- *v3
	L["How can I toggle the castbars for myself and my pet?"] = true
	L["The UI features movable on-screen castbars for you, your target, your pet, and your focus target. These bars can be positioned manually by typing |cFF4488FF/glock|r followed by the Enter key. |n|nYou can change their settings, size and visibility in the options menu."] = true
	
	-- minimap
	L["I can't find the Calendar!"] = true
	L["You can open the calendar by clicking the middle mouse button while hovering over the Minimap, or by assigning a keybind to it in the Blizzard keybinding interface avaiable from the GameMenu. The Calendar keybind is located far down the list, along with the GUIS keyinds."] = true
	L["Where can I see the current dungeon- or raid difficulty and size when I'm inside an instance?"] = true
	L["You can see the maximum size of your current group by hovering the cursor over the Minimap while being inside an instance. If you currently have activated Heroic mode, a skull will be visible next to the size display as well."] = true
	L["How can I move the Minimap?"] = true
	L["You can manually move the Minimap as well as many other frames by typing |cFF4488FF/glock|r followed by the Enter key."] = true
	
	-- quests
	L["How can I move the quest tracker?"] = true
	L["My actionbars cover the quest tracker!"] = true
	L["You can manually move the quest tracker as well as many other frames by typing |cFF4488FF/glock|r followed by the Enter key. If you wish the quest tracker to automatically move in relation to your actionbars, then reset its position to the default. |n|nWhen a frame is unlocked with the |cFF4488FF/glock|r command, you can right click on its overlay and select 'Reset' to return it to its default position. For some frames like the quest tracker, this will allow the UI to decide where it should be put."] = true
	
	-- talents
	L["I can't close the Talent Frame when pressing 'N'"] = true
	L["But you can still close it!|n|nYou can close it with the Escacpe key, or the closebutton located in he upper right corner of the Talent Frame.|n|nWhen closing the Talent Frame with the original keybind to toggle it, it becomes 'tainted'. This means that the game considers it to be 'insecure', and you won't be allowed to do actions like for example changing your glyphs. This only happens when closed with the hotkey, not when it's closed by the Escape key or the closebutton.|n|nBy reassigning your Talent Frame keybind to a function that only opens the frame, not toggles it, we have made sure that it gets closed the proper way, and you can continue to change your glyphs as intended."] = true
	
	-- tooltips
	L["How can I toggle the display of player realms and titles in the tooltips?"] = true
	L["You can change most of the tooltip settings from the options menu."] = true
	
	-- unitframes
	L["My party frames aren't showing!"] = true
	L["My raid frames aren't showing!"] = true
	L["You can set a lot of options for the party- and raidframes from within the options menu."] = true
	
	-- worldmap
	L["Why do the quest icons on the WorldMap disappear sometimes?"] = true
	L["Due to some problems with the default game interface, these icons must be hidden while being engaged in combat."] = true
end

--------------------------------------------------------------------------------------------------
--		Keybinds Menu (Blizzard)
--------------------------------------------------------------------------------------------------
do
	L["Toggle Calendar"] = "Afficher le calendrier"
	L["Whisper focus"] = "Chuchoter au focus"
	L["Whisper target"] = "Chuchoter à la cible"
end


--------------------------------------------------------------------------------------------------
--		Error Messages 
--------------------------------------------------------------------------------------------------
do
	L["Can't toggle Action Bars while engaged in combat!"] = "Impossible d'activer les barres d'actions en combat!"
	L["Can't change Action Bar layout while engaged in combat!"] = "Impossible de changer la disposition des barres d'actions en combat!"
	L["Frames cannot be moved while engaged in combat"] = "Impossible de déplacer les cadres en combat!"
	L["Hiding movable frame anchors due to combat"] = "Ancrage des cadres déplacables masqué à cause d'un combat"
	L["UnitFrames cannot be configured while engaged in combat"] = "Impossible de configurer les cadres d'unités en combat"
	L["Can't initialize bags while engaged in combat."] = "Impossible d'initialiser les sacs en combat"
	L["Please exit combat then re-open the bags!"] = "Veuillez cessez le combat et réouvrir les sacs!"
end


--------------------------------------------------------------------------------------------------
--		Core Messages
--------------------------------------------------------------------------------------------------
do
	L["Copy settings between characters"] = "Copie les réglages entre les personnages" -- *v3
	L["Save"] = "Sauvegarder" -- *v3
	L["Restore"] = "Restorer" -- *v3

	L["Goldpaw"] = "|cFFFF7D0AGoldpaw|r" -- my class colored name. no changes needed here.
	L["%s loaded and ready"] = "%s : Chargé et prêt" -- *v3
	L["|cFF4488FF/glock|r to activate config mode"] = "|cFF4488FF/glock|r : Configuration" -- *v3
	L["|cFF4488FF/bind|r to activate binding mode"] = "|cFF4488FF/bind|r : Attibution des raccourcis" -- *v3
	L["|cFF4488FF/gui|r for additional options"] = "|cFF4488FF/gui|r : Options supplémentaires" -- *v3

	-- options menu
	L["The user interface needs to be reloaded for the changes to take effect. Do you wish to reload it now?"] = "L'UI à besoin d'être rechargée pour que les changements prennent effet. Le faire maintenant ?"
	L["You can reload the user interface at any time with |cFF4488FF/rl|r or |cFF4488FF/reload|r"] = "Vous pouvez recharger l'interface à tout moment avec |cFF4488FF/rl|r ou |cFF4488FF/reload|r"
	L["Can not apply default settings while engaged in combat."] = "impossible d'appliquer les réglages par défaut en combat"
	
	-- keybind stuff
	L["Show Talent Pane"] = "Afficher la fenêtre de talents"
	L["Reload the user interface"] = "Recharger l'UI" -- *v3
	L["Blizzard Customer Support"] = "Service clientèle Blizzard" -- *v3
	L["Toggle movable frames"] = "Activer les cadres déplacables" -- *v3
	L["Toggle hover keybind mode"] = "Activer le mode d'attribution des raccourcis au vol" -- *v3
	L["Additional Keybinds"] = "Raccourcis supplémentaires" -- *v3
	L["TSM Post/Cancel"] = "Retarder/annuler TSM" -- *v3

	-- chat commands
	L["Activating Primary Specialization"] = "Activation de la spécialisation principale" -- *v3
	L["Activating Secondary Specialization"] = "Activation de la spécialisation secondaire" -- *v3
	L["%s has been temporarily disabled. Type /enablegui to enable it."] = "%s est désactivé temporairement, tappez /enablegui pour l'activer" -- *v3
	
	-- frame groups (objects movable with /glock)
	L["Unitframes"] = "Cadres d'unités" -- *v3
	L["Frames like the player, target, raid, focus, pet etc"] = "Cadres du joueur, de la cible, du raid, du focus, etc" -- *v3
	L["Actionbars"] = "Barres d'actions" -- *v3
	L["Frames containing shortcut buttons to abilities, macros etc"] = "Cadre des boutons de raccourcis, macros, etc" -- *v3
	L["Panels"] = "Panneaux" -- *v3
	L["Various UI panels providing information, |rincluding the minimap and bottom left and right infopanels"] = true -- *v3
	L["Floaters"] = true -- *v3
	L["Various uncategorized elements like the objective tracker, |rthe durability frame, the vehicle seat indicator etc"] = "Divers éléments tels que le suivi des objectifs, |rla durabilté des objets, le siège du véhicule" -- *v3
	L["Auras"] = true -- *v3
	L["Your buffs and debuffs"] = "Vos buffs et debuffs" -- *v3
	L["Castbars"] = "Barres de sort" -- *v3
	L["Unit castbars, mirror timers, BG timers, etc"] = "Barre de sorts des unités, timers, etc" -- *v3
	
	-- floaters (various movable frame names)
	L["Vehicle"] = "Véhicule" -- *v3
	L["Objectives"] = "Objectifs" -- *v3
	L["Alternate Power"] = "Ressource alternative" -- *v3
	L["Tickets"] = true -- *v3
	L["Durability"] = "Durabilité" -- *v3
	L["Ghost"] = "Fantôme" -- *v3
	L["WorldStateScore"] = "Score du monde" -- *v3
	L["ExtraActionButton"] = "Bouton d'action spéciale" -- *v3
	L["Achievement and Dungeon Alert Frame"] = "Cadre d'alerte de donjon et de haut-faits" -- *v3
	
	-- auto disable
	L["The '%s' module was disabled due to the addon '%s' being loaded."] = "Le module %s a été désactivé suite au chargement de l'add-on %s" -- *v3
	
	-- skin names and descriptions
	L["Skins"] = true -- *v3
	L["Skins the '%s' addon"] = "Habille l'add-on %s" -- *v3
	L["Here you can decide which elements should be skinned to match the rest of the UI, and which should keep their default appearance."] = "Içi vous pourrez décider des add-ons à habiller pour correspondre à l'UI, et de ceux qui conserveront leur aspect par défaut" -- *v3
	L["Debug Tools"] = "Outils de debugging" -- *v3
	L["Debug tools such as the /framestack or /eventtrace frames"] = "Outils de debugging tels que les cadres de /framestack ou /eventtrace" -- *v3
	L["MovePad"] = "Pavé de déplacement" -- *v3
	L["The movepad which allows you to move and jump with your mouse"] = "Vous permet de vous déplacer et de sauter avec la souris" -- *v3
	L["Alert Frames"] = "Alertes" -- *v3
	L["General alerts such as new achievements, dungeons completed, etc"] = "Alertes générales telles que les haut-faits, les donjons terminés, etc" -- *v3
	L["Color Picker"] = "Choix de la couleur" -- *v3
	L["The color wheel"] = "La roue de choix de couleur" -- *v3
	L["GameMenu"] = "Menu du jeu" -- *v3
	L["The main game menu"] = "Le menu principal du jeu" -- *v3
	L["Ghost"] = "Fantôme" -- *v3
	L["The button returning you to a graveyard as a ghost"] = "Le bouton vous renvoyant au cimetière en fantôme" -- *v3
	L["Quest Gossip"] = "Discussion générales" -- *v3
	L["General gossip when talking to quest givers"] = "Discussions générales avec les donneurs de quêtes" -- *v3
	L["Merchant"] = "Marchands" -- *v3
	L["The buy/sell window when talking to merchants"] = "La fenêtre d'achat(s)/vente(s) des marchands" -- *v3
	L["Opacity"] = "Opacité" -- *v3
	L["The opacity selector"] = "Le selecteur d'opacité" -- *v3
	L["Quest Log"] = "Journal de quête" -- *v3
	L["Main quest log"] = "Le journal de quêtes" -- *v3
	L["Quest Greeting"] = "Acceuil de quête" -- *v3
	L["The greeting window when talking to quest givers"] = "La fenêtre d'acceuil en parlant aux donneurs de quêtes" -- *v3
	L["Ready Check"] = "Appel" -- *v3
	L["The ready check popup when in a group"] = "Le pop-up d'appel en groupe" -- *v3
	L["Roll Poll"] = "Vérification de rôle" -- *v3
	L["The roll poll popup when in a group"] = "Le pop-up de vérification de rôle en groupe" -- *v3
	L["Stack Split"] = "Séparation des piles" -- *v3
	L["The stack split frame when splitting stacks in your bank or bags"] = "La fenêtre de séparation des piles d'objets dans vos sacs" -- *v3
	L["Popups"] = true -- *v3
	L["The popup windows with yes/no or other queries"] = "Pop-up de choix (oui/non)" -- *v3
	L["Taxi"] = "Maitre de vol" -- *v3
	L["The flight map when talking to flight masters"] = "La carte de trajet des maitres de vol" -- *v3
	L["Ticket Status"] = "Status du/des ticket(s)" -- *v3
	L["The ticket status button for active support tickets"] = "La fenêtre de status de vos tickets en cours" -- *v3
	L["Objectives Tracker"] = "Suivi des objectifs" -- *v3
	L["The quest- and achievement tracker"] = "La fenêtre de suivi des objectifs de quête/haut-faits" -- *v3
	L["World Score"] = "Score du monde" -- *v3
	L["The on-screen score (battlegrounds, dungeon waves, world PvP objectives etc)"] = "Les divers scores affichés (champ de bataille, vagues de monstres en donjon, objectifs JcJ mondiaux, etc" -- *v3
	L["Battleground Score"] = "Score du champ de bataille" -- *v3
	L["The Battleground score frame"] = "Fenêtre de score du champ de bataille" -- *v3
	L["Achievements"] = "Haut-faits" -- *v3
	L["The achievement- and statistic frames"] = "Cadres de haut-faits et statistiques" -- *v3
	L["Archeology"] = "Archéologie" -- *v3
	L["The Archeology UI"] = "L'UI d'archéologie" -- *v3
	L["Auction House"] = "Hôtel des ventes" -- *v3
	L["The Auction House Interface"] = "L'UI de l'hôtel des ventes" -- *v3
	L["Barber Shop"] = "Coiffeur" -- *v3
	L["The Barber Shop Interface, where you change your hair, facial hair and markings."] = "La fenêtre du coiffeur" -- *v3
	L["Mailbox"] = "Boite aux lettres" -- *v3
	L["Your Mail Inbox and Send Mail windows."] = "Fenêtre d'envoi et de reception du courrier" -- *v3
	L["Character"] = "Personnage" -- *v3
	L["The window where you see your currently equipped gear, set your title and manage your equipment sets."] = "La fenêtre avec votre équipement, vos titres, et ensembles d'équipements" -- *v3
	L["Guild Bank"] = "Banque de guilde" -- *v3
	L["The Guild Bank window with your guild's gold and items."] = "La fenêtre de la banque de guilde" -- *v3
	L["Calendar"] = "Calendrier" -- *v3
	L["The in-game calendar"] = "Le calendrier en jeu" -- *v3
	L["Dressing Room"] = "Fenêtre d'essayage" -- *v3
	L["The dressing room where your character can try on other gear and weapons."] = "La fenêtre d'essayage des armes et équipements" -- *v3
	L["Autocomplete"] = "Auto-complétion" -- *v3
	L["The autocomplete box that pops up when you send mail, invite people to a group etc."] = "La fenêtre d'auto-complétion pour les envois de courrier, les invitations de groupe, etc" -- *v3
	L["TradeSkill"] = "Métiers" -- *v3
	L["The tradeskill windows where you craft items."] = "La fenêtre des métiers" -- *v3
	L["ItemText"] = "Texte des objets" -- *v3
	L["The itemtext frame for books, signs, etc."] = "La fenêtre de texte des livres, panneaux, etc" -- *v3
	L["Trade"] = "Echange" -- *v3
	L["The trade window when trading with another player."] = "La fenêtre d'échange" -- *v3
	L["Void Storage UI"] = "Chambre du vide" -- *v3
	L["The Void Storage interface"] = "L'interface de la chambre du vide" -- *v3
	L["Tutorials"] = "Tutoriels" -- *v3
	L["The game tutorials for new players"] = "Les tutoriels pour nouveaux joueurs" -- *v3
	L["Transmogrification UI"] = true -- *v3
	L["The item transmogrification window where you style your items to look like other items"] = "La fenêtre de transmogrification des objets" -- *v3
	L["Trainers"] = "Entraineurs" -- *v3
	L["The trainer interface where you learn new skills and abilities from"] = "La fenêtre d'apprentissage des talents et metiers" -- *v3
	L["Tabard UI"] = true -- *v3
	L["The tabard designer interface"] = "La fenêtre de design des tabards" -- *v3
	L["Socketing UI"] = "Sertissage" -- *v3
	L["The item socketing UI where you add or remove gems from your gear"] = "Fenêtre de sertissage des objets" -- *v3
	L["Reforging UI"] = "Reforge" -- *v3
	L["The reforging UI where you redistribute secondary stats on your gear"] = "Fenêtre de reforge" -- *v3
	L["PvP"] = "JcJ" -- *v3
	L["The PvP window where you queue up for Battlegrounds and Arenas, and manage your teams"] = "La fenêtre de gestion des champs de bataille et arène, et de vos équipes" -- *v3
	L["Petitions"] = true -- *v3
	L["Petition request such as Guild- and Arena charters"] = "Les chartes de guilde et arène"-- *v3
	L["Macro UI"] = true -- *v3
	L["The window where you manage your macros"] = "La fenêtre de gestion des macros" -- *v3
	L["Dungeon Journal"] = "Codex des donjons" -- *v3
	L["Instance descriptions, boss abilities and loot tables"] = "Description des instances, des capacités des boss, et tables de butin" -- *v3
	L["Dungeon Finder"] = "Recherche de donjon" -- *v3
	L["Where you browse available dungeons, raids, scenarios and challenges"] = "Fenêtre de recherche de donjons, raids, scénarios et défis" -- *v3
	L["Friends"] = "Amis" -- *v3
	L["The friends frame"] = "La fenêtre des amis" -- *v3
	L["Guild UI"] = true -- *v3
	L["The main guild interface"] = "L'interface principale de guilde" -- *v3
	L["Guild Control UI"] = "Interface de gestion de guilde" -- *v3
	L["The window where you create, modify and delete the guild ranks and their permissions"] = "La fenêtre de gestion des rangs de guilde et des permissions" -- *v3
	L["Guild Finder UI"] = "Recherche de guilde" -- *v3
	L["The window where you browser for guilds"] = "La fenêtre de recherche de guilde" -- *v3
	L["Guild Registrar"] = "Enregistrement de guilde" -- *v3
	L["The guild registrar interface where you buy petitions and create new guilds"] = "La fenêtre d'enregistrement et de création de guilde" -- *v3
	L["Guild Invite"] = "Invitation de guilde" -- *v3
	L["The guild invite frame where you accept or decline a guild invitation"] = "La fenêtre d'acceptation ou de refus des invitations de guilde" -- *v3
	L["Inspect UI"] = "Inspection" -- *v3
	L["The window where you inspect another player's gear, talents and PvP teams"] = "La fenêtre d'inspection des autres joueurs" -- *v3
	L["Black Market UI"] = "Marché noir" -- *v3
	L["The black market interface"] = "L'interface du marché noir" -- *v3
	L["Item Upgrade UI"] = "Amélioration des objets" -- *v3
	L["The window where you upgrade the item level of your gear"] = "La fenêtre d'amélioration de vos objets" -- *v3
end

-- menu
do
	L["Copy settings from another character"] = "Copier les réglages à partir d'un autre personnage"
	L["This will copy all settings for the addon and all its sub-modules from the selected character to your currently active character"] = "Permet de copier tous les réglages de l'UI et de ses modules, d'un personnage vers le personnage actif"
	L["This will only copy the settings for this specific sub-module from the selected character to your currently active character"] = "Permet de copier uniquement les réglages du module, d'un personnage vers le personnage actif"
	L["UI Scale"] = "Echelle de l'UI"
	L["Use UI Scale"] = "Utiliser la mise à l'echelle de l'UI"
	L["Check to use the UI Scale Slider, uncheck to use the system default scale."] = "Cocher pour utiliser la mise à l'echelle de l'UI, décocher pour utiliser l'echelle par défaut"
	L["Changes the size of the game’s user interface."] = "Change la taille de l'UI"
	L["Using custom UI scaling is not recommended. It will produce fuzzy borders and incorrectly sized objects."] = "Utiliser une echelle personnalisée n'est pas recommandé. Cela deformera les bordures et faussera la taille des objets"
	L["Apply the new UI scale."] = "Appliquer la nouvelle echelle"
	L["Global Styles"] = "Style global" -- *v3
	L["Backdrop Opacity"] = "Transparence des arrière-plans" -- *v3
	L["Set the level of transparency for all backdrops"] = "Défini le niveau de transparence de tous les arrière-plans" -- *v3
	L["Load Module"] = "Charger le module"
	L["Module Selection"] = "Choix des modules"
	L["Choose which modules that should be loaded"] = "Choisir quel(s) module(s) charger"
	L["Never load this module"] = "Ne jamais charger ce module"
	L["Load this module unless an addon with similar functionality is detected"] = "Charger ce module, sauf si un add-on à fonction équivalente est detecté"
	L["Settings"] = "Paramètres" -- *v3
	L["Adjust the settings for this module"] = "Réglage des paramétres de ce module" -- *v3
	L["(In Development)"] = "(En développement)"
end

-- install tutorial
do
	-- general install tutorial messages
	L["Skip forward to the next step in the tutorial."] = "Sauter à l'étape suivante du tutorial"
	L["Previous"] = "Précédent"
	L["Go backwards to the previous step in the tutorial."] = "Retour à l'étape précédente du tutorial"
	L["Skip this step"] = "Sauter cette étape"
	L["Apply the currently selected settings"] = "Appliquer les réglages sélectionnés"
	L["Procede with this step of the install tutorial."] = "terminer cette étape du tutorial"
	L["Cancel the install tutorial."] = "Annuler le tutorial"
	L["Setup aborted. Type |cFF4488FF/install|r to restart the tutorial."] = "Installation annulée. Tapper |cFF4488FF/install|r pour la relancer."
	L["Setup aborted because of combat. Type |cFF4488FF/install|r to restart the tutorial."] = "Installation annulée à cause d'un combat. Tapper |cFF4488FF/install|r pour la relancer"
	L["This is recommended!"] = "Recommandé!"

	-- core module's install tutorial
	L["This is the first time you're running %s on this character. Would you like to run the install tutorial now?"] = "C'est la première fois que %s se lance sur ce personnage, voulez-vous lancer le tutorial d'installation?"
	L["Using custom UI scaling will distort graphics, create fuzzy borders, and otherwise ruin frame proportions and positions. It is adviced to always leave this off, as it will seriously affect the entire layout of the UI in unpredictable ways."] = true
	L["UI scaling is currently activated. Do you wish to disable this?"] = "La mise à l'echelle de l'UI est activée, voulez-vous la désactiver?"
	L["|cFFFF0000UI scaling is currently deactivated, which is the recommended setting, so we are skipping this step.|r"] = "|cFFFF0000 La mise à l'echelle de l'UI est désactivée, ce qui est le réglage recommandé, nous sautons donc cette étape|r"
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
	L["Mouse Button"] = "Bouton de la souris"

	L["Always"] = "Toujours"
	L["Apply"] = "Appliquer"
	L["Bags"] = "Sacs"
	L["Bank"] = "Banque" 
	L["Bottom"] = "Bas"
	L["Cancel"] = "Annuler"
	L["Categories"] = "Catégories"
	L["Close"] = "Fermer"
	L["Continue"] = "Continuer"
	L["Copy"] = "Copier" -- to copy. the verb.
	L["Default"] = "Défaut"
	L["Elements"] = "Eléments" -- like elements in a frame, not as in fire, ice etc
	L["Free"] = "Libre" -- free space in bags and bank
	L["General"] = "Général" -- general as in general info
	L["Ghost"] = "Fantôme" -- when you are dead and have released your spirit
	L["Hide"] = "Cacher" -- to hide something. not hide as in "thick hide".
	L["Lock"] = "Vérrouiller" -- to lock something, like a frame. the verb.
	L["Main"] = "Principal" -- used for Main chat frame, Main bag, etc
	L["Next"] = "Suivant"
	L["Never"] = "Jamais"
	L["No"] = "Non"
	L["Okay"] = true
	L["Open"] = "Ouvrir"
	L["Paste"] = "Coller" -- as in copy & paste. the verb.
	L["Reset"] = "Remise à zéro"
	L["Rested"] = "Reposé" -- when you are rested, and will recieve 200% xp from kills
	L["Scroll"] = "Parchemin" -- "Scroll" as in "Scroll of Enchant". The noun, not the verb.
	L["Show"] = "Montrer"
	L["Skip"] = "Passer"
	L["Top"] = "Haut"
	L["Total"] = true
	L["Visibility"] = "Visibilité"
	L["Yes"] = "Oui"

	L["Requires the UI to be reloaded!"] = "Nécessite le re-chargement de l'UI"
	L["Changing this setting requires the UI to be reloaded in order to complete."] = "Nécessaire de recharger l'UI complètement pour changer ce réglage"
	L["Changing these settings requires the UI to be reloaded in order to complete."] = "Nécessaire de recharger l'UI complètement pour changer ces réglages" -- *v3
end

-- gFrameHandler (/glock)
do
	L["<Left-Click and drag to move the frame>"] = "<Click gauche maintenu pour déplacer le cadre>"
	L["<Left-Click+Shift to lock into position>"] = "<Click gauche+shift pour vérouiller>"
	-- L["<Right-Click for options>"] = "<Click droit pour les options>" 
	-- L["Lock"] = "Vérrouiller"
	L["Center horizontally"] = "Centrer horizontalement"
	L["Center vertically"] = "Centrer verticalement"
	L["Cancel current position changes"] = "Annuler les changements d'emplacements en cours" -- *v3
	L["Reset to default position"] = "Position par défaut" -- *v3
	L["<Left-Click to toggle this category>"] = "<Click gauche pour afficher/masquer cette catégorie>" -- *v3
	L["<Shift-Click to reset all frames in this category>"] = "<Shift-click pour remettre à zero tous les cadres de cette catégorie>" -- *v3
	L["The frame '%s' is now locked"] = "Le cadre '%s' est vérrouillé" -- *v3
	L["The group '%s' is now locked"] = "Le groupe '%s' est vérrouillé" -- *v3
	L["All frames '%s' are now locked"] = "Tous les cadres de '%s' sont vérrouillés" -- *v3
	L["The frame '%s' is now unlocked"] = "Le cadre '%s' est dévérrouillé" -- *v3
	L["The group '%s' is now unlocked"] = "Le groupe '%s' est dévérouillé" -- *v3
	L["All frames are now unlocked"] = "Tous les cadres sont dévérrouillés" -- *v3
	L["All frames are now locked"] = "Tous les cadres sont vérrouillés" -- *v3
	L["No registered frames to unlock"] = "Aucun cadre à dévérouiller" -- *v3
	L["The group '%s' is empty"] = "Le groupe '%s' est vide" -- *v3
	L["Configuration Mode"] = "Mode configuration" -- *v3
	L["Frames are now unlocked for movement."] = "Les cadres sont maintenant déplacables" -- *v3
	L["<Left-Click once to raise a frame to the front>"] = "<Un click gauche met le cadre au premier plan>" -- *v3
	L["<Left-Click and drag to move a frame>"] = "<CLick gauche maintenu pour déplacer un cadre>" -- *v3
	L["<Left-Click+Shift to lock a frame into position>"] = "<Click gauche+Shift pour vérrouiller l'emplacement dun cadre>" -- *v3
	L["<Right-Click a frame for additional options>"] = "<Click droit pour plus d'options>" -- *v3
	L["Reset all frames to their default positions"] = "Remise à zéro de l'emplacement de tous les cadres" -- *v3
	L["Cancel all current position changes"] = "Annule tous les changements d'emplacement en cours" -- *v3
	L["Lock all frames"] = "Vérrouiller tous les cadres" -- *v3
end

-- visible module names
do
	L["ActionBars"] = "Barres d'actions"
	L["ActionButtons"] = "Boutons d'actions"
	L["Auras"] = true
	L["Bags"] = "Sacs"
	L["Buffs & Debuffs"] = true
	L["Castbars"] = "Barres des sorts" 
	L["Core"] = "Noyeau"
	L["Chat"] = "Discussion"
	L["Combat"] = true
	L["CombatLog"] = "Log du combat"
	L["CombatLogs"] = "Logs des combats" -- *v3
	L["Developer Tools"] = "Outils pour développeurs" -- *v3
	L["Errors"] = "Erreurs"
	L["Fonts"] = "Police" -- *v3
	L["Loot"] = true
	L["Map"] = "Carte" -- *v3
	L["Merchants"] = "Marchands"
	L["Minimap"] = "Mini-carte"
	L["Nameplates"] = "Plaques d'identification"
	L["Panels & Backdrops"] = "Panneaux et arrière-plans" -- *v3
	L["Quests"] = "Quêtes"
	L["Timers"] = true
	L["Tooltips"] = "Info-bulles"
	L["UI Panels"] = "Panneaux de l'UI"
	L["UI Skinning"] = "Habillement de l'UI"
	L["UnitFrames"] = "Cadres d'unités"
		L["PartyFrames"] = "Groupe"
		L["ArenaFrames"] = "Arène"
		L["BossFrames"] = "Boss"
		L["RaidFrames"] = "Raid"
		L["MainTankFrames"] = "Tank principal"
	L["World Status"] = "Etat du Monde"
end

-- various stuff used in the install tutorial's intro screen
do
	L["Credits to: "] = "Crédits :"
	L["Web: "] = true
	L["Download: "] = true
	L["Twitter: "] = true
	L["Facebook: "] = true
	L["YouTube: "] = true
	L["Contact: "] = true 

	L["_ui_description_"] = "%s est une interface d'utilisateur (UI) conçue pour remplacer l'interface par défaut de Blizzard. Une résolution minimale jusqu'a 1280 pixels de large est supportée, mais un minimum de 1440 pixels de large est conseillé. |n|nCette UI est écrite et maintenue par Lars Norberg, jouant le druide féral %s sur le royaume PvE EU de Draenor, du coté alliance"
	L["_install_guide_"] = "En quelques étapes vous serez guidés à travers le processus d'installation des quelques modules de cette interface d'utilisateur. Vous pourrez toujours changer ces options plus tard grace au menu d'options en jeu, ou avec la commande|cFF4488FF/gui|r."
	
	L["_ui_credited_"] = "Banz Lin et quelques autres(zhCN, zhTW), UnoPrata(ptBR, ptPT), Zork (pour ses tutorials et mes messages exceptionnels @ WoWInterface) et Kkthnxbye(compatibilité et tests)"

	L["_ui_copyright_"] = "Copyright (c) 2013, Lars '%s' Norberg. Tous droits réservés"
end
