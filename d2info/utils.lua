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

return utils
