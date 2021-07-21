LivgardetGuildTool = {
    db = nil,
    name = "LivgardetGuildTool",
    addonName = "Livgardet Guild Tool",
    displayName = "|cea4e49Livgardet|r |c40c0f0Guild Tool|r",
    defaults = {
        showChatIcon = true,
    },
    panel = nil,
    chatIcon = nil
}

local IconDiscord = "|t25:25:esoui/art/help/help_tabicon_cs_up.dds|t"
local IconWeb= "|t25:25:esoui/art/tutorial/help_tabicon_tutorial_up.dds|t"
local IconOpt= "|t25:25:esoui/art/chatwindow/chat_options_up.dds|t"
local IconGrpTool = "|t25:25:esoui/art/mainmenu/menubar_group_up.dds|t"
local IconGHouse = "|t25:25:esoui/art/mainmenu/menubar_guilds_up.dds|t"

function LivgardetGuildTool:InitializeMenu()
    local LAM2 = LibAddonMenu2

    local panelData = {
        type = "panel",
        name = self.addonName,
        displayName = self.displayName,
        author = "Zand3rs",
        version = "1.0",
        slashCommand = "/livgardet",
        website = "https://www.esoui.com",
        registerForRefresh = true,
        registerForDefaults = true,
    }

    local optionsTable = {
        {
            type = "header",
            name = GetString(LIVGARDET_SETTINGS_HEADER_GENERAL),
            width = "full",
        },
        {
            type = "checkbox",
            name = GetString(LIVGARDET_SETTINGS_CHAT_ICON),
            getFunc = function() return self.db.showChatIcon end,
            setFunc = function( show )
                self.db.showChatIcon = show
                self:ShowChatIcon(show)
            end,
        },
        {
            type = 'header',
            name = 'MAil Settings',
            width = 'full',
        },
        {
            type = 'description',
            text = 'The following setting will disable the confirmation box when deleting empty messages. If mail contain attachments they will not be removed.',
            width = 'full',
        },
        {
            type = "checkbox",
            name = GetString(LIVGARDET_SETTINGS_MAIL_DELETION),
            getFunc = function() return self.db.skipMailDeletionPrompt end,
            setFunc = function( skip )
                self.db.skipMailDeletionPrompt = skip
            end,
        },
 

    }

    self.panel = LAM2:RegisterAddonPanel(self.name .. "Options", panelData)
    LAM2:RegisterOptionControls(self.name .. "Options", optionsTable)
end

function LivgardetGuildTool:InitializeChatIcon()
    local ptoGHall = WINDOW_MANAGER:CreateControl("LivgardetGuildTool1", ZO_ChatWindow, CT_BUTTON)
    ptoGHall:SetDimensions(22, 22)
    ptoGHall:SetAnchor(TOPLEFT, ZO_ChatOptionsSectionLabel, TOPRIGHT, -100, 10)
    ptoGHall:SetHandler("OnMouseEnter", function(control)
        InitializeTooltip(InformationTooltip, control)
        SetTooltipText(InformationTooltip, "Livgardet", 1, 1, 1, LEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
    end)
    ptoGHall:SetHandler("OnMouseExit", function(_)
        ClearTooltip(InformationTooltip)
    end)
    ptoGHall:SetNormalTexture("LivgardetGuildTool/imgs/livgardeteso.dds")
    ptoGHall:SetPressedTexture("LivgardetGuildTool/imgs/livgardeteso.dds")
    ptoGHall:SetMouseOverTexture("LivgardetGuildTool/imgs/livgardeteso.dds")

    ptoGHall:SetHandler("OnClicked", function(...)
        local entries = {
            {
                label = GetString(LIVGARDET_PORT_GUILDHOUSE),
                callback = function()
                    LivgardetGuildTool:PortToHouse("@Nsaje", 71, GetString(LIVGARDET_CHAT_GUILDHOUSE))

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
        AddCustomMenuItem(IconOpt..GetString(LIVGARDET_BUTTON_SETTINGS), function()
            LAM2:OpenToPanel(self.panel)
        end)
        ShowMenu()
    end)
    self.chatIcon = ptoGHall
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

    self:InitializeMenu()
    self:InitializeChatIcon()

    self:ShowChatIcon(self.db.showChatIcon)
end

function LivgardetGuildTool.OnAddOnLoaded(_, addon)
    if addon == LivgardetGuildTool.name then
        LivgardetGuildTool:Initialize()
    end
end

EVENT_MANAGER:RegisterForEvent(LivgardetGuildTool.name, EVENT_ADD_ON_LOADED, LivgardetGuildTool.OnAddOnLoaded)


-- Guild Inviter

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

--hejsan mamma bajs