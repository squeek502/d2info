local constants = require('d2info.constants')
local utils = {}

function utils.friendlyVersion(ver)
  return table.concat({ver.major, ver.minor, ver.build, ver.revision}, '.')
end

function utils.tableMerge(a, b)
  local merged = {}
  for k,v in pairs(b) do
    merged[k] = v
  end
  -- a overwrites any duplicates in b
  for k,v in pairs(a) do
    merged[k] = v
  end
  return merged
end

function utils.friendlyNumber(num)
  local abs = math.abs(num)
  if abs >= 1000000000 then
    return string.format("%0.1fb", num / 1000000000)
  elseif abs >= 1000000 then
    return string.format("%0.1fm", num / 1000000)
  elseif abs >= 1000 then
    return string.format("%0.1fk", num / 1000)
  end
  return string.format("%d", num)
end

local secondsPerMin = 60
local secondsPerHour = secondsPerMin * 60
local secondsPerDay = secondsPerHour * 24
function utils.friendlyTime(seconds, showDays)
  if seconds == nil or seconds < 0 then
    return "-"
  elseif showDays and seconds >= secondsPerDay then
    return string.format("%ud%02uh", math.floor(seconds / secondsPerDay), (seconds % secondsPerDay) / secondsPerHour)
  elseif seconds >= secondsPerHour*10 then
    return string.format("%uh", math.floor(seconds / secondsPerHour))
  elseif seconds >= secondsPerHour then
    return string.format("%uh%um", math.floor(seconds / secondsPerHour), (seconds % secondsPerHour) / secondsPerMin)
  elseif seconds >= secondsPerMin then
    return string.format("%um%02us", math.floor(seconds / secondsPerMin), seconds % secondsPerMin)
  else
    return string.format("%02usec", seconds)
  end
end

function utils.printf(...)
  print(string.format(...))
end

function utils.toFile(filename, txt)
  local f = assert(io.open(filename, "w"))
  f:write(txt)
  f:close()
end

function utils.expToPercentLeveled(exp, level)
  if level == 99 then return 0 end
  local expRange = constants.experience[level+1] - constants.experience[level]
  local expGotten = exp - constants.experience[level]
  return expGotten / expRange
end

-- Converts exp to GUI 'ticks' of the experience bar
function utils.expToTicks(exp, level)
  if level == 99 then return 0 end
  local maxTicks = constants.gui.expBar.ticks
  local percentLeveled = utils.expToPercentLeveled(exp, level)
  return percentLeveled * maxTicks
end

-- The GUI bar is full at 119 ticks rather than the full 120
-- (i.e. with the XP bar totally full there is still 1 tick left to gain)
-- so this can be used to determine whether or not a tick has actually
-- appeared on the XP bar GUI
function utils.expToVisualTicks(exp, level)
  if level == 99 then return 0 end
  local maxVisualTicks = constants.gui.expBar.ticks - 1
  local percentLeveled = utils.expToPercentLeveled(exp, level)
  return percentLeveled * maxVisualTicks
end

function utils.expToNextVisualTick(exp, level)
  if level == 99 then return 0 end
  local maxVisualTicks = constants.gui.expBar.ticks - 1
  local expRange = constants.experience[level+1] - constants.experience[level]
  local expGotten = exp - constants.experience[level]
  local expPerVisualTick = math.floor(expRange / maxVisualTicks)
  return expPerVisualTick - (expGotten % expPerVisualTick)
end

local underLevel25 = {
  [10] = 0.02, [9] = 0.15, [8] = 0.36, [7] = 0.68, [6] = 0.88, [-6] = 0.81, [-7] = 0.62, [-8] = 0.43, [-9] = 0.24, [-10] = 0.05
}
local level25Plus = {
  [-6] = 0.81, [-7] = 0.62, [-8] = 0.43, [-9] = 0.24, [-10] = 0.05
}
function utils.expLevelDifference(mlvl, clvl)
  local diff = mlvl-clvl
  if clvl < 25 then
    if underLevel25[diff] then
      return underLevel25[diff]
    elseif diff > 10 then
      return 0.02
    elseif diff < -10 then
      return 0.05
    else
      return 1.0
    end
  else
    -- For any monster above your level, you get EXP*(Player Level / Monster Level).
    if diff > 0 then
      return clvl / mlvl
    elseif level25Plus[diff] then
      return level25Plus[diff]
    elseif diff <= -10 then
      return 0.05
    else
      return 1.0
    end
  end
end

function utils.expLevelPenalty(clvl)
  return constants.experienceLevelPenalties[clvl] or 1
end

function utils.expGain(mlvl, clvl)
  return utils.expLevelDifference(mlvl, clvl) * utils.expLevelPenalty(clvl)
end

-- replace all non-whitespace characters with space characters
-- e.g. "ab\n \t c" should become "  \n \t  "
function utils.makeWhitespace(str)
  return str:gsub("[^\n\r\t ]", " ")
end

-- add space characters to a buf in order to
-- make it completely overwrite the previous buf
function utils.padBuf(cur, last)
  if not last then return cur end
  local padded = {}
  for i,v in ipairs(cur) do
    padded[i] = v
  end
  for i,v in ipairs(last) do
    if not cur[i] then
      padded[i] = utils.makeWhitespace(v)
    elseif #cur[i] < #v then
      local remainder = v:sub(#cur[i])
      padded[i] = cur[i] .. utils.makeWhitespace(remainder)
    end
  end
  return padded
end

return utils
