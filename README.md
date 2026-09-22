# Morph Helper
![screenshot](https://i.imgur.com/tgfTBiu.png)
Assists in using the morph lua commands provided by VanillaHelpers.
Slash commands, and morph window available. Type /mh show to display the window or /mh to learn more.
Has creature and race morph lists for Vanilla, Wallcraft, and Turtle WoW. However, Mount list is only for vanilla.
*V1.60* Now supports syncing morphs between party/raid members, improved UI, expanded mount/fp support
Supports [WoWInit](https://github.com/tubtubs/wowinit), includes examples commands. Great for setting morphs up on login.

![WoWInitscreenshot](https://i.imgur.com/KDg8bIC.png)

## Client Mods
*v1.60+ REQUIRES THESE CLIENT MODS:* 
* [VanillaHelpers](https://github.com/isfir/VanillaHelpers)
* [Nampower](https://github.com/brues-code/nampower) (events)
* [UnitXP_SP3](https://codeberg.org/konaka/UnitXP_SP3) (timers)
* [ClassicAPI](https://github.com/brues-code/ClassicAPI) (Spell info queries)



## Installation:
0. Install the client mods listed above
1. Click the Code button to the upper right hand corner and select download or click [here](https://github.com/tubtubs/MorphHelper/archive/refs/heads/master.zip).
2. Unzip the download into your Interface/Addons folder in your WoW directory. Eg: *C:\Games\WoW\Interface\Addons*
    - Should have all 5 folders, MorphHelper, MorphHelper_Vanilla, MorphHelper_Turtle, MorphHelper_Wallcraft, MorphHelper_Mounts
3. Restart WoW and enable the main addon (MorphHelper) from the character selection screen. Ensure your addon memory cap is set to a higher number or 0 (no limit) as well. 
    - The other addons for displays lists (MorphHelper_X will be automatically loaded and enabled as needed on init)

You can also use the [GitAddonsManager](https://gitlab.com/woblight/GitAddonsManager) to install this addon.

-If there are any further issues with installation, ensure that *MorphHelper.toc* is in the root folder. There should be no subdirectories. Eg: *C:\Games\WoW\Interface\Addons\MorphHelper\MorphHelper.toc*

## Commands:
* /MorphHelper /Morph /MH.
* /MH show - Shows the morph helper window.
* /MH minimap {show/hide} - Show or hide the minimap button. 
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

## Known Issues:
* Performance
    - Reduced memory usage by moving display lists to seperate on demand loaded addons
    - Improved mount support listens for buff changes, it may cause lag in raids or populated areas

* Addon Messages don't share item morphs
    - Item morphs are still WIP, barely supported

* Can't morph *x* NPC
    - Many limitations imposed by VanillaHelpers calls. Companions, pets, and odd factions (enemy or neutral) don't morph well with VanillaHelpers.

* Can't morph *x* item
    - I'm still testing out item morphing viability. 
    - Limited functionality, ItemIDs must be cached so something you can link from Atlasloot for example would work.

* T-Posing during FlightPaths, mount not displaying on use
    - If you morph your mount, and then unmorph your mount future mounts might not display
        - Should be addressed with v1.60, but fix requires client mods
    - If you morph your mount at all, then flight paths are likely to break. Use /mh FPMorph to set a displayID to fly on regularly.
    - I recommend `/mh FPMorph 15293`, for the chromatic mount.

* My factions are all messed up? I can't talk to friendly NPCs, they're red now?
    - Morphing as a different race causes your faction to change internally, possibly so customizations show up properly
        * Avoid morphing as the opposing faction, try morphing as a displayID for an NPC instead of the race for example
    - Morphing might mess up your reputation standing. For example, becoming hated with alliance as an alliance player. Need to investigate more.

## Changelog
* V1.60
    - Sync morphs between party members with addon messages
        - uses client mods to resolve GUIDs to client side unit tokens
    - Improved mount/flight path morphs
        - Removed janky /run methods
        - Added button for FP morphs to UI
        - Uses client mods for improved support by watching buffs
    - Dynamic UI for parties updated
        - Supports raids w/ scrollbar
        - Displays party member names now
