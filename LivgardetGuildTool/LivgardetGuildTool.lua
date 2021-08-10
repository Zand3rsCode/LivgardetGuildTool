LivgardetGuildTool = {
    db = nil,
    name = "LivgardetGuildTool",
    addonName = "Livgardet Guild Tool",
    displayName = "|cea4e49Livgardet|r |c40c0f0Guild Tool|r",
    panel = nil,
    chatIcon = nil
}

local LG
local IconDiscord = "|t25:25:esoui/art/help/help_tabicon_cs_up.dds|t"
local IconWeb= "|t25:25:esoui/art/tutorial/help_tabicon_tutorial_up.dds|t"
local IconOpt= "|t25:25:esoui/art/chatwindow/chat_options_up.dds|t"
local IconGrpTool = "|t25:25:esoui/art/mainmenu/menubar_group_up.dds|t"
local IconGHouse = "|t25:25:esoui/art/mainmenu/menubar_guilds_up.dds|t"

local defaults = { 
    showChatIcon = true,
    improveDialog = false,
    dontReadBooks = false,
    nonstopHarvest = false, 
    hideTopBar = false, 
    NoCostTravel = false, 
}

-- FAST TRAVEL CONFIRMATION.
local function fasterTraveling()
    local function ShowDialog_NoCostTravel(name, data) 
        if name == "FAST_TRAVEL_CONFIRM" or name == "RECALL_CONFIRM" then 
            if LG.NoCostTravel then 
                FastTravelToNode(data.nodeIndex) 
                ZO_Dialogs_ReleaseDialog("FAST_TRAVEL_CONFIRM") 
                return true 
                end 
            end 
        end 
    ZO_PreHook("ZO_Dialogs_ShowDialog", ShowDialog_NoCostTravel)
end

-- Hide The Compass
local function hidetop()
    if LG.hideTopBar then 
        ZO_Compass:SetAlpha(0) 
        ZO_CompassContainer:SetAlpha(0)
        ZO_CompassFrameCenter:SetHidden(true) 
        ZO_CompassFrameLeft:SetHidden(true) 
        ZO_CompassFrameRight:SetHidden(true)
    else
        ZO_Compass:SetAlpha(1) 
        ZO_CompassContainer:SetAlpha(1) 
        ZO_CompassFrameCenter:SetHidden(false) 
        ZO_CompassFrameLeft:SetHidden(false) 
        ZO_CompassFrameRight:SetHidden(false) 
    end
end

-- harvest no interrupt
local function DontInterruptHarvesting()
	local function Show_Hook(self)
		if LG.nonstopHarvest then
			EndPendingInteraction()
			self:OnShown()
			return true
		end
	end
	ZO_PreHook(END_IN_WORLD_INTERACTIONS_FRAGMENT, "Show", Show_Hook)
end

-- Removes the book from view when reading --
local function DontReadBooks()
	local function OnShowBook(eventCode, title, body, medium, showTitle)
		local willShow = LORE_READER:Show(title, body, medium, showTitle)
		if willShow then
			PlaySound(LORE_READER.OpenSound)
		else
			EndInteraction(INTERACTION_BOOK)
		end
	end
	local function OnDontShowBook()
		EndInteraction(INTERACTION_BOOK)
	end
	if LG.dontReadBooks then
		LORE_READER.control:UnregisterForEvent(EVENT_SHOW_BOOK)
		LORE_READER.control:RegisterForEvent(EVENT_SHOW_BOOK, OnDontShowBook)
	else
		LORE_READER.control:UnregisterForEvent(EVENT_SHOW_BOOK)
		LORE_READER.control:RegisterForEvent(EVENT_SHOW_BOOK, OnShowBook)
	end
end


-- Removes the Mail delete confirmation if mail is empty. Does not remove attachments. | /esoui/ingame/mail/keyboard/mailinbox_keyboard.lua
ZO_PreHook(MAIL_INBOX, "Delete", function(self)
	if LivgardetGuildTool.db.skipMailDeletionPrompt and self.mailId and self:IsMailDeletable() then
		local numAttachments, attachedMoney = GetMailAttachmentInfo(self.mailId)
		if numAttachments == 0 and attachedMoney == 0 then
			self:ConfirmDelete(self.mailId)
			return true
		end
	end
end)

-- Removes the Crafting Improvement confirm box --
local function ImproveDialog()
        local function ShowDialog_improve(name, data)
		if name == "CONFIRM_IMPROVE_ITEM" or name == "CONFIRM_IMPROVE_LOCKED_ITEM" or name == "GAMEPAD_CONFIRM_IMPROVE_LOCKED_ITEM" then
			if LG.improveDialog then
				ImproveSmithingItem(data.bagId, data.slotIndex, data.boostersToApply)
				return true
			end
		end
	end
	ZO_PreHook("ZO_Dialogs_ShowDialog", ShowDialog_improve)
end

