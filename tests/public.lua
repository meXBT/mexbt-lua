require 'busted.runner'()
local mexbt = require('mexbt')

describe("meXBT", function()
  
  it("gives a valid response to all public api functions that require no args", function()
    local flist = {"ticker", "trades", "currency_pairs", "order_book"};
    for i,fname in ipairs(flist) do
      assert.is_true(mexbt[fname]().isAccepted)
    end
  end)
  
  it("allows passing a custom currency pair to functions that accept it", function()
    local flist = {"ticker", "trades", "order_book"};
    for i,fname in ipairs(flist) do
      assert.is_true(mexbt[fname]('BTCUSD').isAccepted)
    end
  end)
  
  it("allows you to fetch trades by date range", function()
    local result = mexbt.trades_by_date(nil, os.time(), os.time())
    assert.is_true(result.isAccepted)
    assert.is_true(#result.trades == 0)
  end)
  
end)
