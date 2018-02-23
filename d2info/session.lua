local constants = require('d2info.constants')
local utils = require('d2info.utils')

local Session = {}
Session.__index = Session

function Session.new(startExp, startLevel, maxDurationPerTown)
  local self = setmetatable({}, Session)
  self.startTime = os.time()
  self.immutableStartTime = self.startTime
  self.duration = 0
  self.townDurations = {}
  self.maxDurationPerTown = maxDurationPerTown
  self.startExp = startExp
  self.exp = startExp
  self.startLevel = startLevel
  self.level = startLevel
  self.runs = 0
  self.runsTotalDuration = 0
  return self
end

function Session:update(dt, state)
  -- we can safely skip updating anything during a pause
  if state:isPaused() then return end

  if state:inTown() then
    self.townDurations[state.area.act] = (self.townDurations[state.area.act] or 0) + dt
  end
  self.duration = self.duration + dt
  -- reset the session on level up, because the amount of
  -- exp gained changes depending on your level
  if state.level > self.level then
    self.startTime = os.time()
    self.duration = 0
    self.townDurations = {}
    self.startExp = state.exp
  end
  self.exp = state.exp
  self.level = state.level
end

function Session:expGained()
  return self.exp - self.startExp
end

function Session:ticksGained()
  local gainedIntoLevel = constants.experience[self.level] + self:expGained()
  return utils.expToTicks(gainedIntoLevel, self.level)
end

function Session:getAdjustedGameTime()
  if not self.maxDurationPerTown then return self.duration end
  local adjustment = 0
  for act=1,5 do
    if self.townDurations[act] and self.townDurations[act] > self.maxDurationPerTown then
      adjustment = adjustment + (self.townDurations[act] - self.maxDurationPerTown)
    end
  end
  return self.duration - adjustment
end

local function expPerMin(expGained, duration)
  local mins = duration / 60
  if mins == 0 then return 0 end
  return expGained / mins
end

function Session:realTimeExpPerMin()
  return expPerMin(self:expGained(), os.time() - self.startTime)
end

function Session:durationExpPerMin()
  return expPerMin(self:expGained(), self:getAdjustedGameTime())
end

local function secondsToNextLevel(exp, level, expGained, duration)
  if level == 99 or expGained == 0 then return nil end
  local expNeeded = constants.experience[level+1] - exp
  local expPerMin = expPerMin(expGained, duration)
  local minsNeeded = expNeeded / expPerMin
  return minsNeeded * 60
end

function Session:realTimeToNextLevel()
  return secondsToNextLevel(self.exp, self.level, self:expGained(), os.time() - self.startTime)
end

function Session:gameTimeToNextLevel()
  return secondsToNextLevel(self.exp, self.level, self:expGained(), self:getAdjustedGameTime(self.maxDurationPerTown))
end

function Session:onGameEnd(endedSession)
  self.runs = self.runs + 1
  self.expPerRun = self:expGained() / self.runs
  self.runsTotalDuration = self.runsTotalDuration + endedSession:getAdjustedGameTime()
end

function Session:averageExpPerRun()
  return self.expPerRun
end

function Session:averageExpPerMinPerRun()
  return self:averageExpPerRun() / (self:averageGameTimePerRun() / 60)
end

function Session:averageGameTimePerRun()
  if self.runs == 0 then return nil end
  return self.runsTotalDuration / self.runs
end

function Session:runsToNextLevel()
  if self.runs == 0 or self.expPerRun == 0 then return nil end
  local expNeeded = constants.experience[self.level+1] - self.exp
  local runsNeeded = expNeeded / self.expPerRun
  return runsNeeded
end

return Session
