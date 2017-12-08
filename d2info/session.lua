local constants = require('d2info.constants')

local Session = {}
Session.__index = Session

function Session.new(startExp, startLevel)
  local self = setmetatable({}, Session)
  self.startTime = os.time()
  self.immutableStartTime = self.startTime
  self.duration = 0
  self.startExp = startExp
  self.exp = startExp
  self.startLevel = startLevel
  self.level = startLevel
  return self
end

function Session:update(exp, level)
  -- reset the session on level up, because the amount of
  -- exp gained changes depending on your level
  if level > self.level then
    self.startTime = os.time()
    self.duration = 0
    self.startExp = exp
  end
  self.exp = exp
  self.level = level
end

function Session:incrementDuration(inc)
  if inc == nil then inc = 1 end
  self.duration = self.duration + inc
end

local function expPerMin(expGained, duration)
  local mins = duration / 60
  if mins == 0 then return 0 end
  return expGained / mins
end

function Session:realTimeExpPerMin()
  return expPerMin(self.exp - self.startExp, os.time() - self.startTime)
end

function Session:durationExpPerMin()
  return expPerMin(self.exp - self.startExp, self.duration)
end

local function secondsToNextLevel(exp, level, expGained, duration)
  if level == 99 then return nil end
  local expNeeded = constants.experience[level+1] - exp
  local expPerMin = expPerMin(expGained, duration)
  local minsNeeded = expNeeded / expPerMin
  return minsNeeded * 60
end

function Session:realTimeToNextLevel()
  return secondsToNextLevel(self.exp, self.level, self.exp - self.startExp, os.time() - self.startTime)
end

function Session:gameTimeToNextLevel()
  return secondsToNextLevel(self.exp, self.level, self.exp - self.startExp, self.duration)
end

return Session
