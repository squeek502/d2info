local utils = require('d2info.utils')
local lfs = require('lfs')
local printf, friendlyNumber, friendlyTime, toFile = utils.printf, utils.friendlyNumber, utils.friendlyTime, utils.toFile
local expToPercentLeveled = utils.expToPercentLeveled

local Output = {}
Output.__index = Output

function Output.new(outputDir)
  local self = setmetatable({}, Output)
  self.outputDir = outputDir or "output"
  if not lfs.attributes(self.outputDir) then
    assert(lfs.mkdir(self.outputDir))
  end
  return self
end

function Output:buffer(str, ...)
  table.insert(self.buf, string.format(str, ...))
end

function Output:toScreen(state)
  os.execute('cls')
  self.buf = {}
  if state.ingame then
    local sessions = state:getSessions()
    local total, current, last = sessions.total, sessions.current, sessions.last
    self:buffer("%s (level %d & %.2f%%)", state.player, state.level, expToPercentLeveled(state.exp, state.level)*100)
    self:buffer("/players %d", state.playersX)

    if current then
      self:buffer("\nRun #%d:", total.runs+1)
      self:buffer(" %s xp/min (%s xp in %s)", friendlyNumber(current:durationExpPerMin()), friendlyNumber(current:expGained()), friendlyTime(current:getAdjustedGameTime()))
      self:buffer(" %s until level %d at this rate", friendlyTime(current:gameTimeToNextLevel()), state.level+1)
    end

    if last then
      self:buffer("\nLast run:")
      self:buffer(" %s xp/min (%s xp in %s)", friendlyNumber(last:durationExpPerMin()), friendlyNumber(last:expGained()), friendlyTime(last:getAdjustedGameTime()))
      self:buffer(" %s until level %d at this rate", friendlyTime(last:gameTimeToNextLevel()), state.level+1)
    end

    if total.runs > 0 then
      self:buffer("\nAverage run:")
      self:buffer(" %s xp/min (%s xp in %s)", friendlyNumber(total:averageExpPerMinPerRun()), friendlyNumber(total:averageExpPerRun()), friendlyTime(total:averageGameTimePerRun()))
      local runsNeeded = total:runsToNextLevel()
      self:buffer(" %s runs until level %d", runsNeeded and string.format("%d", runsNeeded) or "-", state.level+1)
    end

    if total then
      self:buffer("\nThis session:")
      local percentGain = expToPercentLeveled(state.exp, state.level) - expToPercentLeveled(total.startExp, state.level)
      self:buffer(" %s%.1f ticks (%s%.2f%%)", total:visualTicksGained() >= 0 and "+" or "", total:visualTicksGained(), percentGain >= 0 and "+" or "", percentGain*100)
      self:buffer(" Next visual tick in %s xp", friendlyNumber(utils.expToNextVisualTick(state.exp, state.level)))
      self:buffer(" %s xp/min (%s xp in %s)", friendlyNumber(total:durationExpPerMin()), friendlyNumber(total:expGained()), friendlyTime(total.runsTotalDuration + current:getAdjustedGameTime()))
      self:buffer(" %s until level %d at this rate", friendlyTime(total:gameTimeToNextLevel()), state.level+1)
    end

    --[[
    self:buffer("Real-time:")
    self:buffer(" %s xp/min (in %s)", friendlyNumber(total:realTimeExpPerMin()), friendlyTime(os.time() - total.startTime))
    self:buffer(" %s until level %d in real-time", friendlyTime(total:gameTimeToNextLevel()), state.level+1)
    ]]--

    if state.config:get("SHOW_AREA_INFORMATION") then
      if state.area and state.difficulty and not state.area.town then
        local alvl = state.area.alvl[state.difficulty.code]
        self:buffer("\n%s [%s] alvl=%d", state.area.name, state.difficulty.name, alvl)
        self:buffer("Experience gain at level %d: %0.4f%%", state.level, utils.expLevelPenalty(state.level)*100)
        self:buffer("Monsters (lvl%d): \t%0.4f%% exp", alvl, utils.expGain(alvl, state.level)*100)
        self:buffer("Champions (lvl%d): \t%0.4f%% exp", alvl+2, utils.expGain(alvl+2, state.level)*100)
        self:buffer("Uniques (lvl%d): \t%0.4f%% exp", alvl+3, utils.expGain(alvl+3, state.level)*100)
      end
    end
  else
    self:buffer(state.reader.status or "No player")
  end
  print(table.concat(self.buf, '\n'))
end

function Output:toFile(state)
  if self.buf and #self.buf > 0 then
    toFile(self.outputDir .. "/console-output.txt", table.concat(self.buf, '\n'))
  end

  local sessions = state:getSessions()
  if not sessions then return end
  local total, current, last = sessions.total, sessions.current, sessions.last
  toFile(self.outputDir .. "/xpmin-realtime.txt", friendlyNumber(total:realTimeExpPerMin()))
  toFile(self.outputDir .. "/xpmin-gametime.txt", friendlyNumber(total:durationExpPerMin()))
  toFile(self.outputDir .. "/xpmin-currentgame.txt", current and friendlyNumber(current:realTimeExpPerMin()) or "-")
  toFile(self.outputDir .. "/xpmin-lastgame.txt", last and friendlyNumber(last:durationExpPerMin()) or "-")
  toFile(self.outputDir .. "/timetolevel-realtime.txt", friendlyTime(total:realTimeToNextLevel()))
  toFile(self.outputDir .. "/timetolevel-gametime.txt", friendlyTime(total:gameTimeToNextLevel()))
  toFile(self.outputDir .. "/timetolevel-currentgame.txt", current and friendlyTime(current:gameTimeToNextLevel()) or "-")
  toFile(self.outputDir .. "/timetolevel-lastgame.txt", last and friendlyTime(last:gameTimeToNextLevel()) or "-")
  toFile(self.outputDir .. "/ticksgained-overall.txt", string.format("%0.1f", total:visualTicksGained()))
  toFile(self.outputDir .. "/ticksgained-currentgame.txt", current and string.format("%0.1f", current:visualTicksGained()) or "-")
  toFile(self.outputDir .. "/ticksgained-lastgame.txt", last and string.format("%0.1f", last:visualTicksGained()) or "-")
  toFile(self.outputDir .. "/run-number.txt", total.runs+1)
  toFile(self.outputDir .. "/runs-average-xpmin.txt", total.runs > 0 and friendlyNumber(total:averageExpPerMinPerRun()) or "-")
  toFile(self.outputDir .. "/runs-average-duration.txt", total.runs > 0 and friendlyTime(total:averageGameTimePerRun()) or "-")
  toFile(self.outputDir .. "/runs-average-xpgain.txt", total.runs > 0 and friendlyNumber(total:averageExpPerRun()) or "-")
  local runsNeeded = total:runsToNextLevel()
  toFile(self.outputDir .. "/runs-average-timetolevel.txt", runsNeeded and string.format("%d", runsNeeded) or "-")

  if total.lastTick and total.lastTick + state.config:get("TICK_PARTY_DURATION") > os.time() then
    toFile(self.outputDir .. "/tick-party.txt", "party")
  else
    toFile(self.outputDir .. "/tick-party.txt", "")
  end

  if state.ingame then
    toFile(self.outputDir .. "/level.txt", state.level)
    toFile(self.outputDir .. "/level-next.txt", state.level+1)
    toFile(self.outputDir .. "/players-x.txt", state.playersX)
    toFile(self.outputDir .. "/next-tick-in-xp.txt", friendlyNumber(utils.expToNextVisualTick(state.exp, state.level)))
  end
end

return Output
