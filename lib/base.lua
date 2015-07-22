local https = require("ssl.https")
local socket = require("socket")
local ltn12 = require("ltn12")
local cjson = require("cjson")

local url_public  = "https://public-api.mexbt.com"

--- meXBT Api Library
-- @class table
-- @name mexbt
-- @field currency_pair global currency pair. Default: "btcmxn"
local M = {
  currency_pair = "btcmxn",
}

local function call_public(method, params)
  local url = url_public .. "/v1/" .. method
  local source, length = ltn12.source.empty(), 0
  if params ~= nil then
    local json = cjson.encode(params);
    source = ltn12.source.string(json)
    length = #json
  end 
  
  local content = {}
  local success, errormsg = https.request{
    url = url,
    method = "POST",
    headers = {
      ["content-type"] = "application/json",
      ["content-length"] = length
    },
    source = source,
    sink = ltn12.sink.table(content)
  }
  if not success then error(errormsg) end
  -- if empty response --
  if next(content) == nil then return nil end
  
  return cjson.decode(table.concat(content))
end

--- Gets the current ticker data for a given currency pair
-- @param currency_pair currency pair string. Default: mexbt.currency_pair
-- @return json response in table form
function M.ticker(currency_pair)
  return call_public("ticker", {
    productPair = currency_pair or M.currency_pair
  })
end

--- Fetches past trades for a given currency pair
-- @param currency_pair currency pair string. Default: mexbt.currency_pair
-- @param start_index index of first trade to get (starting in 0),
--    use negative numbers to get most recents trades. Default: -1
-- @param count number of trades to return. Default: 10
-- @return json response in table form
function M.trades(currency_pair, start_index, count)
  return call_public("trades", {
    ins = currency_pair or M.currency_pair,
    startIndex = start_index or -1,
    count = count or 10
  })
end

--- Fetches past trades for a given currency pair and date period
-- @param currency_pair currency pair string. Default: mexbt.currency_pair
-- @param start_date timestamp of starting time (see funtion os.time)
-- @param end_date timestamp of ending time (see funtion os.time)
-- @return json response in table form
function M.trades_by_date(currency_pair, start_date, end_date)
  return call_public("trades-by-date", {
    ins = currency_pair or M.currency_pair,
    startDate = start_date,
    endDate = end_date
  })
end

--- Fetches the current orderbook for a given currency pair
-- @param currency_pair currency pair string. Default: mexbt.currency_pair
-- @return json response in table form
function M.order_book(currency_pair)
  return call_public("order-book", {
    productPair = currency_pair or M.currency_pair
  })
end

--- Gets the currency pairs currently trades on meXBT
-- @return json response in table form
function M.currency_pairs()
  return call_public("product-pairs")
end

return M;
