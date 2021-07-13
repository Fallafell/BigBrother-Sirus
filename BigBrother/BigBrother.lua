--[[
BigBrother
Оригинальный концепт мода: Cryect
В настоящие время поддерживается: Фалафель
]]
local addonName, vars = ...
local L = vars.L
if AceLibrary:HasInstance("FuBarPlugin-2.0") then
	BigBrother = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0","AceDB-2.0","AceEvent-2.0","FuBarPlugin-2.0")
else
	BigBrother = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0","AceDB-2.0","AceEvent-2.0")
end

local addon = BigBrother
addon.vars = vars

local bit, math, date, string, select, table, time, tonumber, unpack, wipe, pairs, ipairs = 
      bit, math, date, string, select, table, time, tonumber, unpack, wipe, pairs, ipairs
local IsInInstance, UnitName, UnitBuff, UnitDebuff, UnitExists, UnitGUID, GetSpellLink, GetUnitName, GetPlayerInfoByGUID, GetRealZoneText, GetNumRaidMembers, GetNumPartyMembers, IsInGuild, GetTime, UnitGroupRolesAssigned, GetPartyAssignment = 
      IsInInstance, UnitName, UnitBuff, UnitDebuff, UnitExists, UnitGUID, GetSpellLink, GetUnitName, GetPlayerInfoByGUID, GetRealZoneText, GetNumRaidMembers, GetNumPartyMembers, IsInGuild, GetTime, UnitGroupRolesAssigned, GetPartyAssignment
local COMBATLOG_OBJECT_RAIDTARGET_MASK, COMBATLOG_OBJECT_TYPE_PLAYER, COMBATLOG_OBJECT_TYPE_NPC, COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_TYPE_GUARDIAN, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_REACTION_HOSTILE, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER = 
      COMBATLOG_OBJECT_RAIDTARGET_MASK, COMBATLOG_OBJECT_TYPE_PLAYER, COMBATLOG_OBJECT_TYPE_NPC, COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_TYPE_GUARDIAN, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_REACTION_HOSTILE, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER

local AceEvent = AceLibrary("AceEvent-2.0")
local RL = AceLibrary("Roster-2.1")

local function convertIDstoNames(spellIDs) 
  local result = {}
  local uiversion = select(4,GetBuildInfo())
  local ignoreMissing = {
    [60210] = uiversion >= 40000, -- Freezing Arrow Effect, removed 4.x (replaced with Freezing Trap)
    [59671] = uiversion >= 40000, -- Challenging Howl (Warlock), removed 4.x
  }
  for _, v in ipairs(spellIDs) do
	local spellName = GetSpellInfo(v)
	if (not spellName) then
	  if not ignoreMissing[v] then BigBrother:Print("MISSING SPELLID: "..v) end
	else
	  result[spellName] = true
	end
  end
  return result
end

-- Create a set out of the CC spell ID
local ccSpellNames = convertIDstoNames(vars.SpellData.ccspells)
local rezSpellNames = convertIDstoNames(vars.SpellData.rezSpells)
local brezSpellNames = convertIDstoNames(vars.SpellData.brezSpells)
local brezSpellNamesTwo = convertIDstoNames(vars.SpellData.brezSpellsTwo)
for k,_ in pairs(brezSpellNames) do rezSpellNames[k] = nil end
local tauntSpellNames = convertIDstoNames(vars.SpellData.tauntSpells)
local aoetauntSpellNames = convertIDstoNames(vars.SpellData.aoetauntSpells)
for k,_ in pairs(aoetauntSpellNames) do tauntSpellNames[k] = nil end

local color = "|cffff8040%s|r"
local outdoor_bg = {}

-- FuBar stuff
addon.name = "BigBrother"
addon.hasIcon = true
addon.hasNoColor = true
addon.clickableTooltip = false
addon.independentProfile = true
addon.cannotDetachTooltip = true
addon.hideWithoutStandby = true

function addon:OnClick(button)
	self:ToggleBuffWindow()
end

function addon:OnTextUpdate()
	self:SetText("BigBrother")
  local f = addon.minimapFrame; 
  if f then -- ticket #14
    f.SetFrameStrata(f,"MEDIUM") -- ensure the minimap icon isnt covered by others 	
  end
end

-- AceDB stuff
addon:RegisterDB("BigBrotherDB")
addon:RegisterDefaults("profile", {
  PolyBreak = false,
  Misdirect = false,
  CombatRez = true,
  NonCombatRez = false,
  Groups = {true, true, true, true, true, false, false, false},
  PolyOut = {true, true, false, false, false, false, false},
  GroupOnly = true,
  ReadyCheckMine = true,
  ReadyCheckOther = true,
  ReadyCheckToSelf = false,  
  ReadyCheckToRaid = false,
  ReadyCheckBuffWinMine = false,
  ReadyCheckBuffWinOther = false,
  BuffWindowCombatClose = false,
  CheckFlasks = true,
  CheckElixirs = true,
  CheckFood = true,
  Taunt = false,
  AoeTaunt = false,
  Dispel = false,
  Mana = false,
  Interrupt = false,
  Intervention = false,
  Sacredsacrifice = false,
  Painsupression = false,
  Strangulate = false,
  Fish = false,
  Mail = false,
  Jeeves = false,
  Heroism = false,
  Salva = false,
  Protection = false,
  Freedom = false,
  Sacrifice = false,
  Soulgem = true,
  Firalar = false,
  Arcanesign = false,
  Auramaster = false,
  Stolen = false,
  Megoslack = true,
  Shackleseal = false,
  Hysteria = false,
  Divinehymn = false,
  Removed = false,
  SacrificeRemoved = false,
  ProtectionRemoved = false,
  FreedomRemoved = false,
  SalvaRemoved = false,
  HysteriaRemoved = false,
  PainsupressionRemoved = false,
  Theimmutabilityofice = false,
  AntiMagicCarapace = false,
  Vampireblood = false,
  Antimagiczone = false,
  Indestructiblearmor = false,
  Blinddefense = false,
  Nostepback = false,
  Shieldblock = false,
  Negation = false,
  Divineprotection = false,
  Oakleather = false,
  Survival = false,
  Frenzy = false,
  FangofSindragosa = false,
  Symbioteworm = false,
  Guardianspirit = false,
  GuardianspiritRemoved = false,
  Toyrailroad = false,
})

