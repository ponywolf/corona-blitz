-- playing card module

local M = {}
local id = 1

local function distance ( objA, objB )
  local dx = objA.x - objB.x
  local dy = objA.y - objB.y
  return math.sqrt ( dx * dx + dy * dy )
end

function M.new(front, back, name)
  local instance = display.newGroup()

  back = back or "scene/game/img/cardBack.png"
  front = front or "scene/game/img/"
  
  local cardNames = { "Chastity", "Temperance", "Charity", "Diligence", "Patience", "Kindness", "Humility",
    "Lust", "Gluttony", "Greed", "Sloth", "Wrath", "Envy", "Pride", }
  
  front = front .. cardNames[math.random(#cardNames)] ..".png"

  instance.face = display.newImageRect(instance, front, 128, 192)
  instance.back = display.newImageRect(instance, back, 128, 192)
  instance.face.isVisible = false
  instance.isShowing = false
  instance.type = "card"
  instance.name = id
  id = id + 1

  local function enterFrame()
    if not instance.toRotation then 
      instance.rotation = instance.rotation * 0.95
    end
  end

  function instance:touch( event )
    if event.phase == "began" then
      display.getCurrentStage():setFocus( self, event.id )
      self:toFront()
      self.isFocus = true
      self.markX = self.x
      self.markY = self.y
      self.xScale, self.yScale = 1.1, 1.1
    elseif self.isFocus then
      if event.phase == "moved" then
        self.x = event.x - event.xStart + self.markX
        self.y = event.y - event.yStart + self.markY
        self:rotate((event.x - event.xStart) * 0.0002)
      elseif event.phase == "ended" or event.phase == "cancelled" then
        local table = instance.parent.parent
        local slots = table:listTypes("slot")
        display.getCurrentStage():setFocus( self, nil )
        -- Am I in a slot?
        local placed = false
        for i = 1, #slots do
          if distance(self, slots[i]) < 64 then
            placed = true
            self.toRotation = true
            transition.to (self, { x = slots[i].x, y = slots[i].y,
                rotation = slots[i].rotation, xScale = 1, yScale = 1,
                time = 333, transition = easing.outBounce } )
          end
        end
        -- Am I on another card?
        local cards = table:listTypes("card")
        for i = 1, #cards do
          if distance(self, cards[i]) < 64 and not cards[i].name==self.name then
            cards[i].toRotation = false
            transition.to (cards[i], { x = cards[i]._x, y = cards[i]._y, 
                rotation = 0, xScale = 1, yScale = 1,
                time = 333, transition = easing.outBounce } )
          end
        end        
        if not placed then
          transition.to (self, { x = self._x, y = self._y, rotation = 0,
              xScale = 1, yScale = 1, time = 333,
              transition = easing.outBounce } )
          self.toRotation = nil
        end
        self.isFocus = false      
      end
    end
    return true
  end

  function instance:hide(fast)
    if fast then
      self.face.isVisible = false
      self.back.isVisible = true
      self.isShowing = false
    elseif self.isShowing == true then
      local function flip()
        self.isShowing = false
        self.face.isVisible = false
        self.face.xScale = 1
        self.back.isVisible = true
        self.back.xScale = 1
        transition.from (self.back, { xScale = 0.001, time = 166, transition = easing.outExpo } )
      end
      transition.to (self.face, { xScale = 0.001, time = 166, transition = easing.outExpo, onComplete = flip } )
    end
  end

  function instance:reveal(fast)
    if fast then
      self.face.isVisible = true
      self.back.isVisible = false
      self.isShowing = false
    elseif self.isShowing == false then
      local function flip()
        self.isShowing = false
        self.back.isVisible = false
        self.back.xScale = 1
        self.face.isVisible = true
        self.face.xScale = 1
        transition.from (self.face, { xScale = 0.001, time = 166, transition = easing.outQuad  } )
      end
      transition.to (self.back, { xScale = 0.001, time = 166, transition = easing.outQuad, onComplete = flip } )
    end
  end  

  function instance:finalize()
    Runtime:removeEventListener("enterFrame", enterFrame)
  end

  Runtime:addEventListener("enterFrame", enterFrame)
  instance:addEventListener("finalize")
  instance:addEventListener("touch")

  return instance
end

return M