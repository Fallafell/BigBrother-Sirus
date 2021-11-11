-- All SpellIDs go here
local addonName, vars = ...
vars.SpellData = {}

vars.SpellData.foods = {
	35272, -- Well Fed
	44106, -- "Well Fed" from Brewfest
	43730, -- Electrified
	43722, -- Enlightened
	43763, -- Food (eating)	
}

vars.SpellData.flasks = {
	-- Burning Crusade
	17626, -- 17626 Flask of the Titans
	17627, -- 17627 Flask of Distilled Wisdom 
	17628, -- 17628 Flask of Supreme Power 
	17629, -- 17629 Flask of Chromatic Resistance 
	28518, -- 28518 Flask of Fortification
	28519, -- 28519 Flask of Mighty Restoration 
	28520, -- 28520 Flask of Relentless Assault 
	28521, -- 28521 Flask of Blinding Light 
	28540, -- 28540 Flask of Pure Death 
	33053, -- 33053 Mr. Pinchy's Blessing
	42735, -- 42735 Flask of Chromatic Wonder 
	40567, -- 40567 Unstable Flask of the Bandit
	40568, -- 40568 Unstable Flask of the Elder
	40572, -- 40572 Unstable Flask of the Beast
	40573, -- 40573 Unstable Flask of the Physician
	40575, -- 40575 Unstable Flask of the Soldier
	40576, -- 40576 Unstable Flask of the Sorcerer
	41608, -- 41608 Relentless Assault of Shattrath
	41609, -- 41609 Fortification of Shattrath
	41610, -- 41610 Mighty Restoration of Shattrath
	41611, -- 41611 Sureme Power of Shattrath
	46837, -- 46837 Pure Death of Shattrath
	46839, -- 46839 Blinding Light of Shattrath
	-- Flask WotLK
	53752, -- 53752 Lesser Flask of Toughness
	53755, -- 53755 Flask of the Frost Wyrm
	53758, -- 53758 Flask of Stoneblood
	54212, -- 54212 Flask of Pure Mojo
	53760, -- 53760 Flask of Endless Rage
	62380, -- Lesser Flask of Resistance
    67019, -- Flask of the North	
  	-- Flask Sirus
	270005, -- 270005 Flask of Toughness
	270006, -- 270006 Flask of Resistance
	270007, -- 270007 Flask of the Draconic Mind
	270008, -- 270008 Flask of Titanic Strength
	270009, -- 270009 Flask of Flowing Water
	270010, -- 270010 Flask of Steelskin
}

vars.SpellData.elixirsGuardian = {
	-- Classic Wow
	11348, -- 11348 Greater Armor 
	11396, -- 11396 Greater Intellect 
	24363, -- 24363 Mana Regeneration 
	-- Burning Crusade
	28502, -- 28502 Major Armor 
	28509, -- 28509 Greater Mana Regeneration 
	28514, -- 28514 Empowerment 
	39625, -- 39625 Elixir of Major Fortitude 
	39627, -- 39627 Elixir of Draenic Wisdom 
	39628, -- 39628 Elixir of Ironskin
	39626, -- 39626 Earthen Elixir  
	-- WotLK
	53747, -- 53747 Elixir of Spirit 
	60347, -- 60347 Elixir of Mighty Thoughts 
	53764, -- 53764 Elixir of Mighty Mageblood 
	53751, -- 53751 Elixir of Mighty Fortitude 
	60343, -- 60343 Elixir of Mighty Defense 
	53763, -- 53763 Elixir of Protection	
}

vars.SpellData.elixirsBattle = {
	-- Classic Wow
	11390, -- 11390 Arcane Elixir
	11406, -- 11406 Elixir of Demonslaying
	17538, -- 17538 Elixir of the Mongoose
	17539, -- 17539 Greater Arcane Elixir 
    11474, -- 11474 Shadow Power
    26276, -- 26726 Greater Firepower	
	-- Burning Crusade
	28490, -- 28490 Major Strength 
	28491, -- 28491 Healing Power 
	28493, -- 28493 Major Frost Power 
	28501, -- 28501 Major Firepower 
	28503, -- 28503 Major Shadow Power 
	33720, -- 33720 Onslaught Elixir 
	33721, -- 33721 Spellpower Elixir
	33726, -- 33726 Elixir of Mastery 
	38954, -- 38954 Fel Strength Elixir
	45373, -- 45373 Bloodberry 
	54452, -- 54452 Adept's Elixir 
	54494, -- 54494 Major Agility 
	-- WotLK
	53746, -- 53746 Wrath Elixir
	53749, -- 53749 Guru's Elixir
	53748, -- 53748 Elixir of Mighty Strength
	28497, -- 53748 Elixir of Mighty Agility
--	60346, -- 60346 Elixir of Lightning Speed --- надо исправить 
	60344, -- 60344 Elixir of Expertise
	60341, -- 60341 Elixir of Deadly Strikes
	60345, -- 60345 Elixir of Armor Piercing
	60340, -- 60340 Elixir of Accuracy
}

vars.SpellData.ccspells = {
	118, -- Polymorph
	9484, -- Shackle Undead
	18658, -- Hibernate
	14309, -- Freezing Trap Effect
	60210, -- Freezing Arrow Effect
	6770, -- Sap
	20066, -- Repentance
	5782, -- Fear
	2094, -- Blind
	51514, -- Hex
}

vars.SpellData.brezSpells = {
  21169, -- Перерождение
  47882, -- Камень души
}

vars.SpellData.brezSpellsTwo = {
  20484, -- БР 
}

vars.SpellData.rezSpells = {
  7328,  -- Redemption (Paladin)
  2008,  -- Ancestral Spirit (Shaman)
  50769, -- Revive (Druid)
  2006,  -- Resurrection (Priest)
  54732, -- Defibrillate (Engineer)
}

vars.SpellData.tauntSpells = {
  355,   -- Taunt (Warrior)
  694,   -- Mocking Blow (Warrior)  
  62124, -- Hand of Reckoning (Paladin)
  6795,  -- Growl (Druid)
  56222, -- Dark Command (Death Knight)
  49576, -- Death Grip (Death Knight)  
  20736, -- Distracting Shot (Hunter)  
}

vars.SpellData.aoetauntSpells = {
  1161,  -- Challenging Shout (Warrior)
  31789, -- Righteous Defense (Paladin)  
  5209,  -- Challenging Roar (Druid)
  59671, -- Challenging Howl (Warlock)  
}

vars.SpellData.pokesfish = {
  300061, -- баф при нажатии рыбы (Питье)
}

vars.SpellData.masloo = {
  317727, -- Рдд
  317728, -- Милли
}