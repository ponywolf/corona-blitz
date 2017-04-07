-- Requirements
local composer = require "composer"
local libworld = require "scene.game.lib.world"
local libcards = require "scene.game.lib.cards"
local ponytiled = require "com.ponywolf.ponytiled"
local snap = require "com.ponywolf.snap"
local json = require "json"

-- Variables local to scene
local scene = composer.newScene()
local hud, map
local hand = {}
local centerX, centerY = display.contentCenterX, display.contentCenterY  

function scene:create( event )
	local view = self.view -- add display objects to this group

	-- load sounds
	self.sounds = require "scene.game.sounds"

	-- or load a tiled map
	local data = json.decodeFile("scene/game/map/table.json")
	map = ponytiled.new(data, "scene/game/map")
	map:extend("label", "button")
	view:insert(map)

	-- create an HUD group
	hud = display.newGroup()
--	scene.score = display.newText{ text = "HUD GROUP", font = "scene/game/font/RobotoMono.ttf", fontSize = "32" }
	snap(scene.score, "topcenter", 16)
	view:insert(hud)

	local function ui(event)
		if event.phase == "released" then
			if event.buttonName == "deal" then
				scene:deal()
			elseif event.buttonName == "wipe" then
				scene:wipe()
			end
		end
	end

	Runtime:addEventListener("ui", ui)
	scene:deal()

end

function scene:deal( event )
	local view = self.view -- add display objects to this group
	local cardCount = 5
	local cardLayer = map:findLayer("cards")

	-- deal a hand 
	for i = 1, cardCount do
		hand[i] = libcards.new()
		cardLayer:insert(hand[i])
		hand[i].y = centerY * 2 - hand[i].contentHeight/1.75
		hand[i].x = centerX + (hand[i].contentWidth * (i-1)) - (hand[i].contentWidth * (cardCount / 2 - 0.5))
		hand[i]._x,hand[i]._y = hand[i].x,hand[i].y
	end

	-- show cards
	for i = 1, cardCount do
		local function flip()
			hand[i]:reveal()
		end
		transition.from( hand[i], { delay = i*133, y = centerY*3, transition = easing.outExpo, onComplete=flip })
	end	
end

function scene:wipe( event )
	local view = self.view -- add display objects to this group
	local cardLayer = map:findLayer("cards")

	-- remove a hand 
	for i = cardLayer.numChildren, 1, -1 do
		local function flip()
			display.remove(cardLayer[i])
		end
		transition.to( cardLayer[i], { delay = i*66, alpha = 0, transition = easing.outExpo, onComplete=flip })
	end

end

local function enterFrame(event)
	local elapsed = event.time

end

local function key(event)
	local phase, name = event.phase, event.keyName
	print(phase, name)
end

function scene:show( event )
	local phase = event.phase
	if ( phase == "will" ) then
		Runtime:addEventListener("enterFrame", enterFrame)
	elseif ( phase == "did" ) then
		Runtime:addEventListener( "key", key )
	end
end

function scene:hide( event )
	local phase = event.phase
	if ( phase == "will" ) then
		Runtime:removeEventListener( "key", key )
	elseif ( phase == "did" ) then
		Runtime:removeEventListener("enterFrame", enterFrame)
	end
end

function scene:destroy( event )
	audio.stop()
	for s,v in pairs( self.sounds ) do
		audio.dispose( v )
		self.sounds[s] = nil
	end
end

scene:addEventListener("create")
scene:addEventListener("show")
scene:addEventListener("hide")
scene:addEventListener("destroy")

return scene