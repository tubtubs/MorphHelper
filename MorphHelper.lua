--[[
MorphHelper
By: Tubtubs
Assists in using the morph lua commands provided by Vanilla Helpers.
Slash commands, and morph window avaiable. Type /mh show to display the window  or /mh to learn more.

Requires VanillaHelpers, be sure to install that mod before using this addon.
https://github.com/isfir/VanillaHelpers
Supports WoWInit (https://github.com/tubtubs/wowinit), includes example commands.
Great for setting morphs up on login

TODO:
Investigate Items
]]--
--MorphHelper_Icon = nil

local _G = getfenv(0)
local libIcon = LibStub("LibDBIcon-1.0");
local libData = LibStub("LibDataBroker-1.1");
MH_Dewdrop = AceLibrary("Dewdrop-2.0");
local MH_Presets_Dewdrop = AceLibrary("Dewdrop-2.0");
local FPMorphed = false;
local MH_PartyStatus = -1

MH_DISPLAY_LISTS ={}
MH_CurrentMorphs ={}
--event handler and init
function MH_Test()
    if UnitAffectingCombat("player") then
        DEFAULT_CHAT_FRAME:AddMessage("TRUE")
    end
end

function MH_UpdatePartyMorphUI()
    local partyState = MH_GetPartyStatus()
    DEFAULT_CHAT_FRAME:AddMessage("PartyState: " .. MH_PartyStatus)
    if partyState ~= MH_PartyStatus then
        if MH_PartyStatus == MH_NOPARTY or MH_RAID then
            for i=3,MH_UnitTokensLen do
                u = MH_UnitTokens[i]
                getglobal(MH_MorphLabels[i]):Hide()
                getglobal(MH_MorphButtons[i]):Hide()
                getglobal(MH_MorphMountButtons[i]):Hide()
                getglobal(MH_MorphInfoButtons[i]):Hide()
                getglobal(MH_MountInfoButtons[i]):Hide()
                getglobal(MH_MorphResetButtons[i]):Hide()
                getglobal(MH_MorphMountResetButtons[i]):Hide()
                getglobal("MH_DisplayList_RaidFrame"):Hide()
                getglobal("MH_DisplayList_RaidFrameScrollFrame"):Hide()
            end
        end -- nothing to hide if you're alone ;-;
        -- show new state's UI
    end

    MH_PartyStatus = partyState
    DEFAULT_CHAT_FRAME:AddMessage("PartyState: " .. MH_PartyStatus)
    if MH_PartyStatus == MH_PARTY then
        for i=3,MH_UnitTokensLen do
            u = MH_UnitTokens[i]
            if (UnitExists(u) or MH_PRESETMODE) then --hides invalid units, or shows if preset mode
                --disable morph buttons if no displayID is selected
                getglobal(MH_MorphLabels[i]):Show()
                getglobal(MH_MorphButtons[i]):Show()
                getglobal(MH_MorphMountButtons[i]):Show()
                getglobal(MH_MorphInfoButtons[i]):Show()
                getglobal(MH_MountInfoButtons[i]):Show()
                getglobal(MH_MorphResetButtons[i]):Show()
                getglobal(MH_MorphMountResetButtons[i]):Show()
            else
                getglobal(MH_MorphLabels[i]):Hide()
                getglobal(MH_MorphButtons[i]):Hide()
                getglobal(MH_MorphMountButtons[i]):Hide()
                getglobal(MH_MorphInfoButtons[i]):Hide()
                getglobal(MH_MountInfoButtons[i]):Hide()
                getglobal(MH_MorphResetButtons[i]):Hide()
                getglobal(MH_MorphMountResetButtons[i]):Hide()
            end
        end
    elseif MH_PartyStatus == MH_RAID then
        getglobal("MH_DisplayList_RaidFrame"):Show()
        getglobal("MH_DisplayList_RaidFrameScrollFrame"):Show()
    end
end

function MH_VariablesLoaded()
    if (event=="PLAYER_TARGET_CHANGED") then
        if MH_DisplayList:IsShown() then
            MH_DisplayList_UpdateButtons()
        end
    elseif event=="PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        --rework unit tokens...
        --change morphUI if applicable...
        --lastly update buttons for good measure...
        -- redo unit tokens...?
        MH_CheckMorphUnitTokens()
        MH_UpdatePartyMorphUI()
        if MH_DisplayList:IsShown() then
            if UnitPlayerOrPetInRaid("player") then
                MH_DisplayList_RaidGroup_Update()
            else
                MH_DisplayList_UpdateButtons()
            end
        end
    elseif (event=="PLAYER_LOGIN") then -- Variables Loaded
        MH_Init()
    elseif event=="BUFF_ADDED_SELF" then 
        --arg3 is spellID 
        --DEFAULT_CHAT_FRAME:AddMessage(GetSpellRecField(arg3,"effectMechanic"))
        local spellEffectName = GetSpellRecField(arg3,"effectApplyAuraName")
        if spellEffectName[1] == 78 then
            --Morph me...
            local d
            if MH_CurrentMorphs.Morphs["player"] == nil then
                d = nil
            else
                d = MH_CurrentMorphs.Morphs["player"].MID 
            end
            if d == nil then -- manually morph mount to account for bug...
                local spellEffectUnit = GetSpellRecField(arg3,"effectMiscValue")
                C_CreatureInfo.RequestLoadCreatureByID(spellEffectUnit[1])
                local cinfo = C_CreatureInfo.GetCreatureInfoByID(spellEffectUnit[1])
                -- there's a chance this info isn't ready after first query?
                -- just keep retrying a few more times, seems to always work...
                if cinfo == nil or cinfo.displayID == nil then
                    TT_QueuedMount = spellEffectUnit[1]
                    TT_QueuedToken = "player"
                    UnitXP("timer", "arm", 0, 125, "MH_MountMorphTimer")
                else
                    SetUnitMountDisplayID("player", cinfo.displayID)
                end
            else
                SetUnitMountDisplayID("player", d)
            end
        end
        --test = GetSpellRec(arg3)
        --DeepPrint(test)
        --TT_TestFrame_ScrollFrame_EditBox:SetText(TT_Total)
        --TT_TestFrame:Show()
    elseif event=="BUFF_REMOVED_SELF" then
        local spellEffectName = GetSpellRecField(arg3,"effectApplyAuraName")
        if spellEffectName[1] == 78 then
            --deMorph me...
            DEFAULT_CHAT_FRAME:AddMessage("Test")
            SetUnitMountDisplayID("player", 0)
        end
    elseif event=="BUFF_ADDED_OTHER" then
        --scan party for matching GUIDs
        local token = nil
        if UnitPlayerOrPetInRaid("player") then
            for i=1, GetNumRaidMembers() do
                if GetUnitGUID("raid"..i) == arg1 then
                    token = "raid"..i
                end
            end
        elseif GetNumPartyMembers() > 0 then 
            for i=1, GetNumPartyMembers() do
                if GetUnitGUID("party"..i) == arg1 then
                    token = "party"..i
                end
            end
        end
        if token ~= nil then --found the player, find their morph...
            local d = MH_GetMountMorph(token)
            if d == -1 then -- manually morph mount to account for bug...
                local spellEffectUnit = GetSpellRecField(arg3,"effectMiscValue")
                C_CreatureInfo.RequestLoadCreatureByID(spellEffectUnit[1])
                local cinfo = C_CreatureInfo.GetCreatureInfoByID(spellEffectUnit[1])
                -- there's a chance this info isn't ready after first query?
                if cinfo == nil or cinfo.displayID == nil then
                    --TT_QueuedMount = spellEffectUnit[1]
                    --TT_QueuedToken = token
                    TT_QueuedMounts[token] = spellEffectUnit[1]
                    UnitXP("timer", "arm", 125, 125, MH_MountMorphTimer)
                else
                    SetUnitMountDisplayID(token, cinfo.displayID)
                end
            else
                SetUnitMountDisplayID(token, d)
            end
        end
    elseif event=="BUFF_REMOVED_OTHER" then
        --scan party for matching GUIDs
        local token = nil
        if UnitPlayerOrPetInRaid("player") then
            for i=1, GetNumRaidMembers() do
                if GetUnitGUID("raid"..i) == arg1 then
                    token = "raid"..i
                end
            end
        elseif GetNumPartyMembers() > 0 then 
            for i=1, GetNumPartyMembers() do
                if GetUnitGUID("party"..i) == arg1 then
                    token = "party"..i
                end
            end
        end
        if token ~= nil then --found the player, find their morph...
            local spellEffectName = GetSpellRecField(arg3,"effectApplyAuraName")
            if spellEffectName[1] == 78 then
                --deMorph me...
                SetUnitMountDisplayID(token, 0)
            end
        end
    elseif (event == "UNIT_FLAGS") then
        if (FPMorphed and not UnitOnTaxi("player")) then 
            SetUnitMountDisplayID("player", 0)
            MH_AMSendMorph("player",MH_AMFPMORPH,0)
            FPMorphed = false
        elseif (MH_Vars.FPMorph ~= -1 and UnitOnTaxi("player")) then
            SetUnitMountDisplayID("player", MH_Vars.FPMorph)
            MH_AMSendMorph("player",MH_AMFPMORPH,MH_Vars.FPMorph)
            FPMorphed = true
        end
    elseif event == "CHAT_MSG_ADDON" then
        if MH_Vars.MsgRecv and arg4 ~= UnitName("PLAYER") and arg1==MH_AMPREFIX then
            MH_AMHandler(arg2,arg3,arg4)
        end
    end
end

function MH_Registers()
    MH_Listener:RegisterEvent("PLAYER_TARGET_CHANGED");
    MH_Listener:RegisterEvent("PARTY_MEMBERS_CHANGED");
    MH_Listener:RegisterEvent("BUFF_ADDED_SELF");
    MH_Listener:RegisterEvent("BUFF_REMOVED_SELF");
    MH_Listener:RegisterEvent("BUFF_ADDED_OTHER");
    MH_Listener:RegisterEvent("BUFF_REMOVED_OTHER");
    MH_Listener:RegisterEvent("UNIT_FLAGS");
    MH_Listener:RegisterEvent("CHAT_MSG_ADDON");
    MH_Listener:RegisterEvent("RAID_ROSTER_UPDATE");
end

function MH_FixTargetToken()
    local found = 0 
    local token = "TARGET"
    local GUID = GetUnitGUID("target")
    if UnitPlayerOrPetInRaid("player") then
        for i=1, GetNumRaidMembers() do
            if GetUnitGUID("raid"..i) == GUID then
                token = "raid".. i
                break
            end
        end
    elseif GetNumPartyMembers() > 0 then 
        for i=1, GetNumPartyMembers() do
            if GetUnitGUID("party"..i) == GUID then
                token = "party" .. i
                break
            end
        end
    end
    return token
end


function MH_CheckMorphUnitTokens()
    local t = {}
    for k,v in MH_CurrentMorphs.Morphs do 
        local GUID
        if UnitPlayerOrPetInRaid("player") and string.find(k,"party") then
            GUID = nil
        else
            GUID = GetUnitGUID(k) 
        end        
        if  GUID ~= v.GUID then
            if GUID == GetUnitGUID("player") then
                t["player"] = v
            elseif UnitPlayerOrPetInRaid("player") then
                for i=1, GetNumRaidMembers() do
                    if GetUnitGUID("raid"..i) == v.GUID then
                        t["raid"..i] = v
                        break
                    end
                end
            elseif GetNumPartyMembers() > 0 then 
                DEFAULT_CHAT_FRAME:AddMessage(GetNumPartyMembers())
                for i=1, GetNumPartyMembers() do
                    if GetUnitGUID("party"..i) == v.GUID then
                        t["party"..i] = v
                        break
                    end
                end
            end
        else
            t[k] = v
        end
    end
    MH_CurrentMorphs.Morphs = t
end

local function doCommand(parsed_args)
    l = getn(parsed_args)
    if (l==1) then
        if parsed_args[1]==string.lower(MH_OPT9) then
            MH_DisplayList:Show();
        elseif parsed_args[1]==string.lower(MH_OPT10) then
            MH_DisplayList_ResetPos()
        elseif parsed_args[1]==string.lower(MH_OPT11) then
            MH_GenderFlipMode()
        elseif parsed_args[1]==string.lower(MH_OPT12) then
            MH_SecretCowPowers()
        elseif parsed_args[1]==string.lower(MH_OPT13) then
            MH_ResetAll()
        elseif parsed_args[1]==string.lower(MH_OPT15) then
            MH_ListPresets()
        else
            DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
        end
    elseif (l==2) then --info commands
        if parsed_args[1] == string.lower(MH_OPT6) then 
            local displayID, nativeDisplayID, mountDisplayID = UnitDisplayInfo(parsed_args[2])
            DEFAULT_CHAT_FRAME:AddMessage(format("DisplayID: %s nativeDisplayID: %s mountDisplayID: %s",
             displayID, nativeDisplayID, mountDisplayID))
        elseif parsed_args[1] == string.lower(MH_OPT7) then
            itemDisplayID = GetItemDisplayID(parsed_args[2])
            DEFAULT_CHAT_FRAME:AddMessage(format("ItemID: %s DisplayID: %s",
             parsed_args[2], itemDisplayID))
        elseif parsed_args[1] == string.lower(MH_OPT16) then
            MH_Vars.FPMorph = tonumber(parsed_args[2])
            if (MH_Vars.FPMorph ~= -1) then
                DEFAULT_CHAT_FRAME:AddMessage(format("Set Flight Path Morph to: %s", MH_Vars.FPMorph))
            else
                DEFAULT_CHAT_FRAME:AddMessage("Disabled Flight Path Morph")
            end
        elseif parsed_args[1] == string.lower(MH_OPT14) then
            MH_ApplyPresetID(tonumber(parsed_args[2]))
        elseif parsed_args[1] == string.lower(MH_OPT17) then
            if parsed_args[2] == string.lower("hide") then
                MH_HideMinimap()
            elseif parsed_args[2] == string.lower("show") then
                MH_ShowMinimap()
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
        end
    elseif (l==3) then -- morph commands
        if parsed_args[1] == string.lower(MH_OPT1) then 
            MH_AMSendMorph(parsed_args[2], MH_AMMORPHPLAYER, parsed_args[3])
            SetUnitDisplayID(parsed_args[2], tonumber(parsed_args[3]))
        elseif parsed_args[1] == string.lower(MH_OPT2) then
            MH_AMSendMorph(parsed_args[2], MH_AMMORPHMOUNT, parsed_args[3])
            SetUnitMountDisplayID(parsed_args[2], tonumber(parsed_args[3]))
        elseif parsed_args[1] == string.lower(MH_OPT3) then
            MH_AMSendSwap(MH_AMSWAPID, parsed_args[2], parsed_args[3])
            RemapDisplayID(tonumber(parsed_args[2]), tonumber(parsed_args[3]))
        elseif parsed_args[1] == string.lower(MH_OPT4) then
            MH_AMSendSwap(MH_AMSWAPMID, parsed_args[2], parsed_args[3])
            RemapMountDisplayID(tonumber(parsed_args[2]), tonumber(parsed_args[3]))
        else
            DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
        end
    elseif (l==4) then -- item morph commands
        if parsed_args[1] == string.lower(MH_OPT8) then
            SetUnitVisibleItemID(parsed_args[2], tonumber(parsed_args[3]),tonumber(parsed_args[4]))
        elseif parsed_args[1] == string.lower(MH_OPT5) then 
            RemapVisibleItemID(tonumber(parsed_args[2]), tonumber(parsed_args[3]),tonumber(parsed_args[4]))
        else
            DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage(MH_SLASHUNKNOWN,1,0.3,0.3)
    end
end

local function parseArgs(args)
    args = string.lower(args) --decided to make args case insensitive
    a = string.gfind(args, '%S+')
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


local function TextMenu(arg)
	if arg == nil or arg == "" then
        for w in string.gfind(MH_SLASHHELP, "([^\r\n]+)") do
            DEFAULT_CHAT_FRAME:AddMessage(w,1,1,1)
        end
	else
        parseArgs(arg)
	end
end

function MH_Init()
    -- Classic API Check
    local clientModLoaded = true
    if CLASSIC_API_VERSION ~= nil then
        if CLASSIC_API_VERSION < MH_V_CLASSICAPI then --out of date
            DEFAULT_CHAT_FRAME:AddMessage(MH_V_CLASSICAPI_O)
            clientModLoaded = false
        end
    else -- not installed
        DEFAULT_CHAT_FRAME:AddMessage(MH_V_CLASSICAPI_M)
        clientModLoaded = false
    end
    -- UnitXP3_SP3 check
    local xp3exist, xp3buildTime = pcall(UnitXP, "version", "coffTimeDateStamp");
    if xp3exist then
        if xp3buildTime < MH_V_UNITXP3 then --out of date
            DEFAULT_CHAT_FRAME:AddMessage(MH_V_UNITXP3_O)
            clientModLoaded = false
        end
    else -- not installed
        DEFAULT_CHAT_FRAME:AddMessage(MH_V_UNITXP3_M)
        clientModLoaded = false
    end
        
    -- Nampower check
    if GetNampowerVersion == nil then --not installed
        DEFAULT_CHAT_FRAME:AddMessage(MH_V_NAMPOWER_M)
        clientModLoaded = false
    else
        local major, minor, patch=GetNampowerVersion();
        local namV = (major*100) + (minor*10) + patch
        if namV < MH_V_NAMPOWER then --out of date
            DEFAULT_CHAT_FRAME:AddMessage(MH_V_NAMPOWER_O)
            clientModLoaded = false
        end
    end

    -- VanillaHelpers Check
    if SetUnitMountDisplayID == nil then
        DEFAULT_CHAT_FRAME:AddMessage(MH_V_VANILLAHELPERS_M)
        clientModLoaded = false
    end

    if not clientModLoaded then
        return
    end

    SlashCmdList['MORPHHELPER'] = TextMenu
    local firstrun = 0
    if (not MH_Vars) then
        MH_Vars = {
            Presets=MH_DEFAULT_PRESETS,
            Favorites = {},
            FavoritesLen = 0,
            FPMorph = -1,
            MsgSend = true,
            MsgRecv = true,
        };
        firstrun = 1
    elseif (not MH_Vars.FPMorph) then
        MH_Vars.FPMorph = -1;
    elseif not MH_Vars.MsgSend then
        MH_Vars.MsgSend = true
        MH_Vars.MsgRecv = true
    end
    --initialize display lists
    r = GetRealmName()
    find = 0
    find = string.find(r,"Wallcraft")
    if find==nil then --Standard, or Turtle?
        if (TWMinimapShopFrame~=nil or TWMiniMapBattlefieldFrame~=nil or LFT_Minimap~=nil) then --turtle
            MH_DISPLAY_LISTS = {
                {
                    list=MH_CreatureList_TW,
                    len=MH_CreatureList_TWLen
                },
                {
                    list=MH_RaceList_TW,
                    len=MH_RaceList_TWLen
                },
                {
                    list=MH_MountList_TW,
                    len=MH_MountList_TWLen
                },
                {
                    list=MH_Vars.Favorites,
                    len=MH_Vars.FavoritesLen
                }
            }
            DEFAULT_CHAT_FRAME:AddMessage(MH_S_TWOW)
        else --standard vanilla
            MH_DISPLAY_LISTS = {
                {
                    list=MH_CreatureList_V,
                    len=MH_CreatureList_VLen
                },
                {
                    list=MH_RaceList_V,
                    len=MH_RaceList_VLen
                },
                {
                    list=MH_MountList_V,
                    len=MH_MountList_VLen
                },
                {
                    list=MH_Vars.Favorites,
                    len=MH_Vars.FavoritesLen
                }
            }
            if firstrun == 1 then
                for i,j in pairs(MH_TW_PRESETS) do
                    table.insert(MH_Vars.Presets,j)
                end
            end
            DEFAULT_CHAT_FRAME:AddMessage(MH_S_VWOW)
        end
    else --Wallcraft
        MH_DISPLAY_LISTS = {
            {
                list=MH_CreatureList_WC,
                len=MH_CreatureList_WCLen
            },
            {
                list=MH_RaceList_WC,
                len=MH_RaceList_WCLen
            },
            {
                list=MH_MountList_WC,
                len=MH_MountList_WCLen
            },
            {
                list=MH_Vars.Favorites,
                len=MH_Vars.FavoritesLen
            },
        }
        if firstrun == 1 then
            for i,j in pairs(MH_WC_PRESETS) do
                table.insert(MH_Vars.Presets,j)
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage(MH_S_WC)
    end
    --Initialize WoWInit's list of presets
    if (WI_Vars) then 
        --Example Morph and Presets Menu Stub
        for i,j in pairs(MH_WI_Examples) do
            table.insert(WI_EXAMPLES[1], j)
        end

        --Presets Menu
        MH_UpdateWoWInitPresets()
    end
    --Initialize empty tables
    MH_CurrentMorphs = {
        Dirty=false,
        Morphs = {  
        }
    }
    if MorphHelper_Icon == nil then
        MorphHelper_Icon = {
            hide = false
        };
    end
    MH_MinimapIconRegister()
    MH_DewdropRegister()
    MH_Presets_DewdropRegister()
    MH_UpdatePartyMorphUI()
    --MH_PartyStatus = MH_GetPartyStatus()
    MH_Registers()
    DEFAULT_CHAT_FRAME:AddMessage(MH_NAMEVERSION .. " loaded.")
end

function MH_GetPartyStatus()
    if UnitPlayerOrPetInRaid("player") then
        return MH_RAID
    elseif GetNumPartyMembers() > 0 then 
        return MH_PARTY
    else
        return MH_NOPARTY
    end
end

function MH_UpdateWoWInitPresets()
    --Presets Menu Purge
    if (WI_Vars) then
        l = getn(WI_EXAMPLES[2])
        for i=1, l do
            v = l + 1 - i
            j = {}
            j = WI_EXAMPLES[2][v]
            --DEFAULT_CHAT_FRAME:AddMessage(j.name)
            if j.value == "MH_Presets" then
                table.remove(WI_EXAMPLES[2],v)
            end
        end

        --Presets Menu Re-Add
        for i,j in pairs(MH_Vars.Presets) do
            t = {}
            t =         
            {
                name = j.ID .. ". " .. j.Name,
                tooltip = "",
                example = "\n/mh applyPreset " .. j.ID,
                value = "MH_Presets",
                check = function() 
                    return true
                end,
        }
        table.insert(WI_EXAMPLES[2], t)
        end    
    end
end

--Dropdown Menu Code
function MH_PresetsDewDropGen(minimapBtn)

    for i,j in ipairs(MH_Vars.Presets) do
        chk = false

        if minimapBtn then
            if j.ID == MH_AppliedPresetID then
                chk=true;
            end
            MH_Dewdrop:AddLine(
                'text', j.ID .. ". " ..  j.Name,
                'textR', 1,
                'textG', 0.82,
                'textB', 0,
                'func', MH_ApplyPresetID,
                'arg1', j.ID,
                'notCheckable', false,
                'checked', chk
            )
        else
            if j.ID == MH_CurrentPresetID then
                chk=true;
            end
            MH_Dewdrop:AddLine(
                'text', j.ID .. ". " .. j.Name,
                'textR', 1,
                'textG', 0.82,
                'textB', 0,
                'func', MH_SetCurrentPresetID,
                'arg1', j.ID,
                'notCheckable', false,
                'checked', chk
            )
        end
    end

    MH_Dewdrop:AddLine(
        'text' , "Close Menu",
        'textR', 0,
        'textG', 1,
        'textB', 1,
        'func' , function() MH_Dewdrop:Close() end,
        'notCheckable', true
    )
end

function MH_Presets_DewdropRegister()
    MH_Presets_Dewdrop:Register(MH_DisplayList_PresetsButton, --Bound Frame
		'point', function(parent) --Point
			return "TOP", "BOTTOM"
		end,
		'children', function(level, value) --Children
			if level == 1 then
                MH_PresetsDewDropGen(false)
            end
		end,
		'dontHook', true
	)
end

function MH_DewdropRegister()
    if not MorphHelper_Icon.hide then
        MH_Dewdrop:Register(libIcon:GetMinimapButton("MorphHelper icon"), --Bound Frame
            'point', function(parent) --Point
                return "TOP", "BOTTOM"
            end,
            'children', function(level, value) --Children
                if level == 1 then
                    for i,j in ipairs(MH_Menu) do
                        if j.notCheckable ~= nil and not j.notCheckable then                            
                            MH_Dewdrop:AddLine(
                                'text', j.text,
                                'tooltipTitle', j.tooltipTitle,
                                'tooltipText', j.tooltipText,  
                                'textR', 1,
                                'textG', 0.82,
                                'textB', 0,
                                'func', j.func,
                                'hasArrow', j.hasArrow,
                                'checked', j.checked(),
                                'value', j.value,
                                'notCheckable', j.notCheckable
                            )
                        else

                            MH_Dewdrop:AddLine(
                                'text', j.text,
                                'tooltipTitle', j.tooltipTitle,
                                'tooltipText', j.tooltipText,  
                                'textR', 1,
                                'textG', 0.82,
                                'textB', 0,
                                'func', j.func,
                                'hasArrow', j.hasArrow,
                                'value', j.value,
                                'notCheckable', j.notCheckable
                            )
                        end
                    end

                    --Close button
                    MH_Dewdrop:AddLine(
                        'text' , "Close Menu",
                        'textR', 0,
                        'textG', 1,
                        'textB', 1,
                        'func' , function() MH_Dewdrop:Close() end,
                        'notCheckable', true
                    )
                elseif level == 2 then
                    MH_PresetsDewDropGen(true)
                end
            end,
            'dontHook', true
        )
    end
end

--Minimap Button Setup
function MH_MinimapIconRegister()
    if not MorphHelper_Icon.hide then
        local iconData = libData:NewDataObject("MorphHelper icon data", {
            OnClick = function()
                if MH_Dewdrop:IsOpen() then
                    MH_Dewdrop:Close();
                else
                    MH_Dewdrop:Open(this);
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:SetText(MH_NAMEVERSION);
            end,
            icon = "Interface\\Icons\\INV_Wand_02"
        });

        libIcon:Register("MorphHelper icon", iconData, MorphHelper_Icon);
    end
end

-- slashcommands
SLASH_MORPHHELPER1 = '/MorphHelper'
SLASH_MORPHHELPER2 = '/Morph'
SLASH_MORPHHELPER3 = '/MH'
MH_OPT1 = "morph"
MH_OPT2 = "morphMount"
MH_OPT3 = "remap"
MH_OPT4 = "remapMount"
MH_OPT5 = "remapItem"
MH_OPT6 = "getUnit"
MH_OPT7 = "getItem"
MH_OPT8 = "morphUnitItem"
MH_OPT9 = "show"
MH_OPT10 = "resetWindow"
MH_OPT11 = "genderSwap"
MH_OPT12 = "secretCowPowers"
MH_OPT13 = "resetAll"
MH_OPT14 = "applyPreset"
MH_OPT15 = "listPresets"
MH_OPT16 = "FPMorph"
MH_OPT17 = "minimap"

MH_SLASHHELP0 = "|cFF00FF00" .. MH_NAME .. ":|r This is the help topic for |cFFFFFF00".. SLASH_MORPHHELPER1 .. " " ..
                    SLASH_MORPHHELPER2  .." " .. SLASH_MORPHHELPER3 .. ".|r\n"
MH_SLASHHELP9 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT9 ..
"|r - Shows the morph helper window.\n"
MH_SLASHHELP10 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT10 ..
"|r - Resets the morph helper window position (center screen).\n"
MH_SLASHHELP13 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT13 ..
"|r - Resets all morphs, won't undo swaps. ReloadUI if this fails.\n"
MH_SLASHHELP14 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT14 ..
"|cFF00FF00 presetIndex |r - Applies a preset, at specified index.\n"
MH_SLASHHELP15 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT15 ..
"|r - Lists saved presets, and their index.\n"
MH_SLASHHELP16 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT16 ..
"|cFF00FF00 displayID|r - On taxis morph mount to displayID. Set to -1 to disable.\n"
MH_SLASHHELP17 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT17 ..
"|cFF00FF00 {hide/show}|r - Show or hide the minimap button\n"

--MH_SLASHHELP99 = [[Mount Morph Helper Functions:]] .. "\n"
--MH_SLASHHELP98 = [[|cFFFFFF00 /run MH_MountSpell("SpellName","BuffName",displayID)|r]] .. "\n"
--MH_SLASHHELP97 = [[|cFFFFFF00 /run MH_MountItem("ItemName","BuffName",displayID)|r]] .. "\n"

MH_SLASHHELP1 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT1 ..
"|cFF00FF00 unitToken displayID|r - Morphs unit to a displayID.\n"
MH_SLASHHELP2 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT2 ..
"|cFF00FF00 unitToken displayID|r - Morphs unit's mount to a displayID.\n"
MH_SLASHHELP3 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT3 ..
"|cFF00FF00 oldDisplayID displayID|r - Swap a unit displayID for a new one.\n"
MH_SLASHHELP4 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT4 ..
"|cFF00FF00 oldDisplayID displayID|r - Swap a mount displayID.\n"
MH_SLASHHELP5 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT5 ..
"|cFF00FF00 itemID inventoryslot itemID|r - Morphs a itemID at a slot.\n"
MH_SLASHHELP6 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT6 ..
"|cFF00FF00 unitToken|r - Displays a unit's display info in chat.\n"
MH_SLASHHELP7 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT7 ..
"|cFF00FF00 itemID|r - Displays an item's display info in chat.\n"
MH_SLASHHELP8 = "|cFFFFFF00 " ..SLASH_MORPHHELPER3.. " " .. MH_OPT8 ..
"|cFF00FF00 unitToken inventorySlot itemID|r - Morphs a unit's item.\n"

MH_SLASHHELP = MH_SLASHHELP0 .. MH_SLASHHELP9 .. MH_SLASHHELP17 .. MH_SLASHHELP10 .. MH_SLASHHELP13 .. MH_SLASHHELP15 .. MH_SLASHHELP14 .. MH_SLASHHELP1 .. MH_SLASHHELP2 .. MH_SLASHHELP16 .. MH_SLASHHELP3 .. MH_SLASHHELP4 ..
                 MH_SLASHHELP5 .. MH_SLASHHELP8 .. MH_SLASHHELP6 .. MH_SLASHHELP7 
MH_SLASHUNKNOWN = "|cFF00FF00".. MH_NAME .. ":|r unknown command"

function MH_GenderFlipMode()
    p = {
        {49,50}, --human
        {51,52}, --orc
        {53,54}, --dwarf
        {55,56}, --NE
        {57,58}, --UD
        {59,60}, --Tauren
        {1563, 1564}, --gnome  
        {1478,1479}, --troll 
    }
    l_p = getn(p)
    for i=1, l_p do
        MH_AMSendSwap(MH_AMSWAPID, p[i][1],p[i][2])
        MH_AMSendSwap(MH_AMSWAPID, p[i][2],p[i][1])
        RemapDisplayID(p[i][1],p[i][2])
        RemapDisplayID(p[i][2],p[i][1])
    end
    DEFAULT_CHAT_FRAME:AddMessage("Secret gender swap mode engaged!")
end

function MH_SecretCowPowers()
    t_w = 60
    t_m = 59
    p = {
        {49,50}, --human
        {51,52}, --orc
        {53,54}, --dwarf
        {55,56}, --NE
        {57,58}, --UD
        {59,60}, --Tauren
        {1563, 1564}, --gnome  
        {1478,1479}, --troll 
    }
    l_p = getn(p)
    for i=1, l_p do
        MH_AMSendSwap(MH_AMSWAPID, p[i][1],t_m)
        MH_AMSendSwap(MH_AMSWAPID, p[i][2],t_w)
        RemapDisplayID(p[i][1],t_m)
        RemapDisplayID(p[i][2],t_w)
    end
    DEFAULT_CHAT_FRAME:AddMessage("Secret cow powers engaged!")
end

function MH_ListPresets()
    DEFAULT_CHAT_FRAME:AddMessage(MH_NAME .. " " .. MH_PRESETS .. ":")
    for i,j in pairs(MH_Vars.Presets) do
        DEFAULT_CHAT_FRAME:AddMessage(j.ID .. ". " .. j.Name)
    end

end

function MH_HideMinimap()
    MorphHelper_Icon.hide = true
    libIcon:Hide("MorphHelper icon")
end

function MH_ShowMinimap()
	MorphHelper_Icon.hide = false
	if (libIcon:GetMinimapButton("MorphHelper icon")) then
		libIcon:Show("MorphHelper icon")
	else
        MH_MinimapIconRegister()
        MH_DewdropRegister()
	end
end


-- chat inputs


-- UI CODE --
MH_NUM_DISPLAYS_SHOWN = 8
MH_NUM_RAIDS_SHOWN = 1

MH_CurrentList = 1
MH_OLDIDFOCUS = false
MH_NEWIDFOCUS = false
MH_PRESETMODE = false

MH_MorphLabels = {
    "MH_DisplayListPlayerTitle",
    "MH_DisplayListTargetTitle",
    "MH_DisplayListParty1Title",
    "MH_DisplayListParty2Title",
    "MH_DisplayListParty3Title",
    "MH_DisplayListParty4Title"
}

MH_MorphTitles = {
    "MH_DisplayListPlayerTitle",
    "MH_DisplayListTargetTitle",
    "MH_DisplayListParty1Title",
    "MH_DisplayListParty2Title",
    "MH_DisplayListParty3Title",
    "MH_DisplayListParty4Title",
}

MH_MorphButtons = {
    "MH_DisplayList_MorphPlayer",
    "MH_DisplayList_MorphTarget",
    "MH_DisplayList_MorphParty1",
    "MH_DisplayList_MorphParty2",
    "MH_DisplayList_MorphParty3",
    "MH_DisplayList_MorphParty4"
}

MH_MorphMountButtons = {
    "MH_DisplayList_MorphMountPlayer",
    "MH_DisplayList_MorphMountTarget",
    "MH_DisplayList_MorphMountParty1",
    "MH_DisplayList_MorphMountParty2",
    "MH_DisplayList_MorphMountParty3",
    "MH_DisplayList_MorphMountParty4"
}

MH_MorphResetButtons = {
    "MH_DisplayList_MorphResetPlayer",
    "MH_DisplayList_MorphResetTarget",
    "MH_DisplayList_MorphResetParty1",
    "MH_DisplayList_MorphResetParty2",
    "MH_DisplayList_MorphResetParty3",
    "MH_DisplayList_MorphResetParty4"
}

MH_MorphMountResetButtons = {
    "MH_DisplayList_MorphMountResetPlayer",
    "MH_DisplayList_MorphMountResetTarget",
    "MH_DisplayList_MorphMountResetParty1",
    "MH_DisplayList_MorphMountResetParty2",
    "MH_DisplayList_MorphMountResetParty3",
    "MH_DisplayList_MorphMountResetParty4"
}

MH_MorphInfoButtons = {
    "MH_DisplayList_MorphInfoPlayer",
    "MH_DisplayList_MorphInfoTarget",
    "MH_DisplayList_MorphInfoParty1",
    "MH_DisplayList_MorphInfoParty2",
    "MH_DisplayList_MorphInfoParty3",
    "MH_DisplayList_MorphInfoParty4"
}

MH_MountInfoButtons = {
    "MH_DisplayList_MountInfoPlayer",
    "MH_DisplayList_MountInfoTarget",
    "MH_DisplayList_MountInfoParty1",
    "MH_DisplayList_MountInfoParty2",
    "MH_DisplayList_MountInfoParty3",
    "MH_DisplayList_MountInfoParty4"
}

MH_UnitTokens = {
    "player",
    "target",
    "party1",
    "party2",
    "party3",
    "party4"
}

MH_UnitTokensLen = getn(MH_UnitTokens)

MH_CurrentPreset = ""
MH_AppliedPreset = ""
MH_AppliedPresetIndex = 0
MH_CurrentPresetIndex = 0

MH_AppliedPresetID = 0
MH_CurrentPresetID = 0 

--Utility Functions

function MH_GetMountMorph(token)
    if MH_CurrentMorphs.Morphs[token] ~= nil then
        return MH_CurrentMorphs.Morphs[token].MID
    else
        return -1
    end
end

function MH_ResetAll()
    for i=1,MH_UnitTokensLen do
        u = MH_UnitTokens[i]
        if MH_DisplayList:IsShown() then
            getglobal(MH_MorphButtons[i]):SetChecked(0)
            getglobal(MH_MorphMountButtons[i]):SetChecked(0)
        end
    end
    MH_CurrentMorphs.Dirty = false
    for k, v in pairs(MH_CurrentMorphs.Morphs) do
        MH_CurrentMorphs.Morphs[k] = nil
        if (UnitExists(k) and not MH_PRESETMODE) then
            SetUnitDisplayID(k, 13) 
            SetUnitDisplayID(k, 0)
            SetUnitMountDisplayID(k, 0)
        end
    end
    if (MH_DisplayList:IsShown()) then
        MH_DisplayList_UpdateButtons()
    end
end

function MH_SetCurrentPresetID(PresetID)
    MH_CurrentPresetID = PresetID
    MH_Presets_Dewdrop:Close()
    MH_DisplayList_UpdateButtons()
end


function MH_ApplyPresetID(PresetID)
    found = -1
    for i=1, getn(MH_Vars.Presets) do
        if MH_Vars.Presets[i].ID == PresetID then
            found = i
        end
    end
    if found ~= -1 then
        --MH_CurrentPresetIndex = found
        MH_CurrentPreset = MH_Vars.Presets[found].Name
        --MH_AppliedPresetID = MH_Vars.Presets[found].ID
        MH_CurrentPresetID = MH_Vars.Presets[found].ID
        MH_ApplyPresetButton_OnClick()
    else
        DEFAULT_CHAT_FRAME:AddMessage(format("PresetID: %s not found.", PresetID))
    end
    MH_Dewdrop:Close()
end

-- Raid Group functions
MH_MAXRAIDGROUPS = 8
MH_CurrentRaidGroup = 1
local groupMembers = {}
function MH_DisplayList_RaidGroup_Update()
    local Offset = FauxScrollFrame_GetOffset(MH_DisplayList_RaidFrameScrollFrame);
    MH_DisplayList_RaidFrameLabel:SetText("Group" .. Offset+1)
    MH_CurrentRaidGroup = Offset + 1
    DEFAULT_CHAT_FRAME:AddMessage(MH_CurrentRaidGroup .. " " .. Offset*5 .. " " .. MH_CurrentRaidGroup*5)
    local btn = "MH_DisplayList_RaidFrameSlot"
    local filledBtn = "MH_DisplayList_RaidFrameFilledSlot"
    local filledBtnName = filledBtn .. "Name"
    groupMembers = {}
    for i=1, MH_MAXRAID do
        name, rank, subgroup, level, class, fileName, 
        zone, online, isDead, role, isML = GetRaidRosterInfo(i);
        if name~= nil and subgroup == MH_CurrentRaidGroup then
            table.insert(groupMembers, {
                name = MH_RAID_CLASS_COLORS[fileName]..name.."|r",
                class=class,
                level=level,
                token="raid"..i
            })
        end
    end
    for i=1, 5 do
        --name = table.remove(groupMembers,1)
        if groupMembers[i] == nil then
            name = nil 
        else
            name = groupMembers[i].name
        end
        if name ~= nil then
            --DEFAULT_CHAT_FRAME:AddMessage(format("%s %s %s %s", i, name, level, class))
            _G[filledBtn..i]:Show()
            _G[filledBtn..i.."Name"]:SetText(name)
            --_G[filledBtn..i.."Level"]:SetText(level)
            --_G[filledBtn..i.."Class"]:SetText(class)
            _G[btn..i]:Hide()
        else
            _G[btn..i]:Show()
            _G[filledBtn..i]:Hide()
        end
    end
    --DEFAULT_CHAT_FRAME:AddMessage(MH_DisplayList_RaidFrameScrollFrame:GetVerticalScroll())
    MH_DisplayList_UpdateButtons()
    FauxScrollFrame_Update(MH_DisplayList_RaidFrameScrollFrame, 8 , 1, 32);
end

--DisplayList Functions

function MH_DisplayList_ResetPos()
    MH_DisplayList:ClearAllPoints()
    MH_DisplayList:SetPoint("CENTER", UIParent ,"CENTER", 0, 0)
end

function MH_DisplayList_Update()
	local numDisplays = MH_DISPLAY_LISTS[MH_CurrentList].len
    --DEFAULT_CHAT_FRAME:AddMessage(format("%s",numDisplays))
    local displays = MH_DISPLAY_LISTS[MH_CurrentList].list
	--local DeckBuilderFrame_DeckButtonText, DeckBuilderFrame_DeckButton;
	local Offset = FauxScrollFrame_GetOffset(MH_DisplayList_DisplayListScrollFrame);
	local index;
	for i=1, MH_NUM_DISPLAYS_SHOWN do
        MH_DisplayList_ListFPButton = getglobal("MH_DisplayList_ListFPButton"..i.."");
		MH_DisplayList_ListFaveButton = getglobal("MH_DisplayList_ListFaveButton"..i.."");
		MH_DisplayList_ListButtonName = getglobal("MH_DisplayList_ListButton"..i.."Name");
        MH_DisplayList_ListButtonID = getglobal("MH_DisplayList_ListButton"..i.."ID");
        MH_DisplayList_ListButtonTexture = getglobal("MH_DisplayList_ListButton"..i.."Texture");
		MH_DisplayList_ListButton = getglobal("MH_DisplayList_ListButton"..i);
		index = (Offset) + i;
		if ( index <= numDisplays) then
			MH_DisplayList_ListButton:Show();
            MH_DisplayList_ListFaveButton:Show();
            MH_DisplayList_ListFPButton:Show();
            MH_DisplayList_ListButtonName:SetText(displays[index].ModelName)
            MH_DisplayList_ListButtonID:SetText(displays[index].ID)
            MH_DisplayList_ListButtonTexture:SetText(displays[index].TextureVariation1)
            found = 0
            for i=1, MH_Vars.FavoritesLen do
                a = MH_Vars.Favorites[i].ID
                if a == displays[index].ID then
                    found = i
                    break
                end
            end
            if found ~= 0 then
                MH_DisplayList_ListFaveButton:SetNormalTexture(MH_STARDISABLEDICO)
                MH_DisplayList_ListFaveButton:SetHighlightTexture(MH_STARDISABLEDICO)
                MH_DisplayList_ListFaveButton:SetScript("OnEnter",MH_DisplayList_FavoriteDeleteTooltip);
            else
                MH_DisplayList_ListFaveButton:SetNormalTexture(MH_STARICO)
                MH_DisplayList_ListFaveButton:SetHighlightTexture(MH_STARICO)
                MH_DisplayList_ListFaveButton:SetScript("OnEnter",MH_DisplayList_FavoriteTooltip);
            end
            if MH_Vars.FPMorph == displays[index].ID then
                MH_DisplayList_ListFPButton:SetNormalTexture(MH_FPDISABLEICO)
                MH_DisplayList_ListFPButton:SetHighlightTexture(MH_FPDISABLEICO)
                MH_DisplayList_ListFPButton:SetScript("OnEnter",MH_DisplayList_FPDeleteTooltip);
            else
                MH_DisplayList_ListFPButton:SetNormalTexture(MH_FPICO)
                MH_DisplayList_ListFPButton:SetHighlightTexture(MH_FPICO)
                MH_DisplayList_ListFPButton:SetScript("OnEnter",MH_DisplayList_FPTooltip);
            end
		else
			MH_DisplayList_ListButton:Hide();
            MH_DisplayList_ListFaveButton:Hide();
            MH_DisplayList_ListFPButton:Hide();
		end
		if ( index == MH_DisplayList.selectedIcon  ) then
			MH_DisplayList_ListButton:SetChecked(1);
		else
			MH_DisplayList_ListButton:SetChecked(nil);
		end
	end
	
	-- Scrollbar stuff
	FauxScrollFrame_Update(MH_DisplayList_DisplayListScrollFrame, numDisplays , MH_NUM_DISPLAYS_SHOWN, MH_NUM_DISPLAYS_SHOWN);
end

function MH_DisplayList_OnClick()
	MH_DisplayList.selectedIcon =  this:GetID() + (FauxScrollFrame_GetOffset(MH_DisplayList_DisplayListScrollFrame));
    MH_DisplayList_IDEditBox:SetText("")
    if (MH_NEWIDFOCUS) then 
        index = MH_DisplayList.selectedIcon
        displays = MH_DISPLAY_LISTS[MH_CurrentList].list
        MH_DisplayList_SwapFrame_NewIDEditBox:SetText(displays[index].ID)
        MH_DisplayList_SwapFrame_NewIDEditBox:ClearFocus()
        MH_NEWIDFOCUS = false
    elseif (MH_OLDIDFOCUS) then
        index = MH_DisplayList.selectedIcon
        displays = MH_DISPLAY_LISTS[MH_CurrentList].list
        MH_DisplayList_SwapFrame_OldIDEditBox:SetText(displays[index].ID)
        MH_DisplayList_SwapFrame_OldIDEditBox:ClearFocus()
        MH_OLDIDFOCUS = false
    end

    MH_DisplayList_Update()
    MH_DisplayList_UpdateButtons()
end

function MH_DisplayList_UpdateButtons()
    --Morph Buttons if no ID selected
    txtID = MH_DisplayList_IDEditBox:GetText()
    if UnitPlayerOrPetInRaid("player") then --raid buttons
        local filledBtn = "MH_DisplayList_RaidFrameFilledSlot"
        if MH_DisplayList.selectedIcon > 0 or string.len(txtID) > 0 then
            for i=1, getn(groupMembers) do -- just need to worry about the visible party members
                local BtnMorph = filledBtn .. i .. "_Morph"
                local BtnMountMorph = filledBtn .. i .. "_MorphMount"
                _G[BtnMorph]:Enable()
                _G[BtnMountMorph]:Enable()
                local t = groupMembers[i].token
                if MH_CurrentMorphs.Morphs[t] ~= nil then
                    if MH_CurrentMorphs.Morphs[t].ID ~= nil then
                        _G[BtnMorph]:SetChecked(1)
                    else
                    _G[BtnMorph]:SetChecked(0)
                    end
                    if MH_CurrentMorphs.Morphs[t].MID ~= nil then
                        _G[BtnMountMorph]:SetChecked(1)
                    else
                    _G[BtnMountMorph]:SetChecked(0)
                    end
                else
                    _G[BtnMountMorph]:SetChecked(0)
                    _G[BtnMorph]:SetChecked(0)
                end
            end
        else
            for i=1, getn(groupMembers) do -- just need to worry about the visible party members
                local BtnMorph = filledBtn .. i .. "_Morph"
                local BtnMountMorph = filledBtn .. i .. "_MorphMount"
                _G[BtnMorph]:Disable()
                _G[BtnMountMorph]:Disable()
                local t = groupMembers[i].token
                if MH_CurrentMorphs.Morphs[t] ~= nil then
                    if MH_CurrentMorphs.Morphs[t].ID ~= nil then
                        _G[BtnMorph]:SetChecked(1)
                    else
                        _G[BtnMorph]:SetChecked(0)
                    end
                    if MH_CurrentMorphs.Morphs[t].MID ~= nil then
                        _G[BtnMountMorph]:SetChecked(1)
                    else
                        _G[BtnMountMorph]:SetChecked(0)
                    end
                else
                    _G[BtnMountMorph]:SetChecked(0)
                    _G[BtnMorph]:SetChecked(0)
                end
            end
        end
    elseif GetNumPartyMembers() > 0 then -- just party members...
        for i=3,MH_UnitTokensLen do
            u = MH_UnitTokens[i]
            if (UnitExists(u) or MH_PRESETMODE) then --hides invalid units, or shows if preset mode
                --disable morph buttons if no displayID is selected
                if MH_DisplayList.selectedIcon > 0 or string.len(txtID) > 0 then
                    getglobal(MH_MorphButtons[i]):Enable()
                    getglobal(MH_MorphMountButtons[i]):Enable()
                else
                    getglobal(MH_MorphButtons[i]):Disable()
                    getglobal(MH_MorphMountButtons[i]):Disable()
                end
                getglobal(MH_MorphTitles[i]):SetText(GetUnitName(u))
                getglobal(MH_MorphResetButtons[i]):Enable()
                getglobal(MH_MorphMountResetButtons[i]):Enable()
                getglobal(MH_MorphInfoButtons[i]):Enable()
                getglobal(MH_MountInfoButtons[i]):Enable()
            end
            if MH_CurrentMorphs.Morphs[u] ~= nil then
                    if MH_CurrentMorphs.Morphs[u].ID ~= nil then
                        _G[MH_MorphButtons[i]]:SetChecked(1)
                    else
                        _G[MH_MorphButtons[i]]:SetChecked(0)
                    end
                    if MH_CurrentMorphs.Morphs[u].MID ~= nil then
                        _G[MH_MorphMountButtons[i]]:SetChecked(1)
                    else
                        _G[MH_MorphMountButtons[i]]:SetChecked(0)
                    end
            else
                _G[MH_MorphMountButtons[i]]:SetChecked(0)
                _G[MH_MorphButtons[i]]:SetChecked(0)
            end
        end
    end
    for i=1, 2 do -- player/target
        u = MH_UnitTokens[i]
        if (UnitExists(u) or MH_PRESETMODE) then --hides invalid units, or shows if preset mode
            --disable morph buttons if no displayID is selected
            if MH_DisplayList.selectedIcon > 0 or string.len(txtID) > 0 then
                getglobal(MH_MorphButtons[i]):Enable()
                getglobal(MH_MorphMountButtons[i]):Enable()
            else
                getglobal(MH_MorphButtons[i]):Disable()
                getglobal(MH_MorphMountButtons[i]):Disable()
            end
            getglobal(MH_MorphResetButtons[i]):Enable()
            getglobal(MH_MorphMountResetButtons[i]):Enable()
            getglobal(MH_MorphInfoButtons[i]):Enable()
            getglobal(MH_MountInfoButtons[i]):Enable()
        else
            getglobal(MH_MorphButtons[i]):Disable()
            getglobal(MH_MorphMountButtons[i]):Disable()
            getglobal(MH_MorphResetButtons[i]):Disable()
            getglobal(MH_MorphMountResetButtons[i]):Disable()
            getglobal(MH_MorphInfoButtons[i]):Disable()
            getglobal(MH_MountInfoButtons[i]):Disable()
        end
    end

    --Preset Buttons
    if MH_CurrentMorphs.Dirty then --only offer to save if there's changes
        MH_DisplayList_AddPresetButton:Enable()
    else
        MH_DisplayList_AddPresetButton:Disable()
    end
    if MH_CurrentPresetIndex > 0 then -- only offer to apply or delete if a preset is selected
        MH_DisplayList_DeletePresetButton:Enable()
        MH_DisplayList_ApplyPresetButton:Enable()
    else
        MH_DisplayList_DeletePresetButton:Disable()
        MH_DisplayList_ApplyPresetButton:Disable()
    end
    --Swap Buttons
    txtID = MH_DisplayList_SwapFrame_NewIDEditBox:GetText()
    txtOID = MH_DisplayList_SwapFrame_OldIDEditBox:GetText()
    --only enable swap buttons if both displayID fields are filled

    if (string.len(txtID) > 0 and string.len(txtOID) > 0) then
        MH_DisplayList_IDSwapsButton:Enable()
        MH_DisplayList_MountIDSwapsButton:Enable()
    else
        MH_DisplayList_IDSwapsButton:Disable()
        MH_DisplayList_MountIDSwapsButton:Disable()
        MH_DisplayList_SwapFrame_SwapIDsButton:Disable()
    end
    if (string.len(txtID) > 0 or string.len(txtOID) > 0) then
        MH_DisplayList_SwapFrame_SwapIDsButton:Enable()
    end
end

function MH_DisplayList_OnShow()
    MH_DisplayList.selectedIcon = 0
    if (MH_PRESETMODE) then
        MH_DisplayList_PresetModeCheckButton:SetChecked(1)
    else
        MH_DisplayList_PresetModeCheckButton:SetChecked(0)
    end
    MH_DisplayList_RaidGroup_Update()
    MH_DisplayList_Update()
    MH_DisplayList_UpdateButtons()
    if MorphHelper_Icon.hide then
        MH_DisplayList_MinimapToggleButton:SetChecked(0)
    else
        MH_DisplayList_MinimapToggleButton:SetChecked(1)
    end
end

function MH_DisplayList_MinimapToggleButton_OnClick()
    if MorphHelper_Icon.hide then
        MH_ShowMinimap()
    else
        MH_HideMinimap()
    end
end

function MH_DisplayList_RaidFrame_OnMouseWheel()
    s = FauxScrollFrame_GetOffset(MH_DisplayList_RaidFrameScrollFrame)
    if arg1 < 0 then 
        s = s + 1 
    else
        s = s - 1
    end
    local max = MH_MAXRAIDGROUPS-1
    if(max < 0) then
        max = 0
    end
    if s < 0 then
        s=0
    elseif s > max then
        s=max
    end
    MH_DisplayList_RaidFrameScrollFrame:SetVerticalScroll(s*32);
end

--DisplayID List Scrolling Functions
function MH_DisplayList_OnMouseWheel()
    s = FauxScrollFrame_GetOffset(MH_DisplayList_DisplayListScrollFrame)
    if arg1 < 0 then 
        s = s + 2 
    else
        s = s - 2
    end
    local max = MH_DISPLAY_LISTS[MH_CurrentList].len-MH_NUM_DISPLAYS_SHOWN
    if(max < 0) then
        max = 0
    end
    if s < 0 then
        s=0
    elseif s > max then
        s=max
    end
    MH_DisplayList_DisplayListScrollFrame:SetVerticalScroll(s*8);
end

--Scrolls to the displayID in the big list, only scrolls through All folder
function MH_ScrollToDisplayID(displayID)
    found=0
    for i=1, MH_DISPLAY_LISTS[1].len do
        a = ((MH_DISPLAY_LISTS[1].list)[i]).ID
        if (a==displayID) then
            found = i
            break
        end
    end
    if found == 0 then
        DEFAULT_CHAT_FRAME:AddMessage(format("Couldn't find displayID: %s",displayID))
    else
        MH_CurrentList = 1
        DEFAULT_CHAT_FRAME:AddMessage(format("Found displayID: %s",displayID))
        MH_DisplayList_DisplayListScrollFrame:SetVerticalScroll((floor((found-1)*8)))
        MH_DisplayList_Update()
    end
end

-- RAID UI Morph Functions

function MH_DisplayList_RaidMorph_OnClick()
    this:SetChecked(1)
    --get getDisplayID
    local displayID = MH_GetDisplayID()
    --get unitToken
    --local k = this:GetID();
    --local u = MH_UnitTokens[k]
    -- Get Parent, Get their ID, use this as index in current group members variable
    local id = this:GetParent():GetID()
    local u = groupMembers[id].token
    if GetUnitGUID(u) == GetUnitGUID("player") then
        u = "player"
    end
    if MH_CurrentMorphs.Morphs[u] == nil then MH_CurrentMorphs.Morphs[u] = {} end
    MH_CurrentMorphs.Morphs[u].GUID = GetUnitGUID(u)
    DEFAULT_CHAT_FRAME:AddMessage("GUID" .. GetUnitGUID(u))
    MH_CurrentMorphs.Morphs[u].ID = displayID
    MH_CurrentMorphs.Dirty=true
    MH_DisplayList_UpdateButtons()
    if (not MH_PRESETMODE) then
        MH_AMSendMorph(u,MH_AMMORPHPLAYER, displayID)
        SetUnitDisplayID(u, displayID)  
    end
end

function MH_DisplayList_RaidMorphMount_OnClick()
    this:SetChecked(1)
    --get getDisplayID
    local displayID = MH_GetDisplayID()
    --get unitToken
    local id = this:GetParent():GetID()
    local u = groupMembers[id].token
    if GetUnitGUID(u) == GetUnitGUID("player") then
        u = "player"
    end
    if MH_CurrentMorphs.Morphs[u] == nil then MH_CurrentMorphs.Morphs[u] = {} end
    MH_CurrentMorphs.Morphs[u].GUID = GetUnitGUID(u)
    MH_CurrentMorphs.Morphs[u].MID = displayID
    DEFAULT_CHAT_FRAME:AddMessage("GUID" .. GetUnitGUID(u))
    MH_CurrentMorphs.Dirty=true
    MH_DisplayList_UpdateButtons()
    if (not MH_PRESETMODE) then
        MH_AMSendMorph(u,MH_AMMORPHMOUNT, displayID)
        SetUnitMountDisplayID(u, displayID)
    end
end

function MH_DisplayList_RaidMorphReset_OnClick()
    --get unitToken
    local id = this:GetParent():GetID()
    local u = groupMembers[id].token
    if GetUnitGUID(u) == GetUnitGUID("player") then
        u = "player"
    end
    if MH_CurrentMorphs.Morphs[u] ~= nil then 
        MH_CurrentMorphs.Morphs[u].ID = nil
        if MH_CurrentMorphs.Morphs[u].MID == nil then MH_CurrentMorphs.Morphs[u] = nil end
    end
    MH_CurrentDisplaysCheckDirty()
    --getglobal(MH_MorphButtons[k]):SetChecked(0) TODO
    local f = this:GetParent():GetName()
    _G[f.."_Morph"]:SetChecked(0)
    --Morphing to a creature after another race makes resetting possible
    --Resets native displayID or something
    if not MH_PRESETMODE then
        MH_AMSendMorph(u,MH_AMMORPHPLAYER, -1)
        SetUnitDisplayID(u, 13) 
        SetUnitDisplayID(u, 0)
    end
end

function MH_DisplayList_RaidMorphMountReset_OnClick()
    --get unitToken
    local id = this:GetParent():GetID()
    local u = groupMembers[id].token
    if GetUnitGUID(u) == GetUnitGUID("player") then
        u = "player"
    end
    if MH_CurrentMorphs.Morphs[u] ~= nil then 
        MH_CurrentMorphs.Morphs[u].MID = nil
        if MH_CurrentMorphs.Morphs[u].ID == nil then MH_CurrentMorphs.Morphs[u] = nil end
    end
    MH_CurrentDisplaysCheckDirty()
    --getglobal(MH_MorphMountButtons[k]):SetChecked(0) TODO
    local f = this:GetParent():GetName()
    _G[f.."_MorphMount"]:SetChecked(0)
    if not MH_PRESETMODE then
        MH_AMSendMorph(u,MH_AMMORPHMOUNT, -1)
        SetUnitMountDisplayID(u, 0)
    end
end

function MH_DisplayList_RaidMorphInfo_OnClick()
    --get info about that unit, and then use that info
    --get unitToken
    local id = this:GetParent():GetID()
    local u = groupMembers[id].token
    local displayID, _, mountDisplayID = UnitDisplayInfo(u)
    if IsAltKeyDown() then
        displayID = mountDisplayID
    end
    --Find DisplayID in the big list
    if (MH_NEWIDFOCUS) then 
        MH_DisplayList_SwapFrame_NewIDEditBox:SetText(displayID)
        MH_DisplayList_SwapFrame_NewIDEditBox:ClearFocus()
        MH_NEWIDFOCUS = false
        MH_DisplayList_UpdateButtons()
    elseif (MH_OLDIDFOCUS) then
        MH_DisplayList_SwapFrame_OldIDEditBox:SetText(displayID)
        MH_DisplayList_SwapFrame_OldIDEditBox:ClearFocus()
        MH_OLDIDFOCUS = false
        MH_DisplayList_UpdateButtons()
    end
    MH_ScrollToDisplayID(displayID)
end

--UI Morph functions
function MH_GetDisplayID()
    local manualID = MH_DisplayList_IDEditBox:GetText()
    if manualID ~= nil and string.len(manualID) > 0 then
        return tonumber(manualID)
    else
        index = MH_DisplayList.selectedIcon
        displays = MH_DISPLAY_LISTS[MH_CurrentList].list
        return displays[index].ID
    end
end

function MH_DisplayList_Morph_OnClick()
    this:SetChecked(1)
    --get getDisplayID
    local displayID = MH_GetDisplayID()
    --get unitToken
    local k = this:GetID();
    local u = MH_UnitTokens[k]
    if u == "target" then 
        u = MH_FixTargetToken() 
        if u ~= "target" then 
            getglobal(MH_MorphButtons[k]):SetChecked(0)
        end
    end
    if MH_CurrentMorphs.Morphs[u] == nil then MH_CurrentMorphs.Morphs[u] = {} end
    MH_CurrentMorphs.Morphs[u].ID = displayID
    MH_CurrentMorphs.Morphs[u].GUID = GetUnitGUID(u)
    DEFAULT_CHAT_FRAME:AddMessage("GUID" .. GetUnitGUID(u))
    MH_CurrentMorphs.Dirty=true
    MH_DisplayList_UpdateButtons()
    if (not MH_PRESETMODE) then
        MH_AMSendMorph(u,MH_AMMORPHPLAYER, displayID)
        SetUnitDisplayID(u, displayID)  
    end
end

function MH_DisplayList_MorphMount_OnClick()
    this:SetChecked(1)
    --get getDisplayID
    local displayID = MH_GetDisplayID()
    --get unitToken
    local k = this:GetID();
    local u = MH_UnitTokens[k]
    if u == "target" then 
        u = MH_FixTargetToken() 
        if u ~= "target" then 
            getglobal(MH_MorphButtons[k]):SetChecked(0)
        end
    end
    if MH_CurrentMorphs.Morphs[u] == nil then MH_CurrentMorphs.Morphs[u] = {} end
    MH_CurrentMorphs.Morphs[u].MID = displayID
    MH_CurrentMorphs.Morphs[u].GUID = GetUnitGUID(u)
    MH_CurrentMorphs.Dirty=true
    MH_DisplayList_UpdateButtons()
    if (not MH_PRESETMODE) then
        MH_AMSendMorph(u,MH_AMMORPHMOUNT, displayID)
        SetUnitMountDisplayID(u, displayID)
    end
end

function MH_CurrentDisplaysCheckDirty()
    found = 0
    for k,v in pairs(MH_CurrentMorphs.Morphs) do
        if id ~= v.ID or mid ~= v.MID then
            found = 1
            break
        end
    end

    if found == 0 then
        MH_CurrentMorphs.Dirty = false
    end
    MH_DisplayList_UpdateButtons()
end

function MH_DisplayList_MorphReset_OnClick()
    --get unitToken
    local k = this:GetID();
    local u = MH_UnitTokens[k]
    if u == "target" then 
        u = MH_FixTargetToken() 
    end
    if MH_CurrentMorphs.Morphs[u] ~= nil then 
        MH_CurrentMorphs.Morphs[u].ID = nil
        if MH_CurrentMorphs.Morphs[u].MID == nil then MH_CurrentMorphs.Morphs[u] = nil end
    end
    MH_CurrentDisplaysCheckDirty()
    getglobal(MH_MorphButtons[k]):SetChecked(0)
    --Morphing to a creature after another race makes resetting possible
    --Resets native displayID or something
    if not MH_PRESETMODE then
        MH_AMSendMorph(u,MH_AMMORPHPLAYER, -1)
        SetUnitDisplayID(u, 13) 
        SetUnitDisplayID(u, 0)
    end
end

function MH_DisplayList_MorphMountReset_OnClick()
    --get unitToken
    local k = this:GetID();
    local u = MH_UnitTokens[k]
    if MH_CurrentMorphs.Morphs[u] ~= nil then 
        MH_CurrentMorphs.Morphs[u].MID = nil
        if MH_CurrentMorphs.Morphs[u].ID == nil then MH_CurrentMorphs.Morphs[u] = nil end
    end
    MH_CurrentDisplaysCheckDirty()
    getglobal(MH_MorphMountButtons[k]):SetChecked(0)
    if not MH_PRESETMODE then
        MH_AMSendMorph(u,MH_AMMORPHMOUNT, -1)
        SetUnitMountDisplayID(u, 0)
    end
end

function MH_DisplayList_MorphInfo_OnClick()
    --get info about that unit, and then use that info
    --get unitToken
    local k = this:GetID()
    local u = MH_UnitTokens[k]
    local displayID, _, _ = UnitDisplayInfo(u)
    --Find DisplayID in the big list
    if (MH_NEWIDFOCUS) then 
        MH_DisplayList_SwapFrame_NewIDEditBox:SetText(displayID)
        MH_DisplayList_SwapFrame_NewIDEditBox:ClearFocus()
        MH_NEWIDFOCUS = false
        MH_DisplayList_UpdateButtons()
    elseif (MH_OLDIDFOCUS) then
        MH_DisplayList_SwapFrame_OldIDEditBox:SetText(displayID)
        MH_DisplayList_SwapFrame_OldIDEditBox:ClearFocus()
        MH_OLDIDFOCUS = false
        MH_DisplayList_UpdateButtons()
    end
    MH_ScrollToDisplayID(displayID)
end

function MH_DisplayList_MountInfo_OnClick()
    --get info about that unit, and then use that info
    --get unitToken
    local k = this:GetID()
    local u = MH_UnitTokens[k]
    local _, _, mountDisplayID = UnitDisplayInfo(u)
    --Find DisplayID in the big list
    if mountDisplayID == 0  then 
        DEFAULT_CHAT_FRAME:AddMessage(format("Unit isn't mounted"))
    else
       MH_ScrollToDisplayID(mountDisplayID)
        if (MH_NEWIDFOCUS) then 
            MH_DisplayList_SwapFrame_NewIDEditBox:SetText(mountDisplayID)
            MH_DisplayList_SwapFrame_NewIDEditBox:ClearFocus()
            MH_NEWIDFOCUS = false
            MH_DisplayList_UpdateButtons()
        elseif (MH_OLDIDFOCUS) then
            MH_DisplayList_SwapFrame_OldIDEditBox:SetText(mountDisplayID)
            MH_DisplayList_SwapFrame_OldIDEditBox:ClearFocus()
            MH_OLDIDFOCUS = false
            MH_DisplayList_UpdateButtons()
        end
    end
end

--Morph Button Tooltips
function MH_SetupTooltip(tip)
    local k = this:GetID()
    local u = MH_UnitTokens[k]
    if (MH_PRESETMODE) then
        name = GetUnitName(u)
        tooltip = format(tip,u)
    elseif (UnitExists(u)) then
        name = GetUnitName(u)
        tooltip = format(tip,name)
    else
        tooltip = MH_TOOLTIPNOUNIT
    end
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
    GameTooltip:SetText(tooltip);
    GameTooltip:Show()
end

function MH_SetupRaidTooltip(tip)
    local id = this:GetParent():GetID()
    local u = groupMembers[id].token
    if (MH_PRESETMODE) then
        name = GetUnitName(u)
        tooltip = format(tip,u)
    elseif (UnitExists(u)) then
        name = GetUnitName(u)
        tooltip = format(tip,name)
    else
        tooltip = MH_TOOLTIPNOUNIT
    end
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
    GameTooltip:SetText(tooltip);
    GameTooltip:Show()
end

function MH_DisplayList_IDEditBox_OnEnter()
    MH_DisplayList_IDEditBox:ClearFocus()
    MH_DisplayList.selectedIcon = 0
    MH_DisplayList_Update()
    MH_DisplayList_UpdateButtons()
end

--favorites buttons
local function sort_ids(a,b)
    return a.ID < b.ID
end

function MH_DisplayListFP_OnClick()
    local index =  this:GetID() + (FauxScrollFrame_GetOffset(MH_DisplayList_DisplayListScrollFrame));
    local displays = MH_DISPLAY_LISTS[MH_CurrentList].list
    if MH_Vars.FPMorph == displays[index].ID then
        MH_Vars.FPMorph = -1 
        MH_DisplayList_FPTooltip()
    else
        MH_Vars.FPMorph = displays[index].ID
        MH_DisplayList_FPDeleteTooltip()
    end
    MH_DisplayList_Update()
end

function MH_DisplayList_FPTooltip()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
    GameTooltip:SetText(MH_TOOLTIPFPBTN);
    GameTooltip:Show();
end

function MH_DisplayList_FPDeleteTooltip()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
    GameTooltip:SetText(MH_TOOLTIPFPBTNDELETE);
    GameTooltip:Show();
end

function MH_DisplayListFave_OnClick()
    local manualID = MH_DisplayList_IDEditBox:GetText()
    local index =  this:GetID() + (FauxScrollFrame_GetOffset(MH_DisplayList_DisplayListScrollFrame));
    local displays = MH_DISPLAY_LISTS[MH_CurrentList].list
    local temp = {
        ID = displays[index].ID,
        ModelName= displays[index].ModelName,
        TextureVariation1 = displays[index].TextureVariation1;
    }
    local found = 0
    for i=1, MH_Vars.FavoritesLen do
        local a = MH_Vars.Favorites[i].ID
        if a == displays[index].ID then
            found = i
            break
        end
    end
    if found == 0 then
        table.insert(MH_Vars.Favorites,temp)
        table.sort(MH_Vars.Favorites,sort_ids)
        MH_Vars.FavoritesLen = MH_Vars.FavoritesLen + 1;
        MH_DISPLAY_LISTS[4].len = MH_DISPLAY_LISTS[4].len+1
        MH_DisplayList_Update()
        MH_DisplayList_FavoriteDeleteTooltip()
    else
        table.remove(MH_Vars.Favorites, found)
        MH_Vars.FavoritesLen = MH_Vars.FavoritesLen - 1;
        MH_DISPLAY_LISTS[4].len = MH_DISPLAY_LISTS[4].len-1
        MH_DisplayList_Update()
        MH_DisplayList_FavoriteTooltip()
    end
end

function MH_DisplayList_FavoriteTooltip()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
    GameTooltip:SetText(MH_TOOLTIPFAVORITES);
    GameTooltip:Show();
end

function MH_DisplayList_FavoriteDeleteTooltip()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
    GameTooltip:SetText(MH_TOOLTIPFAVORITESDELETE);
    GameTooltip:Show();
end

--Category Change
function MH_ChangeCategory()
    local cat = this:GetID()
    MH_CurrentList = cat
    MH_DisplayList.selectedIcon  = 0
    MH_DisplayList_DisplayListScrollFrame:SetVerticalScroll(0)
    MH_DisplayList_Update()
    MH_DisplayList_UpdateButtons()
end

--presets

function MH_PresetDropDownButton_OnClick()
    PlaySound("igCharacterInfoOpen");
    if MH_Dewdrop:IsOpen() then
        MH_Dewdrop:Close();
    else
        MH_Dewdrop:Open(this);
    end
end

function MH_AddPresetButton_OnClick()
	--prompt for a new name
    local accept = function()
        local editBox=getglobal(this:GetParent():GetName().."EditBox");
        local newPreset = editBox:GetText();
        --decided to let presets have duplicate names. Why not?
        --Need to duplicate the morphs table.
        local b = {}
        local c = {}
        --for i=1, MH_UnitTokensLen do
        for k,v in pairs(MH_CurrentMorphs.Morphs) do
            if v.ID == nil then
                c = {ID=nil, MID=v.MID}
            elseif v.MID == nil then
                c = {ID=v.ID, MID=nil}
            else
                c = {ID=v.ID, MID=v.MID}
            end
            b[k] = c
        end
        if getn(MH_Vars.Presets) > 0 then
            tid = MH_Vars.Presets[getn(MH_Vars.Presets)].ID + 1
        else
            tid = 1
        end
        local a = {
            Name=newPreset, 
            ID = tid,
            Morphs = b
        }
        table.insert(MH_Vars.Presets,a)
        DEFAULT_CHAT_FRAME:AddMessage(format("Preset %s added successfully!",newPreset));
        this:GetParent():Hide();
        MH_UpdateWoWInitPresets()
    end
	StaticPopupDialogs["MH_ADDPRESET_DIALOG"]={
		text=TEXT(MH_NEWPRESET),
		button1=TEXT(ACCEPT),
		button2=TEXT(CANCEL),
		hasEditBox=1,
		maxLetters=32,
		OnAccept=accept,
		EditBoxOnEnterPressed=accept,
		EditBoxOnEscapePressed=function()
			this:GetParent():Hide();
		end,
		timeout=0,
		exclusive=1
	};
	StaticPopup_Show("MH_ADDPRESET_DIALOG");
	getglobal(getglobal(StaticPopup_Visible("MH_ADDPRESET_DIALOG")):GetName().."EditBox"):SetText("");
end

function MH_DisplayList_ApplyPresetButton_Tooltip()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
    --generate display info for current morphs
    local tooltip = MH_APPLYPRESETTOOLTIP .. "\nPreset Morphs:\n"
    --local id = -1
    --local mid = -1
    --for i=1, MH_UnitTokensLen do
    for k,v in pairs(MH_Vars.Presets[MH_CurrentPresetIndex].Morphs) do
        if v.ID ~= nil then
            tooltip = tooltip ..  k .. " ID: " .. v.ID .. "\n"
        end
        if v.MID ~= nil then
            tooltip = tooltip ..  k .. " MID: " .. v.MID .. "\n"
        end
    end
    GameTooltip:SetText(tooltip);
    GameTooltip:Show();
end

function MH_DisplayList_AddPresetButton_Tooltip()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
    --generate display info for current morphs
    local tooltip = MH_ADDPRESETSTOOLTIP .. "\nCurrent Morphs:\n"
    --local id = -1
    --local mid = -1
    --for i=1, MH_UnitTokensLen do
    for k,v in pairs(MH_CurrentMorphs.Morphs) do
        --id = MH_CurrentMorphs.Morphs[i].ID
        --mid = MH_CurrentMorphs.Morphs[i].MID
        if v.ID ~= nil then
            tooltip = tooltip .. k .. " ID: " .. v.ID .. "\n"
        end
        if v.MID ~= nil then
            tooltip = tooltip .. k .. " MID: " .. v.MID .. "\n"
        end
    end
    GameTooltip:SetText(tooltip);
    GameTooltip:Show();
end

function MH_DeletePresetButton_OnClick()
    --Confirmation dialog
    StaticPopupDialogs["MH_DELETEPRESET_CONFIRMATION"] = {
	text = "Do you want to delete the preset: " .. MH_CurrentPreset .. "?",
	button1 = "Yes",
	button2 = "No",
	OnAccept = function()
        table.remove(MH_Vars.Presets,MH_CurrentPresetIndex)
        MH_CurrentPresetIndex = 0
        MH_CurrentPreset = ""
        MH_DisplayList_UpdateButtons()
        MH_UpdateWoWInitPresets()
	    --ReloadUI();	
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}
	StaticPopup_Show("MH_DELETEPRESET_CONFIRMATION")
end

function MH_ApplyPresetButton_OnClick()
    --MH_AppliedPresetIndex = MH_CurrentPresetIndex
    --MH_AppliedPreset = MH_Vars.Presets[MH_CurrentPresetIndex].Name
    found = -1
    for i=1, getn(MH_Vars.Presets) do
        if MH_Vars.Presets[i].ID == MH_CurrentPresetID then
            found = i
        end
    end
    MH_AppliedPresetID = MH_CurrentPresetID
    MH_CurrentPresetIndex = found
    local id = -1
    local mid = -1
    local u = ""
    --for i=1, MH_UnitTokensLen do
    for k,v in pairs(MH_Vars.Presets[MH_CurrentPresetIndex].Morphs) do
        --u = MH_UnitTokens[k]
        id = v.ID
        mid = v.MID
        DEFAULT_CHAT_FRAME:AddMessage(k)

        if (UnitExists(k) or MH_PRESETMODE) then

            if id ~= nil then
                if not MH_PRESETMODE then
                    SetUnitDisplayID(k, id)
                    MH_AMSendMorph(k, MH_AMMORPHPLAYER, id)
                    DEFAULT_CHAT_FRAME:AddMessage(format("Morphed %s to %s", u, id))
                end
                if MH_CurrentMorphs.Morphs[k] == nil then MH_CurrentMorphs.Morphs[k] = {} end
                MH_CurrentMorphs.Morphs[k].ID = id
                MH_CurrentMorphs.Dirty=true
                --getglobal(MH_MorphButtons[k]):SetChecked(1)
            end
            if mid ~= nil then
                if not MH_PRESETMODE then
                    SetUnitMountDisplayID(k, mid)
                    MH_AMSendMorph(k, MH_AMMORPHMOUNT, id)
                    DEFAULT_CHAT_FRAME:AddMessage(format("Morphed %s's mount to %s", u, mid))
                end
                if MH_CurrentMorphs.Morphs[k] == nil then MH_CurrentMorphs.Morphs[k] = {} end
                MH_CurrentMorphs.Morphs[k].MID = mid
                MH_CurrentMorphs.Dirty=true
                -- TODO: Check the checked status of buttons after applying presets...?
                --getglobal(MH_MorphMountButtons[k]):SetChecked(1)
            end
        end
    end
    if MH_DisplayList:IsShown() then
        MH_DisplayList_UpdateButtons()
    end
end

--Swap Functions

function MH_DisplayList_SwapFrame_NewIDEditBox_OnEnter()
    MH_DisplayList_SwapFrame_NewIDEditBox:ClearFocus()
    MH_NEWIDFOCUS = false
    MH_DisplayList_UpdateButtons()
end

function MH_DisplayList_SwapFrame_OldIDEditBox_OnEnter()
    MH_DisplayList_SwapFrame_OldIDEditBox:ClearFocus()
    MH_OLDIDFOCUS = false
    MH_DisplayList_UpdateButtons()
end

function MH_DisplayList_IDSwapsButton_OnClick()
    local newID = MH_DisplayList_SwapFrame_NewIDEditBox:GetText()
    local oldID = MH_DisplayList_SwapFrame_OldIDEditBox:GetText()
    MH_AMSendSwap(MH_AMSWAPID, oldID, newID)
    RemapDisplayID(oldID, newID)
end

function MH_DisplayList_MountIDSwapsButton_OnClick()
    local newID = MH_DisplayList_SwapFrame_NewIDEditBox:GetText()
    local oldID = MH_DisplayList_SwapFrame_OldIDEditBox:GetText()
    MH_AMSendSwap(MH_AMSWAPMID, oldID, newID)
    RemapMountDisplayID(oldID, newID)
end

function MH_DisplayList_SwapFrame_SwapIDsButton_OnClick()
    local newID = MH_DisplayList_SwapFrame_NewIDEditBox:GetText()
    local oldID = MH_DisplayList_SwapFrame_OldIDEditBox:GetText()

    MH_DisplayList_SwapFrame_NewIDEditBox:SetText(oldID)
    MH_DisplayList_SwapFrame_OldIDEditBox:SetText(newID)

    MH_DisplayList_SwapFrame_NewIDEditBox:ClearFocus()
    MH_DisplayList_SwapFrame_OldIDEditBox:ClearFocus()
end

--AM Protocol: GUID:MOUNT/PLAYER:DISPALYID
--EG: 1:0:2001 -- player morph
--EG: 1:1:2001 -- mount morph
-- MODES: 
-- 0 : player morph
-- 1 : mount morph
-- 2 : id remap
-- 3 : mid remap
-- 4 : FP Morph
function MH_AMSendMorph(token, m, id)
    if not MH_Vars.MsgSend then return end
    if UnitPlayerOrPetInRaid("player") then
        channel = "RAID"
    elseif GetNumPartyMembers() > 0 then 
        channel = "PARTY"
    else
        return
    end
    local msg = format("%s:%s:%s", GetUnitGUID(token), m, id)
    SendAddonMessage(MH_AMPREFIX, msg, channel)
end

-- oops two different protocols whatever
-- mode:id1:id2
function MH_AMSendSwap(m, id, sid)
    if not MH_Vars.MsgSend then return end
    local channel
    if UnitPlayerOrPetInRaid("player") then
        channel = "RAID"
    elseif GetNumPartyMembers() > 0 then 
        channel = "PARTY"
    else
        return
    end

    local msg = format("%s:%s:%s", m, id, sid)
    SendAddonMessage(MH_AMPREFIX, msg, channel)
end

--TT_QueuedMount = 0
--TT_QueuedToken = ""
TT_QueuedMounts = {}
function MH_MountMorphTimer(timer)
    for k,v in TT_QueuedMounts do     
        local cinfo = C_CreatureInfo.GetCreatureInfoByID(v)
        if cinfo ~= nil then
            SetUnitMountDisplayID(k, cinfo.displayID)
            TT_QueuedMounts[k] = nil
        end
    end
    if next(TT_QueuedMounts) == nil then
        UnitXP("timer", "disarm",timer)
    end
end

function MH_AMHandler(arg2, arg3, arg4)
    --DEFAULT_CHAT_FRAME:AddMessage(arg2)
    local parsed_args = {}
    local a = string.gfind(arg2, '([^:]+)') --parses info after :
    for i in a do --need to translate it to a table, a is a function
        table.insert(parsed_args,i)
        --TubTalents_Out(i)
    end 
    local len = getn(parsed_args)
    if len == 3 then
        if tonumber(parsed_args[1]) == MH_AMSWAPID then
            RemapDisplayID(tonumber(parsed_args[2]), tonumber(parsed_args[3]))
        elseif tonumber(parsed_args[1]) == MH_AMSWAPMID then
            RemapMountDisplayID(tonumber(parsed_args[2]), tonumber(parsed_args[3]))
        else
            --find the unit token...
            local token = nil
            if GetUnitGUID("player") == parsed_args[1] then
                token = "player"
            elseif UnitPlayerOrPetInRaid("player") then
                for i=1, MH_MAXRAID do
                    if UnitExists("raid"..i) and GetUnitGUID("raid"..i) == parsed_args[1] then
                        token = "raid"..i
                        break
                    end
                end
            elseif GetNumPartyMembers() > 0 then
                for i=1, MH_MAXGROUP do
                    if UnitExists("party"..i) and GetUnitGUID("party"..i) == parsed_args[1] then
                        token = "party"..i
                        break
                    end
                end
            end
            --store then morph
            if token ~= nil then
                local tindex
                for k, v in pairs(MH_UnitTokens) do
                    if token == v then
                        tindex = k
                    end
                end
                DEFAULT_CHAT_FRAME:AddMessage(parsed_args[2])
                if tonumber(parsed_args[2]) == MH_AMMORPHPLAYER then
                    if tonumber(parsed_args[3]) == -1 then
                        MH_CurrentMorphs.Morphs[token].ID = nil
                        if MH_CurrentMorphs.Morphs[token].MID == nil then MH_CurrentMorphs.Morphs[token] = nil end
                        SetUnitDisplayID(token, 0)
                    else
                        if MH_CurrentMorphs.Morphs[token] == nil then MH_CurrentMorphs.Morphs[token] = {} end
                        MH_CurrentMorphs.Morphs[token].ID = tonumber(parsed_args[3])
                        MH_CurrentMorphs.Dirty=true
                        SetUnitDisplayID(token, tonumber(parsed_args[3]))
                    end
                elseif tonumber(parsed_args[2]) == MH_AMMORPHMOUNT then
                    if tonumber(parsed_args[3]) == -1 then
                        MH_CurrentMorphs.Morphs[token].MID = nil
                        if MH_CurrentMorphs.Morphs[token].ID == nil then MH_CurrentMorphs.Morphs[token] = nil end
                        SetUnitMountDisplayID(token, tonumber(parsed_args[3]))
                    else
                        if MH_CurrentMorphs.Morphs[token] == nil then MH_CurrentMorphs.Morphs[token] = {} end
                        MH_CurrentMorphs.Morphs[token].MID = tonumber(parsed_args[3])
                        MH_CurrentMorphs.Dirty=true
                        SetUnitMountDisplayID(token, tonumber(parsed_args[3]))
                    end
                elseif tonumber(parsed_args[2] == MH_AMFPMORPH) then
                    SetUnitMountDisplayID(token, tonumber(parsed_args[3]))
                else
                    DEFAULT_CHAT_FRAME:AddMessage("MH: Addon Message failure2")
                end
            end
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("MH: Addon Message failure1")
    end
end