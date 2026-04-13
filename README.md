# Morph Helper
![screenshot](https://i.imgur.com/tgfTBiu.png)
Assists in using the morph lua commands provided by VanillaHelpers.
Slash commands, and morph window avaiable. Type /mh show to display the window or /mh to learn more.
Has creature and race morph lists for Vanilla, Wallcraft, and Turtle WoW. However, Mount list is only for vanilla.

*NOTE*: Requires [VanillaHelpers](https://github.com/isfir/VanillaHelpers) be sure to installed first.

Supports [WoWInit](https://github.com/tubtubs/wowinit), includes examples commands. Great for setting morphs up on login.

![WoWInitscreenshot](https://i.imgur.com/KDg8bIC.png)

## Installation:
1. Click the Code button to the upper right hand corner and select download or click [here](https://github.com/tubtubs/MorphHelper/archive/refs/heads/master.zip).
2. Unzip the download into your Interface/Addons folder in your WoW directory. Eg: *C:\Games\WoW\Interface\Addons*
3. Rename the folder from *MorphHelper-master* to *MorphHelper*
4. Restart WoW and enable the addon from the character selection screen. Ensure your addon memory cap is set to 0 (no limit) as well.

You can also use the [GitAddonsManager](https://gitlab.com/woblight/GitAddonsManager) to install this addon.

-If there are any further issues with installation, ensure that *MorphHelper.toc* is in the root folder. There should be no subdirectories. Eg: *C:\Games\WoW\Interface\Addons\MorphHelper\MorphHelper.toc*

## Commands:
* /MorphHelper /Morph /MH.
* /MH show - Shows the morph helper window.
* /MH resetWindow - Resets the morph helper window position (center screen).
* /MH resetAll - Resets all morphs, won't undo swaps
* /MH listPresets - Lists saved presets, and their index.
* /MH applyPreset presetIndex  - Applies a preset, at specified index.
* /MH morph unitToken displayID - Morphs unit to a displayID.
* /MH morphMount unitToken displayID - Morphs unit's mount to a displayID.
* /MH FPMorph displayID - On taxis morph mount to displayID. Set to -1 to disable.
* /MH remap oldDisplayID displayID - Swap a unit displayID for a new one.
* /MH remapMount oldDisplayID displayID - Swap a mount displayID.
* /MH remapItem itemID inventoryslot itemID - Morphs a itemID at a slot.
* /MH morphUnitItem unitToken inventorySlot itemID - Morphs a unit's item.
* /MH getUnit unitToken - Displays a unit's display info in chat.
* /MH getItem itemID - Displays an item's display info in chat.
* /run MH_MountItem("ItemName","BuffName",displayID)
* /run MH_MountSpell("SpellName","BuffName",displayID)

## Known Issues:
Preset indexs can be messy if you delete them
* Already planning on reworking this system

Can't morph *x* NPC

* Many limitations imposed by VanillaHelpers calls. Companions, pets, and odd factions (enemy or neutral) don't morph well with VanillaHelpers.

Can't morph *x* item

* I'm still testing out item morphing viability. 
* Limited functionality, ItemIDs must be cached so something you can link from Atlasloot.

T-Posing during FlightPaths, no Gryphons

* If you morph your mount at all, then flight paths are likely to break. Use /mh FPMorph to set a displayID to fly on regularly.
* I recommend `/mh FPMorph 15293`, for the chromatic mount.