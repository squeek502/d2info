local Session = require('d2info.session')

local GameState = {}
GameState.__index = GameState

function GameState.new(reader, config, output)
  local self = setmetatable({}, GameState)

  self.reader = reader
  self.config = config
  self.output = output
  self.sessions = {}
  self.ingame = false

  return self
end

function GameState:inValidGame(multiplayer)
  return (multiplayer or self.reader:getGamePointer() ~= nil) and self.reader:getExperience() ~= nil
end

function GameState:inMultiplayerGame()
  return self.reader:getGamePointer() == nil and self.reader:getExperience() ~= nil
end

function GameState:inTown()
  return self.area and self.area.town == true
end

function GameState:isPaused()
  return not self.multiplayer and self.ingame and self.lastFrameNumber and self.lastFrameNumber == self.frameNumber
end

function GameState:setupCurrentSession()
  assert(self.player, "attempt to setup session for nil player")
  local maxTownDuration = self.config:get("MAX_TOWN_DURATION")
  if not self.sessions[self.player] then
    self.sessions[self.player] = {}
    self.sessions[self.player].total = Session.new(self.exp, self.level, maxTownDuration)
  end
  if self.sessions[self.player].current == nil then
    self.sessions[self.player].current = Session.new(self.exp, self.level, maxTownDuration)
  end
end

function GameState:onCurrentSessionEnd()
  local current = self.sessions[self.player].current
  self.sessions[self.player].total:onGameEnd(current)
  self.sessions[self.player].last = current
  self.sessions[self.player].current = nil
end

function GameState:currentSessionExists()
  return self.player ~= nil and self.sessions[self.player].current ~= nil
end

function GameState:getSessions()
  if self.ingame then
    return self.sessions[self.player]
  end
end

function GameState:tick(ms)
  self.multiplayer = self:inMultiplayerGame()
  self.ingame = self:inValidGame(self.multiplayer)
  if self.ingame then
    -- read current state
    self.player = self.reader:getPlayerName()
    self.exp, self.level = self.reader:getExperience()
    self.difficulty = self.reader:getDifficulty()
    self.area = self.reader:getArea()
    self.playersX = self.reader:getPlayersX()
    self.lastFrameNumber = self.frameNumber
    self.frameNumber = self.reader:getCurrentFrameNumber()

    self:setupCurrentSession()

    local current, total = self.sessions[self.player].current, self.sessions[self.player].total
    current:update(ms / 1000, self)
    total:update(ms / 1000, self)
  else
    if self:currentSessionExists() then
      self:onCurrentSessionEnd()
    end
  end

  if self.config:get("OUTPUT_TO_SCREEN") then
    self.output:toScreen(self)
  end
  if self.config:get("OUTPUT_TO_FILE") then
    self.output:toFile(self)
  end
end

return GameState
