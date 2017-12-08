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

-- Write to the console by overwriting the line using CR
-- Uses spaces to cover up the last message when needed
local lastLen = 0
function utils.consoleWrite(msg)
  local len = #msg
  io.write('\r')
  io.write(msg)
  if len < lastLen then
    io.write(string.rep(' ', lastLen-len))
  end
  lastLen = len
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
    return "∞"
  elseif days and seconds > secondsPerDay then
    return string.format("%ud%02uh", math.floor(seconds / secondsPerDay), (seconds % secondsPerDay) / secondsPerHour)
  elseif seconds > secondsPerHour*10 then
    return string.format("%uh", math.floor(seconds / secondsPerHour))
  elseif seconds > secondsPerHour then
    return string.format("%uh%um", math.floor(seconds / secondsPerHour), (seconds % secondsPerHour) / secondsPerMin)
  else
    return string.format("%um%02us", math.floor(seconds / secondsPerMin), seconds % secondsPerMin)
  end
end

return utils
