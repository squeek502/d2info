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
  if num > 1000000 then
    return string.format("%0.2fm", num / 1000000)
  elseif num > 1000 then
    return string.format("%0.1fk", num / 1000)
  end
  return string.format("%u", num)
end

local secondsPerMin = 60
local secondsPerHour = secondsPerMin * 60
local secondsPerDay = secondsPerHour * 24
function utils.friendlyTime(seconds, days)
  if seconds == nil then
    return "-"
  elseif days and seconds >= secondsPerDay then
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

return utils
