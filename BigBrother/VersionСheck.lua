local IsInGuild = IsInGuild
local IsInInstance = IsInInstance
local SendAddonMessage = SendAddonMessage
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local CreateFrame = CreateFrame

local myname = UnitName("player")
versionBB = GetAddOnMetadata("BigBrother", "Version")

local spamt = 0
local timeneedtospam = 180
do
    local SendMessageWaitingBB
    local SendRecieveGroupSizeBB = 0
    function SendMessage_BB()
        if GetNumRaidMembers() > 1 then
            local _, instanceType = IsInInstance()
            if instanceType == "pvp" then
                SendAddonMessage("BBVC", versionBB, "BATTLEGROUND")
            else
                SendAddonMessage("BBVC", versionBB, "RAID")
            end
        elseif GetNumPartyMembers() > 0 then
            SendAddonMessage("BBVC", versionBB, "PARTY")
        elseif IsInGuild() then
            SendAddonMessage("BBVC", versionBB, "GUILD")
        end
        SendMessageWaitingBB = nil
    end
    
    local function SendRecieve_BB(_, event, prefix, message, _, sender)
        if event == "CHAT_MSG_ADDON" then
            argtime = time()
            if prefix ~= "BBVC" then return end
            if not sender or sender == myname then return end

            local ver = tonumber(versionBB)
            message = tonumber(message)

            local  timenow = argtime
            if message and (message > ver) then 
                if timenow - spamt >= timeneedtospam then              
                    print("|cff1784d1".."BigBrother for Sirus".."|r".." (".."|cffff0000"..ver.."|r"..") устарел. Вы можете загрузить последнюю версию (".."|cff00ff00"..message.."|r"..") из ".."|cffffcc00".."https://github.com/Fallafell/BigBrother-Sirus".."|r")
                    spamt = time()
                end
            end
        end

        if event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
            local numRaid = GetNumRaidMembers()
            local num = numRaid > 0 and numRaid or (GetNumPartyMembers() + 1)
            if num ~= SendRecieveGroupSizeBB then
                if num > 1 and num > SendRecieveGroupSizeBB then
                    if not SendMessageWaitingBB then
                        SendMessage_BB()
                    end
                end
                SendRecieveGroupSizeBB = num
            end
        elseif event == "PLAYER_ENTERING_WORLD" then
                    if not SendMessageWaitingBB then
                        SendMessage_BB()
                    end

        end
    end
           
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_ADDON")
    f:RegisterEvent("RAID_ROSTER_UPDATE")
    f:RegisterEvent("PARTY_MEMBERS_CHANGED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", SendRecieve_BB)
end