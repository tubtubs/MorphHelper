-- addon info
MH_NAME		= "MorphHelper";
MH_VERSION		= "1.0";

MH_NAMEVERSION	= MH_NAME.." v"..MH_VERSION;

-- slashcommands
SLASH_MORPHHELPER1 = '/MorphHelper'
SLASH_MORPHHELPER2 = '/Morph'
SLASH_MORPHHELPER3 = '/MH'
MH_OPT1 = "morph"
MH_OPT2 = "morphMount"
MH_OPT3 = "remapDisplayID"
MH_OPT4 = "remapMountDisplayID"
MH_OPT5 = "remapItemDisplayID"
MH_OPT6 = "getUnitDisplay"
MH_OPT7 = "getItemDisplay"
MH_OPT8 = "morphUnitItem"
MH_SLASHHELP0 = "|cFF00FF00" .. MH_NAME .. ":|r This is the help topic for |cFFFFFF00".. SLASH_MORPHHELPER1 .. " " ..
                    SLASH_MORPHHELPER2  .. SLASH_MORPHHELPER3 .. " .|r\n"
MH_SLASHHELP1 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT1 ..
"|cFF00FF00 unitToken displayID|r - Morphs unit to a displayID.\n"
MH_SLASHHELP2 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT2 ..
"|cFF00FF00 unitToken displayID|r - Morphs unit's mount to a displayID.\n"
MH_SLASHHELP3 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT3 ..
"|cFF00FF00 oldDisplayID displayID|r - Swap a unit displayID for a new one.\n"
MH_SLASHHELP4 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT4 ..
"|cFF00FF00 oldDisplayID displayID|r - Swap a mount displayID.\n"
MH_SLASHHELP5 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT5 ..
"|cFF00FF00 itemID inventoryslot displayID|r - Morphs a itemID at a slot.\n"
MH_SLASHHELP6 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT6 ..
"|cFF00FF00 unitToken|r - Displays a unit's display info in chat.\n"
MH_SLASHHELP7 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT7 ..
"|cFF00FF00 itemID|r - Displays an item's display info in chat.\n"
MH_SLASHHELP8 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT8 ..
"|cFF00FF00 unitToken inventorySlot displayID|r - Morphs a unit's item.\n"

MH_SLASHHELP = MH_SLASHHELP0 .. MH_SLASHHELP1 .. MH_SLASHHELP2 .. MH_SLASHHELP3 .. MH_SLASHHELP4 ..
                 MH_SLASHHELP5 .. MH_SLASHHELP8 .. MH_SLASHHELP6 .. MH_SLASHHELP7
MH_SLASHUNKNOWN = "|cFF00FF00".. MH_NAME .. ":|r unknown command"


local function doCommand(parsed_args)
    l = getn(parsed_args)
    if (l==2) then --info commands
        if parsed_args[1] == MH_OPT6 then 
            displayID, nativeDisplayID, mountDisplayID = UnitDisplayInfo(parsed_args[2])
            DEFAULT_CHAT_FRAME:AddMessage(format("DisplayID: %s nativeDisplayID: %s mountDisplayID: %s",
             displayID, nativeDisplayID, mountDisplayID))
        elseif parsed_args[1] == MH_OPT7 then
            itemDisplayID = GetItemDisplayID(parsed_args[2])
            DEFAULT_CHAT_FRAME:AddMessage(format("ItemID: %s DisplayID: %s",
             parsed_args[2], itemDisplayID))
        else
            DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
        end
    elseif (l==3) then -- morph commands
        if parsed_args[1] == MH_OPT1 then 
            SetUnitDisplayID(parsed_args[2], tonumber(parsed_args[3]))
        elseif parsed_args[1] == MH_OPT2 then
            SetUnitMountDisplayID(parsed_args[2], tonumber(parsed_args[3]))
        elseif parsed_args[1] == MH_OPT3 then
            RemapDisplayID(tonumber(parsed_args[2]), tonumber(parsed_args[3]))
        elseif parsed_args[1] == MH_OPT4 then
            RemapMountDisplayID(tonumber(parsed_args[2]), tonumber(parsed_args[3]))
        else
            DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
        end
    elseif (l==4) then -- item morph commands
        if parsed_args[1] == MH_OPT8 then
            SetUnitVisibleItemID(tonumber(parsed_args[2]), tonumber(parsed_args[3]),tonumber(parsed_args[4]))
        elseif parsed_args[1] == MH_OPT5 then 
            RemapVisibleItemID(tonumber(parsed_args[2]), tonumber(parsed_args[3]),tonumber(parsed_args[4]))
        else
            DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
    end
end

local function parseArgs(args)
    a = string.gmatch(args, '%S+')
    parsed_args = {}
    for i in a do
        table.insert(parsed_args,i)
    end
    l = getn(parsed_args)
    if (l > 0) then 
        doCommand(parsed_args)
    else
        DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
    end
end

-- chat inputs
local function TextMenu(arg)
	if arg == nil or arg == "" then
		DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHHELP,1,1,1)
	else
        parseArgs(arg)
	end
end

SlashCmdList['MORPHHELPER'] = TextMenu