-- Guild Invite from chat function
local function AddPlayerToGuild(name, guildid, guildname) 
    d(zo_strformat(GINV_GUILDINVITED, name, guildname)) 
    GuildInvite(guildid, name) 
end 
local CreateChatMenuItem = CHAT_SYSTEM.ShowPlayerContextMenu 
CHAT_SYSTEM.ShowPlayerContextMenu = function(self, name, rawName, ...) 
    CreateChatMenuItem(self, name, rawName, ...) 
    for i = 1, GetNumGuilds() do 
        local gid = GetGuildId(i) 
        if DoesPlayerHaveGuildPermission(gid, GUILD_PERMISSION_INVITE) then 
            local guildName = GetGuildName(gid) 
            AddMenuItem(zo_strformat(GINV_GUILDINVITE, guildName), function() AddPlayerToGuild(name, gid, guildName) end) 
        end 
    end 
    if ZO_Menu_GetNumMenuItems() > 0 then 
        ShowMenu() 
    end 
end

-- Initialize the menu stuff.
function LivgardetGuildTool:InitializeMenu()
    local LAM2 = LibAddonMenu2

    local panelData = {
        type = "panel",
        name = self.addonName,
        displayName = self.displayName,
        author = "Zand3rs",
        version = "1.5",
        slashCommand = "/livgardet",
        website = "https://www.esoui.com",
        registerForRefresh = true,
        registerForDefaults = true,
    }

-- Options for the settings page. 
    local optionsTable = {
        { 
            type = "header", name = GetString(LIVGARDET_SETTINGS_HEADER_GENERAL), width = "half", 
        },
        { -- SHOW OR HIDE CHAT ICON TO OPEN MENU
            type = "checkbox", name = GetString(LIVGARDET_SETTINGS_CHAT_ICON), 
            tooltip = GetString(LIVGARDET_SETTINGS_CHAT_ICON_TT), 
            getFunc = function() return self.db.showChatIcon end,
            setFunc = function( show ) self.db.showChatIcon = show self:ShowChatIcon(show) end,
        },
        {
            type = 'header', name = 'Quality of life settings', width = 'full',
        },
        { -- SKIP CONFIRM PROMPT WHEN ERASING MAIL
            type = "checkbox",
            name = GetString(LIVGARDET_SETTINGS_MAIL_DELETION),
            tooltip = GetString(LIVGARDET_SETTINGS_MAIL_DELETION_TT),
            getFunc = function() return self.db.skipMailDeletionPrompt end,
            setFunc = function( skip ) self.db.skipMailDeletionPrompt = skip end,
        },
        { -- HIDE DIALOG WHEN IMPROVING ITEMS
			type = "checkbox",
			name = GetString(LIVGARDET_SETTINGS_CONFIRM_IMPROVE),
            tooltip = GetString(LIVGARDET_SETTINGS_CONFIRM_IMPROVE_TT),
			getFunc = function() return LG.improveDialog end,
			setFunc = function(value) LG.improveDialog = value end,
		},
        { -- HIDE BOOK WHEN READING
			type = "checkbox",
			name = GetString(LIVGARDET_SETTINGS_CONFIRM_NOBOOK),
            tooltip = GetString(LIVGARDET_SETTINGS_CONFIRM_NOBOOK_TT),
			getFunc = function() return LG.dontReadBooks end,
			setFunc = function(value) LG.dontReadBooks = value DontReadBooks() end,
		},

        { -- HIDE COMPASS
            type = 'checkbox',
            name = GetString(LIVGARDET_SETTINGS_COMPASS),
            tooltip = GetString(LIVGARDET_SETTINGS_COMPASS_TT),
            getFunc = function() return LG.hideTopBar end,
            setFunc = function(value) LG.hideTopBar = value; hidetop() end,
            default = hideTopBar,
         },

         { -- NO COST TRAVEL
            type = 'checkbox',
            name = GetString(LIVGARDET_SETTINGS_CONFIRM_FAST_TRAVEL),
            tooltip = GetString(LIVGARDET_SETTINGS_CONFIRM_FAST_TRAVEL_TT),
            getFunc = function() return LG.NoCostTravel end,
            setFunc = function(value) LG.NoCostTravel = value end,
         }, 
    } 
    self.panel = LAM2:RegisterAddonPanel(self.name .. "Options", panelData)
    LAM2:RegisterOptionControls(self.name .. "Options", optionsTable)
end

