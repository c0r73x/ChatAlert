-- ChatAlert.lua
-- Copyright (C) 2021 c0r73x <c0r73x@gmail.com>
--
-- Distributed under terms of the MIT license.
--

ChatAlert = {}
ChatAlert.name = "ChatAlert"
ChatAlert.short_name = "CA"

local ChannelInfo = ZO_ChatSystem_GetChannelInfo()

local function GetChannelName(channelId)
    local channelInfo = ChannelInfo[channelId]
    if channelInfo then
        return channelInfo.dynamicName and
            GetDynamicChatChannelName(channelInfo.id) or
            channelInfo.name
    end
end

local function CreateChannelLink(channelInfo, overrideName)
    local channelName = overrideName or GetChannelName(channelInfo.id)
    return string.format("|cff00ff|H1:channel:%s|h[%s]:|h|r", channelInfo.id, channelName)
end

local function isWordFoundInString(word, str)
    local w = word:lower()
    local s = str:lower()

    return select(2,s:gsub('^' .. w .. '%W+','')) +
        select(2,s:gsub('%W+' .. w .. '$','')) +
        select(2,s:gsub('^' .. w .. '$','')) +
        select(2,s:gsub('%W+' .. w .. '%W+','')) > 0
end

local function strsplit(s, delimiter)
    local result = {}

    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end

    return result
end

function ChatAlert:Initialize()
    self.saveData = self.LoadSettings()
    self.currentPlayer = GetDisplayName()

    EVENT_MANAGER:RegisterForEvent(
        self.name,
        EVENT_CHAT_MESSAGE_CHANNEL,
        self.OnNewChatMessage
    )
end

function ChatAlert.OnNewChatMessage(
    event,
    channelType,
    fromName,
    text,
    isCustomerService,
    fromDisplayName)
    if channelType == CHAT_CHANNEL_WHISPER then
        return
    end

    if fromDisplayName == ChatAlert.currentPlayer then
        -- d("Why are you talking to yourself " .. fromDisplayName .. "?")
        return
    end

    local found = false

    for _, alert in ipairs(ChatAlert.saveData.alerts) do
        if alert.type == 'Word' then
            local words = strsplit(alert.filter, " ")
            for _, word in pairs(words) do
                if word then
                    -- d("Checking for '" .. word .. "'")
                    found = isWordFoundInString(word, text)
                end

                if found then
                    break
                end
            end
        end

        if found then
            break
        end
    end

    if not found then
        return
    end

    local channelInfo = ChannelInfo[channelType]
    if channelInfo and channelInfo.format then
        local r, g, b = ZO_ChatSystem_GetCategoryColorFromChannel(channelType)

        local msg = ("%s |c%02x%02x%02x%s|r"):format(
            CreateChannelLink(channelInfo),
            r * 255, g * 255, b * 255,
            text
        )

        CHAT_ROUTER:FormatAndAddChatMessage(
            EVENT_CHAT_MESSAGE_CHANNEL,
            CHAT_CHANNEL_WHISPER,
            fromName,
            msg,
            false,
            fromDisplayName
        )
    end
end

function ChatAlert.OnAddOnLoaded(event, addonName)
    if addonName == ChatAlert.name then
        ChatAlert:Initialize()
    end
end

EVENT_MANAGER:RegisterForEvent(
    ChatAlert.name,
    EVENT_ADD_ON_LOADED,
    ChatAlert.OnAddOnLoaded
)
