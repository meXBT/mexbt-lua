require 'busted.runner'()
local mexbt = require('mexbt')
mexbt.account = require('mexbt.account')

describe("meXBT Private", function()
  local account = mexbt.account.new(
    "xxx", -- Public Key
    "xxx", -- Private Key
    "xxx", -- User Id
    true   -- sandbox
  )
  
  it("gives a valid response to all public api functions that require no args", function()
    local flist = {"orders", "cancel_all_orders", "info", "balance", "deposit_addresses"};
    for i,fname in ipairs(flist) do
      assert.is_true(account[fname](account).isAccepted)
    end
  end)
  
  it("allows passing a custom currency pair to functions that accept it", function()
    local flist = {"trades", "cancel_all_orders"};
    for i,fname in ipairs(flist) do
      assert.is_true(account[fname](account, 'BTCUSD').isAccepted)
    end
  end)
  
  it("allows creating market orders", function()
    local result = account:create_order{ amount = 0.1, currency_pair = "BTCUSD" }
    assert.is_true(result.isAccepted)
    assert.is_not_nil(tonumber(result.serverOrderId))
  end)
  
  it("allows creating orders with 8 decimal places", function()
    local result = account:create_order{ amount = 0.12345678, currency_pair = "BTCUSD" }
    assert.is_true(result.isAccepted)
    assert.is_not_nil(tonumber(result.serverOrderId))
  end)
  
  it("allows creating limit orders", function()
    local result = account:create_order{ type = "limit", price = 100, amount = 0.1234, currency_pair = "BTCUSD" }
    assert.is_true(result.isAccepted)
    assert.is_not_nil(tonumber(result.serverOrderId))
  end)
  
  describe("modifying and cancelling orders", function()
    local order_id = account:create_order{ type = "limit", price = 100, amount = 0.1, currency_pair = "BTCUSD" }.serverOrderId
    
    it("allows converting limit orders to market orders", function()
      local result = account:modify_order(order_id, "execute_now", "BTCUSD")
      assert.is_true(result.isAccepted)
    end)
    
    it("allows moving orders to the top of the book", function()
      local result = account:modify_order(order_id, "move_to_top", "BTCUSD")
      assert.is_true(result.isAccepted)
    end)
    
    it("allows cancelling individual orders", function()
      local result = account:cancel_order(order_id, "BTCUSD")
      assert.is_true(result.isAccepted)
      local orders = account:orders().openOrdersInfo
      for i, open_orders in ipairs(orders) do
        if open_orders.ins == "BTCUSD" then
          for j, order in ipairs(open_orders.openOrders) do
            assert.is_false(order.ServerOrderId == order_id)
          end
        end
      end
    end)
    
    it("allows cancelling all orders", function()
      local result = account:cancel_all_orders("BTCUSD")
      assert.is_true(result.isAccepted)
      local orders = account:orders().openOrdersInfo
      for i, open_orders in ipairs(orders) do
        if open_orders.ins == "BTCUSD" then
          assert.is_true(#open_orders.openOrders == 0)
        end
      end
    end)
  end)
  
end)