-- Chat icon Picture and menu configuration
function LivgardetGuildTool:InitializeChatIcon() 
    local LivgHall = WINDOW_MANAGER:CreateControl("LivgardetGuildTool1", ZO_ChatWindow, CT_BUTTON) 
    LivgHall:SetDimensions(22, 22)
    LivgHall:SetAnchor(TOPLEFT, ZO_ChatOptionsSectionLabel, TOPLEFT, 200, 13)
    LivgHall:SetHandler("OnMouseEnter", function(control) 
        InitializeTooltip(InformationTooltip, control) 
        SetTooltipText(InformationTooltip, "Livgardet", 1, 1, 1, LEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true) 
    end) 
    LivgHall:SetHandler("OnMouseExit", function(_) ClearTooltip(InformationTooltip) 
    end)
    LivgHall:SetNormalTexture("LivgardetGuildTool/imgs/livgardeteso.dds")
    LivgHall:SetPressedTexture("LivgardetGuildTool/imgs/livgardeteso.dds")
    LivgHall:SetMouseOverTexture("LivgardetGuildTool/imgs/livgardeteso.dds")
    LivgHall:SetHandler("OnClicked", function(...) 
        local entries = { 
            { 
                label = GetString(LIVGARDET_PORT_GUILDHOUSE), 
                callback = function() 
                    LivgardetGuildTool:PortToHouse("@Nsaje", 66, GetString(LIVGARDET_CHAT_GUILDHOUSE)) 
                end, 
            }, 
            {
                label = "-",
            },
            {
                label = GetString(LIVGARDET_PORT_PARSEHOUSE),
                callback = function()
                    LivgardetGuildTool:PortToHouse("@Zand3rs", 47, GetString(LIVGARDET_CHAT_PARSEHOUSE))
                end,
            },
            {
                label = "-",
            },
            {
                label = GetString(LIVGARDET_PORT_SECRETHOUSE),
                callback = function()
                    Livgardet:PortToHouse("", 70, GetString(LIVGARDET_PORT_SECRETHOUSE))
                end,
            }
        }
        local entries2 = {
            {
                label = GetString(LIVGARDET_GUILD_MESSAGE),
                callback = function() 
                    CHAT_SYSTEM:StartTextEntry("/zone Ett av dom största och mest aktiva svenska gillen i Elderscrolls online |H1:guild:664190|hLivgardet|h har öppna platser och vill fylla dom med nya trevliga, glada spelare. Häng på och upplev vad vi har att erbjuda. Vi kör veteran Trials, normal Trials, tävlingar, PVP, och annat kul. Vi har aktiva mentorer, crafters, och mer för att hjälpa nya.")
                end,
            }
        }
        ClearMenu()
        AddCustomSubMenuItem(IconGHouse..GetString(LIVGARDET_GUILD_HOUSES), entries, normalColor)
        AddCustomMenuItem("-", function()
        end) 
        AddCustomSubMenuItem(IconGrpTool..GetString(LIVGARDET_GUILD_TOOLS), entries2, normalColor)
        AddCustomMenuItem("-", function()
        end)
        AddCustomMenuItem(IconDiscord..GetString(LIVGARDET_OUR_DISCORD), function() 
            RequestOpenUnsafeURL("https://discord.gg/xNjWbaRjn3")
        end)
        AddCustomMenuItem("-", function()
        end)
        AddCustomMenuItem(IconWeb..GetString(LIVGARDET_OUR_WEBSITE), function()
            RequestOpenUnsafeURL("https://www.livgardet.se")
        end)
        AddCustomMenuItem("-", function()
        end)

-- COMMENTED OUT THE OPEN SETTINGS CHOICE BECAUSE IT BUGS OUT FOR NOW !!!
--      AddCustomMenuItem(IconOpt..GetString(LIVGARDET_BUTTON_SETTINGS), function() 
--          LAM2:OpenToPanel(self.panel)
--      end)
        ShowMenu()
    end)
    self.chatIcon = LivgHall
end
function LivgardetGuildTool:PortToHouse(name, houseId, message)
        if (GetDisplayName() == name) then
            RequestJumpToHouse(houseId)
        else
            JumpToSpecificHouse(name, houseId)
        end
        d(message)
    end
    function LivgardetGuildTool:ShowChatIcon(show)   
    self.chatIcon:SetHidden(not show)
end
function LivgardetGuildTool:Initialize()
    self.db = ZO_SavedVars:NewAccountWide("LivgardetSavedVars", 1, nil, self.defaults)
--    LG = ZO_SavedVars:NewAccountWide("LivgardetSavedVars", 1, defaults) 
    self:InitializeMenu()
    self:InitializeChatIcon()
    self:ShowChatIcon(self.db.showChatIcon)
end

-- Do i really need both if i reqrite everything? Ofcourse not  :)
function LivgardetGuildTool.OnAddOnLoaded(_, addon)
    if addon == LivgardetGuildTool.name then
        EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, event) 
        LG = ZO_SavedVars:NewAccountWide("LivgardetSavedVars", 1, defaults) 
        ImproveDialog()
        DontReadBooks() 
        DontInterruptHarvesting() 
        hidetop() 
        fasterTraveling()

        LivgardetGuildTool:Initialize()
    end
end
EVENT_MANAGER:RegisterForEvent(LivgardetGuildTool.name, EVENT_ADD_ON_LOADED, LivgardetGuildTool.OnAddOnLoaded)