local memreader = require('memreader')
local sleep = require('sleep')
local D2Reader = require('d2info.d2reader')
local Output = require('d2info.output')
local Config = require('d2info.config')
local GameState = require('d2info.gamestate')
local windcon = require('windcon')

memreader.debugprivilege(true)

local reader, output, config = D2Reader.new(), Output.new(), Config.new()
local state = GameState.new(reader, config, output)

local UPDATE_PERIOD = config:get("UPDATE_PERIOD")

windcon.clear()
windcon.showcursor(false)

while true do
  state:tick(UPDATE_PERIOD)
  sleep(UPDATE_PERIOD)
end
