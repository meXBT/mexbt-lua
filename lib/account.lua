local https = require("ssl.https")
local socket = require("socket")
local ltn12 = require("ltn12")
local cjson = require("cjson")
local hmac = require("mexbt.hmac")
local mexbt = require("mexbt")

local url_private = "https://private-api.mexbt.com"
local url_sandbox = "https://private-api-sandbox.mexbt.com"

--- Account configuration for Private API
-- @class table
-- @name mexbt.account
-- @field public_key Public API Key
-- @field private_key Private API Key
-- @field user_id account email identification
-- @field currency_pair currency pair for this account. Default: global currency pair
-- @field sandbox uses sandbox server. Default: false
local M = {}
M.__index = M
setmetatable(M, {__call = function(cls,...) return cls.new(...) end})

local function is_sandbox(account)
  if account.sandbox ~= null then
    return account.sandbox end
  return M.sandbox
end

local function call_private(account, method, params)
  if account.public_key == nil or account.private_key == nil then
    error("You must configure your API keys!")
  elseif account.user_id == nil then
    error("You must configure your user_id!")
  end
  
  if params == nil then params = {} end
  params.apiKey = account.public_key
  params.apiNonce = math.floor(socket.gettime() * 1000)
  params.apiSig = hmac.tohex(hmac.sha256(params.apiNonce .. account.user_id .. account.public_key, account.private_key))
  params = cjson.encode(params);
  
  local url = url_private
  if is_sandbox(account) then url = url_sandbox end
  url = url .. "/v1/" .. method
  
  local content = {}
  local success, errormsg, headers = https.request{
    url = url,
    method = "POST",
    headers = {
      ["content-type"] = "application/json",
      ["content-length"] = #params
    },
    source = ltn12.source.string(params),
    sink = ltn12.sink.table(content)
  }
  
  if not success then error(errormsg) end
  -- if empty response --
  if next(content) == nil then return nil end
  
  return cjson.decode(table.concat(content))
end

local function format_amount(account, amount)
  if(is_sandbox(account)) then
    return string.format("%.6f", amount) end
  return tostring(amount)
end

--- Creates an Account Configuration
-- this function supports named parameters in the following syntax:
-- mexbt.account.new{
--   public_key = "XXX",
--   private_key = "XXX",
--   user_id = "my@email",
--   currency_pair = "btcmxn",  -- Optional, default uses global config
--   sandbox = true             -- Optional, default is false
-- }
-- @param public_key Public API Key
-- @param private_key Private API Key
-- @param user_id account email identification
-- @param sandbox uses sandbox server. Default: false
function M.new(public_key, private_key, user_id, sandbox)
  local self = setmetatable({}, M)
  if(type(public_key) == "table") then
    self.public_key     = public_key.public_key
    self.private_key    = public_key.private_key
    self.user_id        = public_key.user_id
    self.currency_pair  = public_key.currency_pair
    self.sandbox        = public_key.sandbox
  else
    self.public_key     = public_key
    self.private_key    = private_key
    self.user_id        = user_id
    self.sandbox        = sandbox
  end
  
  return self
end

--- Creates a market or limit order
-- this function supports named parameters in the following syntax:
-- my_account:create_order{
--   currency_pair = "btcmxn",      -- Default: local or global currency pair
--   amount = 1.0,
--   side = "buy",
--   type = "market",
--   price = 342.99                 -- not used with market type
-- }
-- @param amount quantity to purchase or sell (or named parameters)
-- @param side "buy" or "sell". Default: "buy"
-- @param type "market" or "limit". Default: "market"
-- @param price price for transaction (market type don't use it)
-- @param currency_pair currency pair string. Default: local or global currency pair
-- @return json response in table form
function M:create_order(amount, side, _type, price, currency_pair)
  local params
  if type(amount) == "table" then
    params = {
      ins = amount.currency_pair or self.currency_pair or mexbt.currency_pair,
      qty = format_amount(self, amount.amount),
      orderType = amount.type or "market",
      side = amount.side or "buy",
      px = amount.price,
    }
  else
    params = {
      ins = currency_pair or self.currency_pair or mexbt.currency_pair,
      qty = format_amount(self, amount),
      orderType = _type or "market",
      side = side or "buy",
      px = price,
    }
  end

  if params.orderType == "market" then params.orderType = 1
  elseif params.orderType == "limit" then params.orderType = 0
  elseif params.orderType == 1 or params.orderType == 0 then --do nothing
  else error("Unknown order type '"..tostring(params.type).."'") end
  
  return call_private(self, "orders/create", params)
end

--- Cancels an order
-- @param id order id
-- @param currency_pair currency pair string. Default: local or global currency pair
-- @return json response in table form
function M:cancel_order(id, currency_pair)
  return call_private(self, "orders/cancel", {
    ins = currency_pair or self.currency_pair or mexbt.currency_pair,
    serverOrderId = id
  })
end 

--- Modifies an order
-- @param id order id
-- @param action "move_to_top" or "execute_now"
-- @param currency_pair currency pair string. Default: local or global currency pair
-- @return json response in table form
function M:modify_order(id, action, currency_pair)
  if action == "move_to_top" then action = 0
  elseif action == "execute_now" then action = 1
  elseif action == 1 or action == 0 then --do nothing
  else error('Action must be one of: "move_to_top", "execute_now"') end
  return call_private(self, "orders/modify", {
    ins = currency_pair or self.currency_pair or mexbt.currency_pair,
    serverOrderId = id,
    modifyAction = action
  })
end 

--- Cancels all orders for a givan currency pair
-- @param currency_pair currency pair string. Default: local or global currency pair
-- @return json response in table form
function M:cancel_all_orders(currency_pair)
  return call_private(self, "orders/cancel-all", {
    ins = currency_pair or self.currency_pair or mexbt.currency_pair
  })
end

--- Fetches account information
-- @return json response in table form
function M:info()
  return call_private(self, "me")
end

--- Fetches balance information 
-- @return json response in table form
function M:balance()
  return call_private(self, "balance")
end

--- Fetches trade history
-- @param currency_pair currency pair string. Default: mexbt.currency_pair
-- @param start_index index of first trade to get (starting in 0),
--    use negative numbers to get most recents trades. Default: -1
-- @param count number of trades to return. Default: 10
-- @return json response in table form
function M:trades(currency_pair, start_index, count)
  return call_private(self, "trades", {
    ins = currency_pair or M.currency_pair,
    startIndex = start_index or -1,
    count = count or 10
  })
end

--- Fetches open orders
-- @return json response in table form
function M:orders()
  return call_private(self, "orders")
end

--- Fetches all deposit addresses for depositing
-- @return json response in table form
function M:deposit_addresses()
  return call_private(self, "deposit-addresses")
end

--- Gets deposit address for depositing of specific currency
-- @param currency currency to find the address
-- @return json response in table form
function M:deposit_address(currency)
  local result = call_private(self, "deposit-addresses");
  for address in result.addresses do
    if address.name:upper() == currency:upper() then return address.depositAddress end
  end
  return nil
end

--- Withdraw crypto currency
-- @param amount amount to withdraw
-- @param address deposit address
-- @param currency currency type. ("btc", "ltc", ...)
-- @return json response in table form
function M:withdraw(amount, address, currency)
  amount = format_amount(self, amount)
  local response = call_private(self, "withdraw", {
    ins = currency,
    amount = amount,
    sendToAddress = address
  })
  if response == nil and is_sandbox(self) then error("Withdrawals do not work on the sandbox") end
  return response
end

return M
