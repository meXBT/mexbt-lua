# Mexbt lua API client

Lua client library for the [meXBT](https://mexbt.com) exchange API. JSON Responses are converted to lua tables.

## Install

This library uses `luarocks` as package manager. Read [How to install it on your System](https://github.com/keplerproject/luarocks/wiki/Download#installing)
After that run the following command:

```
luarocks install mexbt
```

To install it from source code clone the repository and in project folder run:

```
luarocks make
```

## Usage

The library is separated in 2 basic modules, `mexbt`(Public API) and `mexbt.account`(Private API).
To import both modules in a lua file, use:

```lua
mexbt = require("mexbt")
mexbt.account = require("mexbt.account")

-- Start using the library
mexbt.ticker()
```

## Public API

You can access all the Public API functions with zero configuration. By default they will use the 'BTCMXN' currency pair.

```lua
result = mexbt.ticker()
result = mexbt.order_book()
result = mexbt.trades(nil, -1, 20)
result = mexbt.trades_by_date("BTCUSD", os.time{year=2014, month=11, day=1}, os.time())
result = mexbt.currency_pairs()
```

If you want to choose another currency pair, you can configure it for all calls:

```lua
mexbt.currency_pair = "BTCUSD"
```

## Private API

### API Keys

You need to generate an API key pair at https://mexbt.com/api/keys. However if you want to get started quickly we recommend having a play in the sandbox first, see the 'Sandbox' section below.

### Creating an account configuration

To access the Private API, you need create a account configuration using your keys:

```lua
-- Direct Mode --
account = mexbt.account.new("my_public_key", "my_private_key", "my_user_id")

-- Named Parameters Mode --
account = mexbt.account.new{public_key = "aaa", private_key = "aaa", user_id = "aaa", currency_pair = "BTCUSD", sandbox = true}

-- Using the configuration
result = account:info()
result = mexbt.account.info(account)
```

### Library Functions

Public API

```lua
function mexbt.ticker(currency_pair)
function mexbt.trades(currency_pair, start_index, count)
function mexbt.trades_by_date(currency_pair, start_date, end_date)
function mexbt.order_book(currency_pair)
function mexbt.currency_pairs()
```

Private API

```lua
function mexbt.account.new(public_key, private_key, user_id, sandbox)
function Account:create_order(amount, side, _type, price, currency_pair)
function Account:cancel_order(id, currency_pair)
function Account:modify_order(id, action, currency_pair)
function Account:cancel_all_orders(currency_pair)
function Account:info()
function Account:balance()
function Account:trades(currency_pair, start_index, count)
function Account:orders()
function Account:deposit_addresses()
function Account:deposit_address(currency)
function Account:withdraw(amount, address, currency)
```

### Sandbox

It's a good idea to first play with the API in the sandbox, that way you don't need any real money to start trading with the API. Just make sure you configure `sandbox = true`.

You can register a sandbox account at https://sandbox.mexbt.com/en/register. It will ask you to validate your email but there is no need, you can login right away at https://sandbox.mexbt.com/en/login. Now you can setup your API keys at https://sandbox.mexbt.com/en/api/keys.

Your sandbox account will automatically have a bunch of cash to play with.

## API documentation

You can find API docs for the Public API at http://docs.mexbtpublicapi.apiary.io

API docs for the Private API are at http://docs.mexbtprivateapi.apiary.io

There are also docs for the Private API sandbox at http://docs.mexbtprivateapisandbox.apiary.io

## Testing Unit

The tests uses the `busted` library, you can install the library and run the tests with the following commands

```
luarocks install busted
busted tests/public.lua tests/private.lua
```