-- ACE options menu
local options = {
  type = 'group',
  handler = BigBrother,
  args = {
    flaskcheck = {
      name = L["Flask Check"],
      desc = L["Checks for flasks, elixirs and food buffs."],
      type = 'group',
      args = {
        self = {
          name = L["Self"],
          desc = L["Reports result only to yourself."],
          type = 'execute',
          func = "FlaskCheck",
          passValue = "SELF",
        },
        party = {
          name = L["Party"],
          desc = L["Reports result to your party."],
          type = 'execute',
          func = "FlaskCheck",
          disabled = function() return GetNumPartyMembers()==0 end,
          passValue = "PARTY",
        },
        raid = {
          name = L["Raid"],
          desc = L["Reports result to your raid."],
          type = 'execute',
          func = "FlaskCheck",
          disabled = function() return GetNumRaidMembers()==0 end,
          passValue = "RAID",
        },
        guild = {
          name = L["Guild"],
          desc = L["Reports result to guild chat."],
          type = 'execute',
          func = "FlaskCheck",
          passValue = "GUILD",
        },
        officer = {
          name = L["Officer"],
          desc = L["Reports result to officer chat."],
          type = 'execute',
          func = "FlaskCheck",
          passValue = "OFFICER",
        },
        whisper = {
          name = L["Whisper"],
          desc = L["Reports result to the currently targeted individual."],
          type = 'execute',
          func = "FlaskCheck",
          passValue = "WHISPER",
        }
      }
    },
    settings = {
      name = L["Settings"],
      desc = L["Mod Settings"],
      type = 'group',
      args = {
     events = {
      name = L["Events"],
      desc = L["Events"],
      type = 'group',
      args = {     
        polymorph = {
          name  = L["Polymorph"],
          desc = L["Reports if and which player breaks crowd control effects (like polymorph, shackle undead, etc.) on enemies."],
          type = 'toggle',
          get = function() return addon.db.profile.PolyBreak end,
          set = function(v) addon.db.profile.PolyBreak=v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },
        misdirect = {
          name  = L["Misdirect"],
          desc = L["Reports who gains misdirection."],
          type = 'toggle',
          get = function() return addon.db.profile.Misdirect end,
          set = function(v) addon.db.profile.Misdirect = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },
        taunt = {
          name  = L["Taunt"],
          desc = L["Reports when players taunt mobs."],
          type = 'toggle',
          get = function() return addon.db.profile.Taunt end,
          set = function(v) addon.db.profile.Taunt = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },
       aoetaunt = {
          name  = L["AoeTaunt"],
          desc = L["Reports when players aoe-taunt mobs."],
          type = 'toggle',
          get = function() return addon.db.profile.AoeTaunt end,
          set = function(v) addon.db.profile.AoeTaunt = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },                
        interrupt = {
          name  = L["Interrupt"],
          desc = L["Reports when players interrupt mob spell casts."],
          type = 'toggle',
          get = function() return addon.db.profile.Interrupt end,
          set = function(v) addon.db.profile.Interrupt = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },    
        mana = {
          name  = L["Mana"],
          desc = L["Reports when players use Innervate, Mana Anthem, and Mana Totem."],
          type = 'toggle',
          get = function() return addon.db.profile.Mana end,
          set = function(v) addon.db.profile.Mana = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },	
        stolen = {
          name  = L["Stolen"],
          desc = L["Reports when players steal mob buffs."],
          type = 'toggle',
          get = function() return addon.db.profile.Stolen end,
          set = function(v) addon.db.profile.Stolen = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },  				
        dispel = {
          name  = L["Dispel"],
          desc = L["Reports when players remove or steal mob buffs."],
          type = 'toggle',
          get = function() return addon.db.profile.Dispel end,
          set = function(v) addon.db.profile.Dispel = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        }, 
--[[    	reporttanks = {
	      name = L["Report Tanks"],
          desc = L["Report events caused by tanks"],
          type = 'toggle',
          get = function() return addon.db.profile.ReportTanks end,
          set = function(v) addon.db.profile.ReportTanks = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
	},	]]	
        brez = {
          name  = L["Resurrection - Combat"],
          desc = L["Reports when Combat Resurrection is performed."],
          type = 'toggle',
          get = function() return addon.db.profile.CombatRez end,
          set = function(v) addon.db.profile.CombatRez = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },      
        rez = {
          name  = L["Resurrection - Non-combat"],
          desc = L["Reports when Non-combat Resurrection is performed."],
          type = 'toggle',
          get = function() return addon.db.profile.NonCombatRez end,
          set = function(v) addon.db.profile.NonCombatRez = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        }, 
       }, }, -- end events 
     tank = {
      name = L["Tank Events"],
      desc = L["Tank Events"],
      type = 'group',
      args = {
        theimmutabilityofice = {
          name  = L["Theimmutabilityofice"],
          desc = L["Reports when when the Sacrifice is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.Theimmutabilityofice end,
          set = function(v) addon.db.profile.Theimmutabilityofice = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },
        antimagiccarapace = {
          name  = L["AntiMagicCarapace"],
          desc = L["Reports when when the Sacrifice is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.AntiMagicCarapace end,
          set = function(v) addon.db.profile.AntiMagicCarapace = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },	   
        vampireblood = {
          name  = L["Vampireblood"],
          desc = L["Reports when when the Sacrifice is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.Vampireblood end,
          set = function(v) addon.db.profile.Vampireblood = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },	   
        antimagiczone = {
          name  = L["Antimagiczone"],
          desc = L["Reports when when the Sacrifice is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.Antimagiczone end,
          set = function(v) addon.db.profile.Antimagiczone = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },	   
        indestructiblearmor = {
          name  = L["Indestructiblearmor"],
          desc = L["Reports when when the Sacrifice is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.Indestructiblearmor end,
          set = function(v) addon.db.profile.Indestructiblearmor = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },	   
        blinddefense = {
          name  = L["Blinddefense"],
          desc = L["Reports when when the Sacrifice is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.Blinddefense end,
          set = function(v) addon.db.profile.Blinddefense = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },	   
        nostepback = {
          name  = L["Nostepback"],
          desc = L["Reports when when the Sacrifice is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.Nostepback end,
          set = function(v) addon.db.profile.Nostepback = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },	   
        shieldblock = {
          name  = L["Shieldblock"],
          desc = L["Reports when when the Sacrifice is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.Shieldblock end,
          set = function(v) addon.db.profile.Shieldblock = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },	   
        negation = {
          name  = L["Negation"],
          desc = L["Reports when when the Sacrifice is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.Negation end,
          set = function(v) addon.db.profile.Negation = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },	   
        divineprotection = {
          name  = L["Divineprotection"],
          desc = L["Reports when when the Sacrifice is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.Divineprotection end,
          set = function(v) addon.db.profile.Divineprotection = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },	   
        oakleather = {
          name  = L["Oakleather"],
          desc = L["Reports when when the Sacrifice is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.Oakleather end,
          set = function(v) addon.db.profile.Oakleather = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },	   
        survival = {
          name  = L["Survival"],
          desc = L["Reports when when the Sacrifice is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.Survival end,
          set = function(v) addon.db.profile.Survival = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },	   
        frenzy = {
          name  = L["Frenzy"],
          desc = L["Reports when when the Sacrifice is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.Frenzy end,
          set = function(v) addon.db.profile.Frenzy = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },	   
        fangofsindragosa = {
          name  = L["FangofSindragosa"],
          desc = L["Reports when when the Sacrifice is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.FangofSindragosa end,
          set = function(v) addon.db.profile.FangofSindragosa = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },	   
        symbioteworm = {
          name  = L["Symbioteworm"],
          desc = L["Reports when when the Sacrifice is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.Symbioteworm end,
          set = function(v) addon.db.profile.Symbioteworm = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },	   		
      }, }, -- end events  		  
     removed = {
      name = L["Removed Events"],
      desc = L["Removed Events"],
      type = 'group',
      args = {
        sacrificeremoved = {
          name  = L["Hand of Sacrifice"],
          desc = L["Reports when when the Sacrifice is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.SacrificeRemoved end,
          set = function(v) addon.db.profile.SacrificeRemoved = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },
       protectionremoved = {
          name  = L["Hand of Protection"],
          desc = L["Reports when when the Protection is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.ProtectionRemoved end,
          set = function(v) addon.db.profile.ProtectionRemoved = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        }, 	  
       freedomremoved = {
          name  = L["Hand of freedom"],
          desc = L["Reports when when the Freedom is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.FreedomRemoved end,
          set = function(v) addon.db.profile.FreedomRemoved = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        }, 	  
       salvaremoved = {
          name  = L["Hand of salvation"],
          desc = L["Reports when when the Salva is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.SalvaRemoved end,
          set = function(v) addon.db.profile.SalvaRemoved = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        }, 	  
       hysteriaremoved = {
          name  = L["Hysteria"],
          desc = L["Reports when when the Hysteria is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.HysteriaRemoved end,
          set = function(v) addon.db.profile.HysteriaRemoved = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        }, 	  
       painsupressionremoved = {
          name  = L["Painsupression"],
          desc = L["Reports when when the Painsupression is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.PainsupressionRemoved end,
          set = function(v) addon.db.profile.PainsupressionRemoved = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },
       guardianspiritremoved = {
          name  = L["Guardianspirit"],
          desc = L["Reports when when the Guardians pirit is decreasing."],
          type = 'toggle',
          get = function() return addon.db.profile.GuardianspiritRemoved end,
          set = function(v) addon.db.profile.GuardianspiritRemoved = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },			
      }, }, -- end events  	   
     extraevents = {
      name = L["Extra events"],
      desc = L["Extra events"],
      type = 'group',
      args = {
        intervention = {
          name  = L["Intervention"],
          desc = L["Reports when players use Intervention."],
          type = 'toggle',
          get = function() return addon.db.profile.Intervention end,
          set = function(v) addon.db.profile.Intervention = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },
        sacredsacrifice = {
          name  = L["Sacred sacrifice"],
          desc = L["Reports when players use Sacred sacrifice."],
          type = 'toggle',
          get = function() return addon.db.profile.Sacredsacrifice end,
          set = function(v) addon.db.profile.Sacredsacrifice = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },
        auramaster = {
          name  = L["Auramaster"],
          desc = L["Reports when players use Aura master."],
          type = 'toggle',
          get = function() return addon.db.profile.Auramaster end,
          set = function(v) addon.db.profile.Auramaster = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },			
        painsupression = {
          name  = L["Painsupression"],
          desc = L["Reports when players use Painsupression."],
          type = 'toggle',
          get = function() return addon.db.profile.Painsupression end,
          set = function(v) addon.db.profile.Painsupression = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },
        strangulate = {
          name  = L["Strangulate"],
          desc = L["Reports when players use Strangulate."],
          type = 'toggle',
          get = function() return addon.db.profile.Strangulate end,
          set = function(v) addon.db.profile.Strangulate = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },
        fish = {
          name  = L["Fish"],
          desc = L["Reports when players use Fish."],
          type = 'toggle',
          get = function() return addon.db.profile.Fish end,
          set = function(v) addon.db.profile.Fish = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },
        mail = {
          name  = L["Mail"],
          desc = L["Reports when players use Mail."],
          type = 'toggle',
          get = function() return addon.db.profile.Mail end,
          set = function(v) addon.db.profile.Mail = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },		
        jeeves = {
          name  = L["Jeeves"],
          desc = L["Reports when players use Jeeves."],
          type = 'toggle',
          get = function() return addon.db.profile.Jeeves end,
          set = function(v) addon.db.profile.Jeeves = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },	
        heroism = {
          name  = L["Heroism"],
          desc = L["Reports when players use Heroism."],
          type = 'toggle',
          get = function() return addon.db.profile.Heroism end,
          set = function(v) addon.db.profile.Heroism = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },
        salva = {
          name  = L["Hand of salvation"],
          desc = L["Reports when players use Hand of salvation."],
          type = 'toggle',
          get = function() return addon.db.profile.Salva end,
          set = function(v) addon.db.profile.Salva = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },				
        protection = {
          name  = L["Hand of Protection"],
          desc = L["Reports when players use Hand of Protection."],
          type = 'toggle',
          get = function() return addon.db.profile.Protection end,
          set = function(v) addon.db.profile.Protection = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },				
        freedom = {
          name  = L["Hand of freedom"],
          desc = L["Reports when players use Hand of freedom."],
          type = 'toggle',
          get = function() return addon.db.profile.Freedom end,
          set = function(v) addon.db.profile.Freedom = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },				
        sacrifice = {
          name  = L["Hand of Sacrifice"],
          desc = L["Reports when players use Hand of Sacrifice."],
          type = 'toggle',
          get = function() return addon.db.profile.Sacrifice end,
          set = function(v) addon.db.profile.Sacrifice = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },
        soulgem = {
          name  = L["Soulgem"],
          desc = L["Reports when players use Soulgem."],
          type = 'toggle',
          get = function() return addon.db.profile.Soulgem end,
          set = function(v) addon.db.profile.Soulgem = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },
      hysteria = {
          name  = L["Hysteria"],
          desc = L["Reports when a player is in the Hysteria."],
          type = 'toggle',
          get = function() return addon.db.profile.Hysteria end,
          set = function(v) addon.db.profile.Hysteria = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },
      divinehymn = {
          name  = L["Divinehymn"],
          desc = L["Reports when a player is in the divine hymn."],
          type = 'toggle',
          get = function() return addon.db.profile.Divinehymn end,
          set = function(v) addon.db.profile.Divinehymn = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },
      guardianspirit = {
          name  = L["Guardianspirit"],
          desc = L["Reports when a player is in the guardian spirit."],
          type = 'toggle',
          get = function() return addon.db.profile.Guardianspirit end,
          set = function(v) addon.db.profile.Guardianspirit = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },	
	  }, }, -- end extra events    
     slacks = {
      name = L["Slacks"],
      desc = L["Slacks"],
      type = 'group',
      args = {
        arcanesign = {
          name  = L["Arcanesign"],
          desc = L["Reports when a player receives Arcane Sign."],
          type = 'toggle',
          get = function() return addon.db.profile.Arcanesign end,
          set = function(v) addon.db.profile.Arcanesign = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },	
        firalar = {
          name  = L["Firalar"],
          desc = L["Reports when a player receives fir from Alar."],
          type = 'toggle',
          get = function() return addon.db.profile.Firalar end,
          set = function(v) addon.db.profile.Firalar = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },	
        megoslack = {
          name  = L["Megoslack"],
          desc = L["Reports when a player makes more than 8 clicks on the fish."],
          type = 'toggle',
          get = function() return addon.db.profile.Megoslack end,
          set = function(v) addon.db.profile.Megoslack = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },
        shackleseal = {
          name  = L["Shackleseal"],
          desc = L["Reports when a player is in the shackle seal."],
          type = 'toggle',
          get = function() return addon.db.profile.Shackleseal end,
          set = function(v) addon.db.profile.Shackleseal = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },
        toyrailroad = {
          name  = L["Toyrailroad"],
          desc = L["Reports when a player using Toy railroad."],
          type = 'toggle',
          get = function() return addon.db.profile.Toyrailroad end,
          set = function(v) addon.db.profile.Toyrailroad = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }		  
        },				
 	  }, }, -- end events
       eventsoutput = {
          name = L["Events Output"],
          desc = L["Set where the output for selected events is sent"],
          type = 'group',
          args = {
            self = {
              name = L["Self"],
              desc = L["Reports result only to yourself."],
              type = 'toggle',
              get = function() return addon.db.profile.PolyOut[1] end,
              set = function(v) addon.db.profile.PolyOut[1] = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
            party = {
              name = L["Party"],
              desc = L["Reports result to your party."],
              type = 'toggle',
              get = function() return addon.db.profile.PolyOut[2] end,
              set = function(v) addon.db.profile.PolyOut[2] = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
            raid = {
              name = L["Raid"],
              desc = L["Reports result to your raid."],
              type = 'toggle',
              get = function() return addon.db.profile.PolyOut[3] end,
              set = function(v) addon.db.profile.PolyOut[3] = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
            guild = {
              name = L["Guild"],
              desc = L["Reports result to guild chat."],
              type = 'toggle',
              get = function() return addon.db.profile.PolyOut[4] end,
              set = function(v) addon.db.profile.PolyOut[4] = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
            officer = {
              name = L["Officer"],
              desc = L["Reports result to officer chat."],
              type = 'toggle',
              get = function() return addon.db.profile.PolyOut[5] end,
              set = function(v) addon.db.profile.PolyOut[5] = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },             
            custom = {
              name = L["Custom"],
              desc = L["Reports result to your custom channel."],
              type = 'toggle',
              get = function() return addon.db.profile.PolyOut[6] end,
              set = function(v) addon.db.profile.PolyOut[6] = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },           
            battleground = {
              name = L["Battleground"],
              desc = L["Reports result to your battleground."],
              type = 'toggle',
              get = function() return addon.db.profile.PolyOut[7] end,
              set = function(v) addon.db.profile.PolyOut[7] = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },                        
          }
        },
        checks = {
          name = L["Checks"],
          desc = L["Set whether Flasks, Elixirs and Food are included in flaskcheck/quickcheck"],
          type = 'group',
          args = {
            flask = {
              name  = L["Flasks"],
              desc = L["Flasks"],
              type = 'toggle',
              get = function() return addon.db.profile.CheckFlasks end,
              set = function(v) addon.db.profile.CheckFlasks = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
            elixir = {
              name  = L["Elixirs"],
              desc = L["Elixirs"],
              type = 'toggle',
              get = function() return addon.db.profile.CheckElixirs end,
              set = function(v) addon.db.profile.CheckElixirs = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
            food = {
              name  = L["Food Buffs"],
              desc = L["Food Buffs"],
              type = 'toggle',
              get = function() return addon.db.profile.CheckFood end,
              set = function(v) addon.db.profile.CheckFood = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },	
          },
        },
        ready = {
          name = L["Ready check auto-check"],
          desc = L["Perform a quickcheck automatically on ready check"],
          type = 'group',
          args = {
            fromself = {
              name  = L["Ready checks from self"],
              desc = L["Ready checks from self"],
              type = 'toggle',
              get = function() return addon.db.profile.ReadyCheckMine end,
              set = function(v) addon.db.profile.ReadyCheckMine = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
            fromother = {
              name  = L["Ready checks from others"],
              desc = L["Ready checks from others"],
              type = 'toggle',
              get = function() return addon.db.profile.ReadyCheckOther end,
              set = function(v) addon.db.profile.ReadyCheckOther = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
            toraid = {
              name  = L["Reports result to your raid."],
              desc = L["Reports result to your raid."],
              type = 'toggle',
              get = function() return addon.db.profile.ReadyCheckToRaid end,
              set = function(v) addon.db.profile.ReadyCheckToRaid = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },            
            toself = {
              name  = L["Reports result only to yourself."],
              desc = L["Reports result only to yourself."],
              type = 'toggle',
              get = function() return addon.db.profile.ReadyCheckToSelf end,
              set = function(v) addon.db.profile.ReadyCheckToSelf = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },  
          },      
        },
        readywin = {
          name = L["Ready check Buff Window"],
          desc = L["Open the Buff Window automatically on ready check"],
          type = 'group',
          args = {
            fromself = {
              name  = L["Ready checks from self"],
              desc = L["Ready checks from self"],
              type = 'toggle',
              get = function() return addon.db.profile.ReadyCheckBuffWinMine end,
              set = function(v) addon.db.profile.ReadyCheckBuffWinMine = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
            fromother = {
              name  = L["Ready checks from others"],
              desc = L["Ready checks from others"],
              type = 'toggle',
              get = function() return addon.db.profile.ReadyCheckBuffWinOther end,
              set = function(v) addon.db.profile.ReadyCheckBuffWinOther = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
          },
        },        
        combatbuffwin = {
          name  = L["Close Buff Window on Combat"],
          desc = L["Close Buff Window when entering combat"],
          type = 'toggle',
          get = function() return addon.db.profile.BuffWindowCombatClose end,
          set = function(v) addon.db.profile.BuffWindowCombatClose = v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        }, 
        grouponly = {
          name  = L["Group Members Only"],
          desc = L["Only reports events about players in my party/raid"],
          type = 'toggle',
          get = function() return addon.db.profile.GroupOnly end,
          set = function(v) addon.db.profile.GroupOnly=v end,
          map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
        },       		
        customchannel = {
          name  = L["Custom Channel"],
          desc = L["Name of custom channel to use for output"],
          type = 'text',
          usage = '',
          validate = function(v) return true end,
          get = function() return addon.db.profile.CustomChannel end,
          set = function(v) addon.db.profile.CustomChannel = v end,

        },            
        groups = {
          name = L["Raid Groups"],
          desc = L["Set which raid groups are checked for buffs"],
          type = 'group',
          args = {
            group1 = {
              name  = L["Group"].." 1",
              desc = L["Group"].." 1",
              type = 'toggle',
              get = function() return addon.db.profile.Groups[1] end,
              set = function(v) addon.db.profile.Groups[1] = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
            group2 = {
              name  = L["Group"].." 2",
              desc = L["Group"].." 2",
              type = 'toggle',
              get = function() return addon.db.profile.Groups[2] end,
              set = function(v) addon.db.profile.Groups[2] = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
            group3 = {
              name  = L["Group"].." 3",
              desc = L["Group"].." 3",
              type = 'toggle',
              get = function() return addon.db.profile.Groups[3] end,
              set = function(v) addon.db.profile.Groups[3] = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
            group4 = {
              name  = L["Group"].." 4",
              desc = L["Group"].." 4",
              type = 'toggle',
              get = function() return addon.db.profile.Groups[4] end,
              set = function(v) addon.db.profile.Groups[4] = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
            group5 = {
              name  = L["Group"].." 5",
              desc = L["Group"].." 5",
              type = 'toggle',
              get = function() return addon.db.profile.Groups[5] end,
              set = function(v) addon.db.profile.Groups[5] = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
            group6 = {
              name  = L["Group"].." 6",
              desc = L["Group"].." 6",
              type = 'toggle',
              get = function() return addon.db.profile.Groups[6] end,
              set = function(v) addon.db.profile.Groups[6] = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
            group7 = {
              name  = L["Group"].." 7",
              desc = L["Group"].." 7",
              type = 'toggle',
              get = function() return addon.db.profile.Groups[7] end,
              set = function(v) addon.db.profile.Groups[7] = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
            group8 = {
              name  = L["Group"].." 8",
              desc = L["Group"].." 8",
              type = 'toggle',
              get = function() return addon.db.profile.Groups[8] end,
              set = function(v) addon.db.profile.Groups[8] = v end,
              map = { [false] = "|cffff4040Disabled|r", [true] = "|cff40ff40Enabled|r" }
            },
          }
        },
      }
    },
    buffcheck = {
      name = L["BuffCheck"],
      desc = L["Pops up a window to check various raid/elixir buffs (drag the bottom to resize)."],
      type = 'execute',
      func = function() BigBrother:ToggleBuffWindow() end,
    }
  }
}

addon.OnMenuRequest = options

function addon:OnInitialize()
  self:RegisterChatCommand("/bb", "/bigbrother", options, "BIGBROTHER")
end

local LDB

function addon:OnEnable()
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  self:RegisterEvent("READY_CHECK")  
  self:RegisterEvent("PLAYER_REGEN_DISABLED")
  self:OnProfileEnable() 
  
  if LDB then
    return
  end
  if AceLibrary:HasInstance("LibDataBroker-1.1") then
    LDB = AceLibrary("LibDataBroker-1.1")
  elseif LibStub then
    LDB = LibStub:GetLibrary("LibDataBroker-1.1",true)
  end
  if LDB then
    local dataobj = LDB:GetDataObjectByName("BigBrother") or 
      LDB:NewDataObject("BigBrother", {
        type = "launcher",
        label = "BigBrother",
        icon = "Interface\\AddOns\\BigBrother\\icon",
      })
    dataobj.OnClick = function(self, button)
	        if button == "RightButton" then
	                BigBrother:OpenMenu(self,addon)
	        else
	                BigBrother:ToggleBuffWindow()
	        end
        end    
    dataobj.OnTooltipShow = function(tooltip)
                if tooltip and tooltip.AddLine then
                        tooltip:SetText("BigBrother")
                        tooltip:AddLine(L["|cffff8040Left Click|r to toggle the buff window"])
                        tooltip:AddLine(L["|cffff8040Right Click|r for menu"])
                        tooltip:Show()
                end
        end            
    -- if AceLibrary:HasInstance("LibDBIcon-1.0") then
    --   AceLibrary("LibDBIcon-1.0"):Register("BigBrother", LDB, self.db.profile.minimap)
    -- end  
  end  

  DEFAULT_CHAT_FRAME:HookScript("OnHyperlinkEnter", function(self, linkData, olink)
        if string.match(linkData,"^player::BigBrother:") then
          GameTooltip:SetOwner(self, "ANCHOR_CURSOR");
          GameTooltip:SetText(L["Click to add this event to chat"])
          GameTooltip:Show()
        end
  end)
  DEFAULT_CHAT_FRAME:HookScript("OnHyperlinkLeave", function(self, linkData, link)
        if string.match(linkData,"^player::BigBrother:") then
          GameTooltip:Hide()
        end
  end)
end

function addon:OnDisable()
  if BigBrother_BuffWindow and BigBrother_BuffWindow:IsShown() then
    BigBrother:ToggleBuffWindow()
  end
end

function addon:OnProfileDisable()
end

function addon:OnProfileEnable()
end

function addon:SendMessageList(Pre,List,Where)
  if #List > 0 then
    if Where == "SELF" then
      self:Print(string.format(color, Pre..":") .. " " .. table.concat(List, ", "))
    elseif Where == "WHISPER" then
      local theTarget = UnitName("playertarget")
      if theTarget == nil then
         theTarget = UnitName("player")
      end
      SendChatMessage(Pre..": "..table.concat(List, ", "),Where,nil,theTarget)
    else
      SendChatMessage(Pre..": "..table.concat(List, ", "),Where)
    end
  end
end

function addon:HasBuff(player,MissingBuffList)
  for k, v in pairs(MissingBuffList) do
    if v==player then
      table.remove(MissingBuffList,k)
    end
  end
end

function addon:FlaskCheck(Where)
  self:ConsumableCheck(Where, true)
end

function addon:QuickCheck(Where)
  self:ConsumableCheck(Where, true)
end


function addon:ConsumableCheck(Where,Full)
  local numElixirs = 0
  local MissingFlaskList={}
  local MissingElixirList={}
  local MissingFoodList={}

  if not (self.db.profile.CheckFlasks or self.db.profile.CheckElixirs or self.db.profile.CheckFood) then
    self:Print(L["No checks selected!"])
    return
  end

	-- Fill up the food and flask lists with the raid roster names
	-- We wil remove those that are "ok" later
  for unit in RL:IterateRoster(false) do
    if self.db.profile.Groups[unit.subgroup] then
      table.insert(MissingFlaskList,unit.name)
      table.insert(MissingFoodList,unit.name)
    end
  end
  if #MissingFlaskList == 0 then
    self:Print(L["No units in selected raid groups!"])
    return
  end

  -- Print the flask list and determine who has no flask
  if self.db.profile.CheckFlasks then  
  for i, v in ipairs(vars.Flasks) do
      local spellName, spellIcon = unpack(v)
      local t = self:BuffPlayerList(spellName,MissingFlaskList)
        self:SendMessageList(spellName, t, Where)
      end	
	if self.db.profile.CheckElixirs then
	else
    self:SendMessageList(L["No Flask"], MissingFlaskList, Where) 	  
    end 
  end  
 
  --use this to print out who has what elixir, and who has no elixirs
  if self.db.profile.CheckElixirs then
    for i, v in ipairs(vars.Elixirs) do
      local spellName, spellIcon = unpack(v)
      local t = self:BuffPlayerList(spellName, MissingFlaskList)
      if self.db.profile.CheckElixirs then
        self:SendMessageList(spellName, t, Where)
      end
    end  
   
    --now figure out who has only one elixir
    for unit in RL:IterateRoster(false) do
      if self.db.profile.Groups[unit.subgroup] then
        numElixirs = 0
        for i, v in ipairs(vars.Elixirs) do
            local spellName, spellIcon = unpack(v)
            if UnitBuff(unit.unitid, spellName) then
              numElixirs = numElixirs + 1
            end
        end
        if numElixirs == 1 then
            table.insert(MissingElixirList,unit.name)
        end
      end
    end

  if self.db.profile.CheckElixirs then
    self:SendMessageList(L["Only One Elixir"], MissingElixirList, Where)
    self:SendMessageList(L["No Flask or Elixir"], MissingFlaskList, Where)
  end
 end 
	--check for missing food
	if self.db.profile.CheckFood then
		for i, v in ipairs(vars.Foodbuffs) do
			local spellName, spellIcon = unpack(v)
			local t = self:BuffPlayerList(spellName, MissingFoodList)
		end
		self:SendMessageList(L["No Food Buff"], MissingFoodList, Where)
	end  
end

local petToOwner = {}
local tanklist = {}
local tankcnt = 0
addon.petToOwner = petToOwner

local function nospace(str)
  if not str then return "" end
  return str:gsub("%s","")
end

function addon:IsTank(name)
  if not name then return nil end
  if tankcnt == 0 then
    RL:ScanFullRoster()
    for unit in RL:IterateRoster(false) do
      if GetPartyAssignment("MAINTANK", unit.unitid) or
         UnitGroupRolesAssigned(unit.unitid) == "TANK" then
        tanklist[nospace(unit.name)] = true -- bare name
        tanklist[nospace(unit.unitid)] = true -- bare name
        tanklist[nospace(GetUnitName(unit.unitid,false))] = true 
        tanklist[nospace(GetUnitName(unit.unitid,true))] = true -- with server name
	tankcnt = tankcnt + 1
	--print("detected tank: "..unit.name)
      end
    end
  end
  local retval = tanklist[nospace(name)] or tanklist[nospace(GetUnitName(name, true))] 
  if BigBrother.debug then
    print("IsTank('"..name.."') => "..(retval and "true" or "false").." "..(tankcnt > 0))
  end
  return retval, tankcnt > 0
end
function addon:clearTankList()
  --print("Wiping "..tankcnt.." tanks")
  wipe(tanklist)
  tankcnt = 0
end
function addon:RAID_ROSTER_UPDATE()
  addon:clearTankList()
  addon:BroadcastVersion()
end
function addon:PARTY_MEMBERS_CHANGED()
  addon:clearTankList()
  addon:BroadcastVersion()
end

function addon:BuffPlayerList(buffname,MissingBuffList)
  local list = {}
  for unit in RL:IterateRoster(false) do
    if UnitBuff(unit.unitid, buffname) then
      table.insert(list, unit.name)
      self:HasBuff(unit.name,MissingBuffList)
    end
  end
  return list
end

local iconlookup = {
  [COMBATLOG_OBJECT_RAIDTARGET1] = "{rt1}",
  [COMBATLOG_OBJECT_RAIDTARGET2] = "{rt2}",
  [COMBATLOG_OBJECT_RAIDTARGET3] = "{rt3}",
  [COMBATLOG_OBJECT_RAIDTARGET4] = "{rt4}",
  [COMBATLOG_OBJECT_RAIDTARGET5] = "{rt5}",
  [COMBATLOG_OBJECT_RAIDTARGET6] = "{rt6}",
  [COMBATLOG_OBJECT_RAIDTARGET7] = "{rt7}",
  [COMBATLOG_OBJECT_RAIDTARGET8] = "{rt8}",
  }

local srcGUID, srcname, srcflags, srcRaidFlags,
      dstGUID, dstname, dstflags, dstRaidFlags

local SRC = "<<<SRC>>>"
local DST = "<<<DST>>>"
local EMBEGIN = "<<<EM>>>"
local EMEND = "<<</EM>>>"
local function SPELL(id)
  return "<<<SPELL:"..id..">>>"
end
local function SPELLDECODE_helper(s)
  local l
  l = s and GetSpellLink(s)
  if l then return l
  else return GetSpellLink(2382)
  end
end
local function SPELLDECODE(spam)
   return string.gsub(spam, "<<<SPELL:(%d+)>>>", SPELLDECODE_helper)
end

local function iconize(flags,chatoutput)
  local iconflag = bit.band(flags or 0, COMBATLOG_OBJECT_RAIDTARGET_MASK)
  
  if chatoutput then
    return (iconlookup[iconflag] or "")
  elseif iconflag then
    local check, iconidx = math.frexp(iconflag)
    --iconidx = iconidx - 20
    if check == 0.5 and iconidx >= 1 and iconidx <= 8 then
      return "|Hicon:"..iconflag..":dest|h|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_"..iconidx..".blp:0|t|h"  
    end
  end
  
  return ""
end

local function unitColor(guid, flags, name)
  local color
  local class = guid and select(3,pcall(GetPlayerInfoByGUID, guid)) -- ticket 34
  if bit.band(flags or 0,COMBATLOG_OBJECT_REACTION_FRIENDLY) == 0 then 
    color = "ff0000"
  elseif bit.band(flags or 0,COMBATLOG_OBJECT_TYPE_NPC) > 0 then
    color = "6666ff"
  elseif bit.band(flags or 0,COMBATLOG_OBJECT_TYPE_PET) > 0 then
    color = "40ff40"
  elseif bit.band(flags or 0,COMBATLOG_OBJECT_TYPE_GUARDIAN) > 0 then
    color = "40ff40"
  elseif class and RAID_CLASS_COLORS[class] then
    local c = RAID_CLASS_COLORS[class]
    color = string.format("%02x%02x%02x", c.r*255, c.g*255, c.b*255)
  else -- unknown
    color = "666666"
  end
  if bit.band(flags or 0,COMBATLOG_OBJECT_TYPE_PLAYER) then
    name = "\124Hplayer:"..name.."::"..name.."\124h"..name.."\124h"
  end
  return "\124cff"..color..name.."\124r"
end

local function unitOwner(petGUID, petFlags, usecolor)
  --print("unitOwner"..petGUID.." "..petFlags)
  if not petGUID or not petFlags then
    return ""
  end
  if bit.band(petFlags,COMBATLOG_OBJECT_TYPE_PET) == 0 and
     bit.band(petFlags,COMBATLOG_OBJECT_TYPE_GUARDIAN) == 0 then
    return ""
  end
  local ownerGUID = petToOwner[petGUID]
  if not ownerGUID then -- try a refresh
    for unit in RL:IterateRoster(true) do
      local ownerid = unit.unitid:match("^(.*)pet$")
      if ownerid == "" then ownerid = "player" end
      if ownerid and UnitExists(ownerid) and UnitExists(unit.unitid) then
        local guid = UnitGUID(unit.unitid)
        local ownerguid = UnitGUID(ownerid)
        petToOwner[guid] = ownerguid 
      end
    end
    ownerGUID = petToOwner[petGUID]
  end
  if not ownerGUID then
    return ""
  end
  local name = select(6,GetPlayerInfoByGUID(ownerGUID)) or "Unknown"
  if usecolor then
    local colored = unitColor(ownerGUID, bit.bor(COMBATLOG_OBJECT_TYPE_PLAYER, COMBATLOG_OBJECT_REACTION_FRIENDLY), name)
    return " <"..colored..">"
  else
    return " <"..name..">"
  end
end

local function SYMDECODE(spam,chatoutput)
  local x = iconize(COMBATLOG_OBJECT_RAIDTARGET7,chatoutput)
  spam = string.gsub(spam, EMBEGIN, x..x..x.." ")
  spam = string.gsub(spam, EMEND, " "..x..x..x)
  local srctxt = srcname or "Unknown"
  local dsttxt = dstname or "Unknown"
  if not chatoutput then
    srctxt = unitColor(srcGUID, srcflags, srctxt)
    dsttxt = unitColor(dstGUID, dstflags, dsttxt)
  end
  local srcowner = unitOwner(srcGUID, srcflags, not chatoutput)
  local dstowner = unitOwner(dstGUID, dstflags, not chatoutput)
  srctxt = iconize(srcRaidFlags,chatoutput)..srctxt..srcowner
  dsttxt = iconize(dstRaidFlags,chatoutput)..dsttxt..dstowner
  spam = string.gsub(spam, SRC, srctxt)
  spam = string.gsub(spam, DST, dsttxt)
  return spam
end

local function spamchannel(spam, channel, chanid)
   local output = spam
   output = SPELLDECODE(output)
   output = SYMDECODE(output, true)
   SendChatMessage(output, channel, nil, chanid)
end

local function sendspam(spam,channels)
	if not spam then return end
	
  local it = select(2, IsInInstance())
  local inbattleground = (it == "pvp") 
  local inwintergrasp = (GetRealZoneText() == L["Wintergrasp"])
  local inarena = (it == "arena")
  
    if tankunit then
    local istank, havetanks = addon:IsTank(tankunit)
    if istank and not addon.db.profile.ReportTanks then
      return
    end
    if not istank and havetanks and addon.db.profile.ReportTanks then
      spam = EMBEGIN..spam..EMEND
    end
    end

  -- BG reporting - never spam bg unless specifically requested, and dont spam anyone else
	if inbattleground then 
	  if channels[7] then 
	    SendChatMessage(spam, "BATTLEGROUND")
	  end
	  return	  
	elseif inwintergrasp then
    if channels[7] then 
	    SendChatMessage(spam, "RAID")
	  end	
	  return	  
	elseif inarena then
	  if channels[2] or channels[7] then
	    SendChatMessage(spam, "PARTY")
	  end
	  return
  end	
    
  -- raid/party reporting
	if GetNumRaidMembers() ~= 0 and channels[3] then
	  SendChatMessage(spam, "RAID")
	elseif GetNumPartyMembers() ~= 0 and channels[2] then
	  SendChatMessage(spam, "PARTY")	
	end
	
	-- guild reporting - dont spam both channels
	if IsInGuild() and channels[4] then
	  SendChatMessage(spam, "GUILD")	
	elseif IsInGuild() and channels[5] then
	  SendChatMessage(spam, "OFFICER")	
	end
	
	-- custom reporting
	if channels[6] and addon.db.profile.CustomChannel then
	  local chanid = GetChannelName(addon.db.profile.CustomChannel)
	  if chanid then
      SendChatMessage(spam, "CHANNEL", nil, chanid)	  
	  end
	end
end

local clickchan = {false, true, true, false, false, false, true}
hooksecurefunc("SetItemRef",function(link,text,button,chatFrame)
  local time, data = string.match(link,"^player::BigBrother:(%d+):(.+)$")
  if time then
      data = SPELLDECODE(data)
      data = "["..date("%H:%M:%S",time).."]: "..data
      if ChatEdit_GetActiveWindow() then
        ChatEdit_InsertLink(data)
      else
        sendspam(data, clickchan)
      end
  end
end)


function addon:PLAYER_REGEN_DISABLED()
  addon:clearTankList()
  if addon.db.profile.BuffWindowCombatClose then
    if BigBrother_BuffWindow and BigBrother_BuffWindow:IsShown() then
      BigBrother:ToggleBuffWindow()
    end  
  end
end

function addon:READY_CHECK(sender)
  local doquickcheck = false
  local dowindisplay = false
  
  if addon.IsDisabled(addon) then
    return
  end
          
  if UnitIsUnit(sender, "player") then
    if addon.db.profile.ReadyCheckMine then doquickcheck = true end
    if addon.db.profile.ReadyCheckBuffWinMine then dowindisplay = true end  
  else     
    if addon.db.profile.ReadyCheckOther then doquickcheck = true end           
    if addon.db.profile.ReadyCheckBuffWinOther then dowindisplay = true end  
  end
  
  if dowindisplay then
    if not BigBrother_BuffWindow or not BigBrother_BuffWindow:IsShown() then
      BigBrother:ToggleBuffWindow()
    end
  end    
  
  if doquickcheck then
    if addon.db.profile.ReadyCheckToRaid then
      if GetNumRaidMembers() > 0 then
          addon:ConsumableCheck("RAID")
      elseif GetNumPartyMembers() > 0 then
          addon:ConsumableCheck("PARTY")                
      end
    elseif addon.db.profile.ReadyCheckToSelf then
      addon:ConsumableCheck("SELF")         
    end
  end    
end

local ccinfo = {
  spellid = {},       -- GUID -> cc spell id
  time = {},          -- GUID -> time when it expires
  dmgspellid = {},    -- GUID -> spell ID that caused damage
  dmgspellamt = {},   -- GUID -> spell ID that caused damage
  dmgunitname = {},   -- GUID -> last unit to damage it
  dmgunitguid = {},   -- GUID -> last unit to damage it
  dmgunitflags = {},  -- GUID -> last unit to damage it
  dmgunitrflags = {}, -- GUID -> last unit to damage it
  postponetime = {},  -- GUID -> time of breakage postponed
}
local function ccinfoClear(dstGUID) 
      ccinfo.spellid[dstGUID] = nil
      ccinfo.time[dstGUID] = nil
      ccinfo.dmgspellid[dstGUID] = nil
      ccinfo.dmgspellamt[dstGUID] = nil
      ccinfo.dmgunitname[dstGUID] = nil
      ccinfo.dmgunitguid[dstGUID] = nil
      ccinfo.dmgunitflags[dstGUID] = nil
      ccinfo.dmgunitrflags[dstGUID] = nil
      ccinfo.postponetime[dstGUID] = nil
end

local playersrcmask = bit.bor(bit.bor(COMBATLOG_OBJECT_TYPE_PLAYER, 
                              COMBATLOG_OBJECT_TYPE_PET),
                              COMBATLOG_OBJECT_TYPE_GUARDIAN) -- totems


  local Arcanesignslack = {}
  local Arcanesignslack2 = {}
  local Fishs3 = {}
  local t = 0
  local fisht = 0

function addon:COMBAT_LOG_EVENT_UNFILTERED(timestamp, subevent, srcGUID, srcname, srcflags, dstGUID, dstname, dstflags, spellID, spellname, spellschool, extraspellID, extraspellname, extraspellschool, auratype, ...)  
  
  local HPTANK = 50000
  
  local is_playersrc = bit.band(srcflags or 0, COMBATLOG_OBJECT_TYPE_PLAYER) > 0
  local is_playerdst = bit.band(dstflags or 0, COMBATLOG_OBJECT_TYPE_PLAYER) > 0
  local is_hostiledst = bit.band(dstflags or 0, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 
  --print((spellname or "nil")..":"..(spellID or "nil")..":"..(subevent or "nil")..":"..(srcname or "nil")..":"..(dstname or "nil")..":"..(dstGUID or "nil")..":"..(dstflags or "nil")..":".."is_playersrc:"..((is_playersrc and "true") or "false"))
  if self.db.profile.GroupOnly and 
     bit.band(srcflags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) > 0 and
     bit.band(dstflags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) > 0 and
     bit.band(srcflags, COMBATLOG_OBJECT_AFFILIATION_RAID) > 0	and  
     not ccinfo.spellid[dstGUID] then
     -- print("skipped event from "..(srcname or "nil").." on "..(dstname or "nil"))
    return
	elseif self.db.profile.PolyBreak and is_playersrc
	  and (subevent == "SPELL_AURA_BROKEN" or subevent == "SPELL_AURA_BROKEN_SPELL" or subevent == "SPELL_AURA_REMOVED")
	  and is_hostiledst
	  and ccSpellNames[spellname] then

		local throttleResetTime = 15;
		local now = GetTime();

		-- Reset the spam throttling cache if it isn't initialized or
		-- if it's been more than 15 seconds since any CC broke
		if (nil == self.spamCache or (nil ~= self.spamCacheLastTimeMax and now - self.spamCacheLastTimeMax > throttleResetTime)) then
			self.spamCache = {};
			self.spamCacheLastTimeMax = nil;
		end

		local output, spam
		local srcspam = iconize(srcflags,true)..srcname
		local srcout = iconize(srcflags,false)..srcname
		local dstspam = iconize(dstflags,true)..dstname
		local dstout = iconize(dstflags,false)..dstname
		
		if subevent == "SPELL_AURA_BROKEN" then
				spam = (L["%s on %s removed by %s"]):format(GetSpellLink(spellID), dstspam, srcspam)
				output = (L["%s on %s removed by %s"]):format(GetSpellLink(spellID), dstout, srcout)
		elseif subevent == "SPELL_AURA_BROKEN_SPELL" then
				spam = (L["%s on %s removed by %s's %s"]):format(GetSpellLink(spellID), dstspam, srcspam, GetSpellLink(extraspellID))
				output = (L["%s on %s removed by %s's %s"]):format(GetSpellLink(spellID), dstout, srcout, GetSpellLink(extraspellID))
		elseif subevent == "SPELL_AURA_REMOVED" and (spellID == 51514) then -- hex does not get a AURA_BROKEN event because it doesnt break on first damage
				spam = (L["%s on %s removed"]):format(GetSpellLink(spellID), dstspam)
				output = (L["%s on %s removed"]):format(GetSpellLink(spellID), dstout)
		end

		-- Should we throttle the spam?
		if self.spamCache[dstGUID] and now - self.spamCache[dstGUID]["lasttime"] < throttleResetTime then
			-- If we've been broken 3 or more times without a 15 second reprieve, then
			-- supress the spam
			if (self.spamCache[dstGUID]["count"] > 3) then
				spam = nil;
				output = nil;
			end

			-- Increment the cache entry
			self.spamCache[dstGUID]["count"] = self.spamCache[dstGUID]["count"] + 1;
			self.spamCache[dstGUID]["lasttime"] = now;
		else
			-- Reset the cache entry
			self.spamCache[dstGUID] = {["count"] = 1, ["lasttime"] = now};
		end
		self.spamCacheLastTimeMax = now;

		if output and self.db.profile.PolyOut[1] then
			self:Print(output)
		end

		if spam then
			sendspam(spam,addon.db.profile.PolyOut)
		end
	elseif self.db.profile.Misdirect and is_playersrc and subevent == "SPELL_CAST_SUCCESS" and (spellID == 34477 or spellID == 57934) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s on %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID), "|cffff4040"..dstname.."|r"))
		end
		sendspam(L["%s cast %s on %s"]:format(srcname, GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
	elseif self.db.profile.CombatRez and is_playersrc and (subevent == "SPELL_RESURRECT" or subevent == "SPELL_CAST_SUCCESS") and brezSpellNamesTwo[spellname] then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s on %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID), "|cffff4040"..dstname.."|r"))
		end
		sendspam(L["%s cast %s on %s"]:format(srcname, GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
	elseif self.db.profile.CombatRez and is_playersrc and (subevent == "SPELL_RESURRECT" or subevent == "SPELL_CAST_SUCCESS") and brezSpellNames[spellname] and (spellID ~= 49039) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)				
	elseif self.db.profile.NonCombatRez and is_playersrc and subevent == "SPELL_RESURRECT" and rezSpellNames[spellname] then
		-- would like to report at spell cast start, but unfortunately the SPELL_CAST_SUCCESS combat log event for all rezzes has a nil target
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s on %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID), "|cffff4040"..dstname.."|r"))
		end
		sendspam(L["%s cast %s on %s"]:format(srcname, GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)		
	elseif self.db.profile.Taunt and is_playersrc and not is_playerdst and subevent == "SPELL_CAST_SUCCESS" and tauntSpellNames[spellname] then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s taunted %s with %s"]:format("|cff40ff40"..srcname.."|r", iconize(dstflags,false).."|cffff4040"..dstname.."|r", GetSpellLink(spellID)))
		end
		sendspam(L["%s taunted %s with %s"]:format(srcname, iconize(dstflags,true)..dstname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
	elseif self.db.profile.AoeTaunt and is_playersrc and not is_playerdst and subevent == "SPELL_AURA_APPLIED" and aoetauntSpellNames[spellname] then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s aoe-taunted %s with %s"]:format("|cff40ff40"..srcname.."|r", iconize(dstflags,false).."|cffff4040"..dstname.."|r", GetSpellLink(spellID)))
		end	
		sendspam(L["%s aoe-taunted %s with %s"]:format(srcname, iconize(dstflags,true)..dstname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
	elseif self.db.profile.Taunt and is_playersrc and not is_playerdst and subevent == "SPELL_MISSED" and tauntSpellNames[spellname] 
	  and not (spellID == 49576 and extraspellID == "IMMUNE") then -- ignore immunity messages from death grip caused by mobs immune to the movement component
    local missType = extraspellID
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s taunt FAILED on %s (%s)"]:format("|cff40ff40"..srcname.."|r", iconize(dstflags,false).."|cffff4040"..dstname.."|r", missType))
		end	
		sendspam(L["%s taunt FAILED on %s (%s)"]:format(srcname, iconize(dstflags,true)..dstname, missType),addon.db.profile.PolyOut)
	elseif self.db.profile.AoeTaunt and is_playersrc and not is_playerdst and subevent == "SPELL_MISSED" and aoetauntSpellNames[spellname]
	  and not (spellID == 49576 and extraspellID == "IMMUNE") then -- ignore immunity messages from death grip caused by mobs immune to the movement component
    local missType = extraspellID
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s taunt FAILED on %s (%s)"]:format("|cff40ff40"..srcname.."|r", iconize(dstflags,false).."|cffff4040"..dstname.."|r", missType))
		end	
		sendspam(L["%s taunt FAILED on %s (%s)"]:format(srcname, iconize(dstflags,true)..dstname, missType),addon.db.profile.PolyOut)		
	elseif self.db.profile.Interrupt and is_playersrc and subevent == "SPELL_INTERRUPT" then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s interrupted casting %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(extraspellID)))
		end	
		sendspam(L["%s interrupted casting %s"]:format(srcname, GetSpellLink(extraspellID)),addon.db.profile.PolyOut)
    elseif self.db.profile.Dispel and is_playersrc and subevent == "SPELL_DISPEL" then
	    if self.db.profile.PolyOut[1] then
		    self:Print(L["%s dispelled %s on %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(extraspellID), iconize(dstflags,false).."|cffff4040"..dstname.."|r"),addon.db.profile.PolyOut)
		end
	    sendspam(L["%s dispelled %s on %s"]:format(srcname, GetSpellLink(extraspellID), dstname),addon.db.profile.PolyOut)
    elseif self.db.profile.Stolen and is_playersrc and is_hostiledst and subevent == "SPELL_STOLEN" then
	    if self.db.profile.PolyOut[1] then
		    self:Print(L["%s stole %s from %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(extraspellID), "|cffff4040"..dstname.."|r"),addon.db.profile.PolyOut)
		end	
	    sendspam(L["%s stole %s from %s"]:format(srcname, GetSpellLink(extraspellID), dstname),addon.db.profile.PolyOut)
	elseif self.db.profile.Mana and is_playersrc and subevent == "SPELL_CAST_SUCCESS" and (spellID == 29166) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s on %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID), "|cffff4040"..dstname.."|r"))
		end			
		sendspam(L["%s cast %s on %s"]:format(srcname, GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
	elseif self.db.profile.Mana and is_playersrc and subevent == "SPELL_CAST_SUCCESS" and (spellID == 16190 or spellID == 64901) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end					
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
	elseif self.db.profile.Sacredsacrifice and is_playersrc and subevent == "SPELL_CAST_SUCCESS" and (spellID == 64205) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
	elseif self.db.profile.Auramaster and is_playersrc and subevent == "SPELL_CAST_SUCCESS" and (spellID == 31821) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)		
	elseif self.db.profile.Intervention and is_playersrc and subevent == "SPELL_CAST_SUCCESS" and (spellID == 3411) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s on %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID), "|cffff4040"..dstname.."|r"))
		end
		sendspam(L["%s cast %s on %s"]:format(srcname, GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
	elseif self.db.profile.Strangulate and is_playersrc and not is_playerdst and subevent == "SPELL_CAST_SUCCESS" and (spellID == 49576) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s on %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID), "|cffff4040"..dstname.."|r"))
		end
		sendspam(L["%s cast %s on %s"]:format(srcname, GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
	elseif self.db.profile.Painsupression and is_playersrc and subevent == "SPELL_CAST_SUCCESS" and (spellID == 33206) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s on %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID), "|cffff4040"..dstname.."|r"))
		end		
		sendspam(L["%s cast %s on %s"]:format(srcname, GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)	
	elseif self.db.profile.Fish and is_playersrc and subevent == "SPELL_CREATE" and (spellID == 300059) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s set %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end	
        fisht = timestamp		
		--print(timestamp)
		sendspam(L["%s set %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
	elseif self.db.profile.Mail and is_playersrc and subevent == "SPELL_CREATE" and (spellID == 54710) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s set %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		sendspam(L["%s set %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)		
	elseif self.db.profile.Jeeves and is_playersrc and subevent == "SPELL_CAST_SUCCESS" and (spellID == 67826 or spellID == 54711) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s caused %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		sendspam(L["%s caused %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
	elseif self.db.profile.Heroism and is_playersrc and subevent == "SPELL_CAST_SUCCESS" and (spellID == 32182 or spellID == 2825) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
	elseif self.db.profile.Salva and is_playersrc and subevent == "SPELL_CAST_SUCCESS" and (spellID == 1038) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s on %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID), "|cffff4040"..dstname.."|r"))
		end
		sendspam(L["%s cast %s on %s"]:format(srcname, GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
	elseif self.db.profile.Sacrifice and is_playersrc and subevent == "SPELL_CAST_SUCCESS" and (spellID == 6940) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s on %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID), "|cffff4040"..dstname.."|r"))
		end
		sendspam(L["%s cast %s on %s"]:format(srcname, GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
	elseif self.db.profile.Freedom and is_playersrc and subevent == "SPELL_CAST_SUCCESS" and (spellID == 1044) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s on %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID), "|cffff4040"..dstname.."|r"))
		end
		sendspam(L["%s cast %s on %s"]:format(srcname, GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
	elseif self.db.profile.Protection and is_playersrc and subevent == "SPELL_CAST_SUCCESS" and (spellID == 10278) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s on %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID), "|cffff4040"..dstname.."|r"))
		end
		sendspam(L["%s cast %s on %s"]:format(srcname, GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)		
	elseif self.db.profile.Soulgem and is_playersrc and subevent == "SPELL_AURA_APPLIED" and (spellID == 47883) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s imposed CC on %s"]:format("|cff40ff40"..srcname.."|r", "|cffff4040"..dstname.."|r"))
		end
		sendspam(L["%s imposed CC on %s"]:format(srcname, dstname),addon.db.profile.PolyOut)	
	elseif self.db.profile.Firalar and is_playerdst and subevent == "SPELL_AURA_APPLIED" and (spellID == 308671) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s catches fir"]:format("|cffff4040"..dstname.."|r"))
		end
		sendspam(L["%s catches fir"]:format(dstname),addon.db.profile.PolyOut)
	elseif self.db.profile.Shackleseal and is_playerdst and subevent == "SPELL_AURA_APPLIED" and (spellID == 310492) and (spellID ~= 310489) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s на %s"]:format(GetSpellLink(spellID), "|cffff4040"..dstname.."|r"))
		end
		sendspam(L["%s на %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)	
	elseif self.db.profile.Arcanesign and is_playersrc and subevent == "SPELL_DAMAGE" and (spellID == 308472) then
			self:Print(L["%s sign damage %s on %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID), "|cffff4040"..dstname.."|r"))
	elseif self.db.profile.Megoslack and is_playersrc and (subevent == "SPELL_AURA_APPLIED" or subevent == "SPELL_AURA_REFRESH") and (spellID == 300061) then
	        if self.db.profile.PolyOut[1] then
			self:Print(L["%s pokes the fish"]:format("|cff40ff40"..srcname.."|r"))	
			end
            table.insert(Arcanesignslack, srcname)
            --print(srcname)
			for i,v in ipairs(Arcanesignslack) do
			--print(i,v)
			if i == 1 then 
			t = timestamp
			elseif i > 1 then
			t = t
			end
            Arcanesignslack2[v] = (Arcanesignslack2[v] or 0 ) +1
			Arcanesignslack = {}
            end
			local max = -math.huge			
            for v,k in pairs(Arcanesignslack2) do 
            max = math.max(max, k)
			--print(v,k)
			local n = 45
            if t - fisht >= n then
			--print(t .. "  " .. fisht .. " " .. t - fisht)
			fisht = timestamp
            -- t = 0
        	max = 0
			Arcanesignslack = {}        
		    Arcanesignslack2 = {}
			--print("Вариант 1")
			table.insert(Arcanesignslack, srcname)
			--if k > 1 then
			elseif t - fisht <= n then
			if srcname == v and k > 7 then
			sendspam(L["%s сделал %s кликов по рыбе"]:format(v, k),addon.db.profile.PolyOut)
			fisht = timestamp		
			--print("Вариант 2")
           -- Fishs3 = Arcanesignslack2
			--for z,y in pairs(Fishs3) do 
			--print(z,y)
			--if y > 7 then
			--sendspam(L["%s сделал %s кликов по рыбе"]:format(z, y),addon.db.profile.PolyOut)
			--Arcanesignslack2 = {}
			--end
			--end
			--elseif k < 7 then
			--end
			end
			end
    end	
	elseif self.db.profile.Hysteria and is_playersrc and subevent == "SPELL_CAST_SUCCESS" and (spellID == 49016) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s on %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID), "|cffff4040"..dstname.."|r"))
		end
		sendspam(L["%s cast %s on %s"]:format(srcname, GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
	elseif self.db.profile.Divinehymn and is_playersrc and subevent == "SPELL_CAST_SUCCESS" and (spellID == 64843) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
	elseif self.db.profile.Toyrailroad and is_playersrc and subevent == "SPELL_CREATE" and (spellID == 61031) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s set yyy %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		sendspam(L["%s set yyy %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)			
    elseif self.db.profile.SacrificeRemoved and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 6940) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s falls off %s"]:format(GetSpellLink(spellID), "|cff40ff40"..dstname.."|r"))
		end		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
    elseif self.db.profile.ProtectionRemoved and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 10278) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s falls off %s"]:format(GetSpellLink(spellID), "|cff40ff40"..dstname.."|r"))
		end		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
    elseif self.db.profile.FreedomRemoved and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 1044) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s falls off %s"]:format(GetSpellLink(spellID), "|cff40ff40"..dstname.."|r"))
		end		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
    elseif self.db.profile.SalvaRemoved and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 1038) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s falls off %s"]:format(GetSpellLink(spellID), "|cff40ff40"..dstname.."|r"))
		end		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
    elseif self.db.profile.HysteriaRemoved and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 49016) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s falls off %s"]:format(GetSpellLink(spellID), "|cff40ff40"..dstname.."|r"))
		end		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
    elseif self.db.profile.PainsupressionRemoved and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 33206) then
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s falls off %s"]:format(GetSpellLink(spellID), "|cff40ff40"..dstname.."|r"))
		end		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)	
 --[[   elseif self.db.profile.test and not is_playerdst and subevent == "SPELL_CAST_START" and (spellID == 308663) then
		if self.db.profile.PolyOut[1] then
			self:SetRaidTarget(srcname,8)
		end		]]
--дк
	elseif self.db.profile.Theimmutabilityofice and is_playersrc and subevent == "SPELL_AURA_APPLIED" and (spellID == 48792) then --Незыблемость льда
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end
		if UnitHealthMax(srcname) > HPTANK then
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
        end
	elseif self.db.profile.AntiMagicCarapace and is_playersrc and subevent == "SPELL_AURA_APPLIED" and (spellID == 48707) then --Антимагический панцирь
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
        end
	elseif self.db.profile.Vampireblood and is_playersrc and subevent == "SPELL_AURA_APPLIED" and (spellID == 55233) then --Кровь вампира
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
        end
	elseif self.db.profile.Antimagiczone and is_playersrc and subevent == "SPELL_AURA_APPLIED" and (spellID == 51052) then --Зона антимагии
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
        end
	elseif self.db.profile.Indestructiblearmor and is_playersrc and subevent == "SPELL_AURA_APPLIED" and (spellID == 51271) then --Несокрушимая броня
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
        end
--вар
	elseif self.db.profile.Blinddefense and is_playersrc and subevent == "SPELL_AURA_APPLIED" and (spellID == 871) then --Глухая оборона
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
        end
	elseif self.db.profile.Nostepback and is_playersrc and subevent == "SPELL_AURA_APPLIED" and (spellID == 12976) then --Ни шагу назад
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
        end
	elseif self.db.profile.Shieldblock and is_playersrc and subevent == "SPELL_AURA_APPLIED" and (spellID == 2565) then --Блок щитом
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
        end
--пал
	elseif self.db.profile.Negation and is_playersrc and subevent == "SPELL_AURA_APPLIED" and (spellID == 307919) then --Отрицание
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
        end
	elseif self.db.profile.Divineprotection and is_playersrc and subevent == "SPELL_AURA_APPLIED" and (spellID == 498) then --Божественная защита
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
        end
--дру
	elseif self.db.profile.Oakleather and is_playersrc and subevent == "SPELL_AURA_APPLIED" and (spellID == 22812) then --Дубовая кожа
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
        end
	elseif self.db.profile.Survival and is_playersrc and subevent == "SPELL_AURA_APPLIED" and (spellID == 61336) then --Инстинкт выживания
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
        end
	elseif self.db.profile.Frenzy and is_playersrc and subevent == "SPELL_AURA_APPLIED" and (spellID == 308079) then --Исступление
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
        end
--тринкеты
	elseif self.db.profile.FangofSindragosa and is_playersrc and subevent == "SPELL_AURA_APPLIED" and (spellID == 71638) then --Безупречный клык Синдрагосы
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
        end
	elseif self.db.profile.Symbioteworm and is_playersrc and subevent == "SPELL_AURA_APPLIED" and (spellID == 300133) then --Червь-симбионт
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then
		sendspam(L["%s cast %s"]:format(srcname, GetSpellLink(spellID)),addon.db.profile.PolyOut)
        end
--дк
	elseif self.db.profile.Theimmutabilityofice and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 48792) then --Незыблемость льда
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
        if UnitHealthMax(srcname) > HPTANK then		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
		end
	elseif self.db.profile.AntiMagicCarapace and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 48707) then --Антимагический панцирь
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
		end
	elseif self.db.profile.Vampireblood and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 55233) then --Кровь вампира
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
		end
	elseif self.db.profile.Antimagiczone and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 51052) then --Зона антимагии
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
		end
	elseif self.db.profile.Indestructiblearmor and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 51271) then --Несокрушимая броня
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
		end
--вар
	elseif self.db.profile.Blinddefense and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 871) then --Глухая оборона
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
		end
	elseif self.db.profile.Nostepback and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 12976) then --Ни шагу назад
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
		end
	elseif self.db.profile.Shieldblock and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 2565) then --Блок щитом
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
		end
--пал
	elseif self.db.profile.Negation and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 307919) then --Отрицание
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
		end
	elseif self.db.profile.Divineprotection and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 498) then --Божественная защита
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
		end
--дру
	elseif self.db.profile.Oakleather and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 22812) then --Дубовая кожа
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
		end
	elseif self.db.profile.Survival and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 61336) then --Инстинкт выживания
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
		end
	elseif self.db.profile.Frenzy and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 308079) then --Исступление
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
		end
--тринкеты
	elseif self.db.profile.FangofSindragosa and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 71638) then --Безупречный клык Синдрагосы
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
		end
	elseif self.db.profile.Symbioteworm and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 300133) then --Червь-симбионт
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID)))
		end		
		if UnitHealthMax(srcname) > HPTANK then		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)
		end
	elseif self.db.profile.Guardianspirit and is_playersrc and subevent == "SPELL_AURA_APPLIED" and (spellID == 47788) then --оберегающий дух (ангелок)
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s cast %s on %s"]:format("|cff40ff40"..srcname.."|r", GetSpellLink(spellID), "|cffff4040"..dstname.."|r"))
		end		
		sendspam(L["%s cast %s on %s"]:format(srcname, GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)	
	elseif self.db.profile.GuardianspiritRemoved and is_playersrc and subevent == "SPELL_AURA_REMOVED" and (spellID == 47788) then --оберегающий дух (ангелок)
		if self.db.profile.PolyOut[1] then
			self:Print(L["%s falls off %s"]:format(GetSpellLink(spellID), "|cff40ff40"..dstname.."|r"))
		end		
		sendspam(L["%s falls off %s"]:format(GetSpellLink(spellID), dstname),addon.db.profile.PolyOut)	
  end 
end

-- function addon:PLAYER_()

-- end


--[[
local Arcanesignslack = {}
table.insert(Arcanesignslack, srcname)  -- unit.name ???



local Arcanesignslack = {"Педрокан", "Педрокан", "Педрокан", "Педрокан", "Педрокан", "Fyldonor", "Фалафель", "Педрокан", "Педрокан", "Педрокан", "Педрокан", "Fyldonor", "Фалафель", "Педрокан", "Педрокан", "Педрокан", "Педрокан", "Fyldonor", "Фалафель", "Педрокан", "Педрокан", "Fyldonor",}
local Arcanesignslack2 = {}

for i,v in ipairs(Arcanesignslack) do
Arcanesignslack2[v] = (Arcanesignslack2[v] or 0 ) +1    
--print("Знак передали " .. i .. " is " .. v .. ".")
end


local s = ""
local max = -math.huge
for k,v in pairs(Arcanesignslack2) do
max = math.max(max, v)
s = s .. k .. ":" .. v .. "\n" 
end

--print(s .. " передал знак на " .. max .. " игроков.")
print(s)
]]

--[[
local Arcanesignslack = {}
table.insert(Arcanesignslack, srcname)  -- unit.name ???

local Arcanesignslack2 = {}
local Arcanesignslack3 = {}

for i,v in ipairs(Arcanesignslack) do
Arcanesignslack2[v] = (Arcanesignslack2[v] or 0 ) +1
end

local max = -math.huge
for v,k in pairs(Arcanesignslack2) do 
--table.sort(Arcanesignslack2)
max = math.max(max, k)
-- k - ник, v - число 
if k >= 4 then
print(k .. " : " ..  v)          
end
end
]]