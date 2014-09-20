# BigMachines

[![Build Status](https://travis-ci.org/TinderBox/big_machines.png)](https://travis-ci.org/TinderBox/big_machines)

Ruby gem for the undocumented BigMachines SOAP API

### Implemented Operations

* Security API - login, logout, getUserInfo, setSessionCurrency
* Commerce API - getTransaction, updateTransaction (partial)

### Services Not Implemented

* Configuration, Parts, Data Tables, Users, Groups, Exchange Rates


## Installation

Add this line to your application's Gemfile:

    gem 'big_machines'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install big_machines

## Usage


#### Create Client

```ruby
client = BigMachines::Client.new('subdomain')
```

```ruby
# Specify process name
client = BigMachines::Client.new('subdomain', process_name: 'quotes_process')
```


#### Authenticate

```ruby
client.login('foo', 'password')
```

### set_session_currency

```ruby
client.set_session_currency('USD')
# => Hash[:status]
```

### get_user_info

```ruby
client.get_user_info
# => Hash[:user_info]
```

### get_transaction

```ruby
# Find transaction by id
client.get_transaction(id)
# => BigMachines::Transaction
```

### update_transaction

```ruby
# Update transaction (quote_process)
client.update_transaction(id, data={notesCMPM_es: "Sample Notes"})
# => Hash[:status]
```


### logout

```ruby
client.logout
```


## Contributing

1. Fork it ( http://github.com/TinderBox/big_machines/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
