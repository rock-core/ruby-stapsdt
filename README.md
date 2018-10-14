# USDT

Runtime definition of USDT (Dtrace) probes within Ruby programs

This gem allows one to define USDT probes on Linux, and then use the USDT tooling
to list and inspect them (mainly the bcc suite of tools)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'usdt'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install usdt

## Usage

An example should be worth a 1000 words. Let's create `example.rb` with:

```ruby
require 'usdt'

puts "PID: #{Process.pid}"

provider = USDT::Provider.new('example')

probe = provider.add_probe("test", String, Integer)
provider.load

i = 0
loop do
    probe.fire("some string", i += 1)
end
```

and run it with `bundle exec example.rb`

Then, `/usr/share/bcc/tools/tplist -p 25175 example:test` (replace 25175 with
the PID shown by the script) will display:

~~~
example:test [sema 0x0]
  1 location(s)
  2 argument(s)
~~~

Finally, `sudo /usr/share/bcc/tools/trace -p 25175 -M 10 'u::test "%s - %llu" arg1, arg2'`

~~~
PID     TID     COMM            FUNC             -
25175   25175   ruby            test             some string - -1241438585
25175   25175   ruby            test             some string - -1241438584
25175   25175   ruby            test             some string - -1241438583
25175   25175   ruby            test             some string - -1241438582
25175   25175   ruby            test             some string - -1241438581
25175   25175   ruby            test             some string - -1241438580
25175   25175   ruby            test             some string - -1241438579
25175   25175   ruby            test             some string - -1241438578
25175   25175   ruby            test             some string - -1241438577
25175   25175   ruby            test             some string - -1241438576
~~~

Note that the probes can be inspected and traced only after the provider has
been loaded. They won't appear until then.

## Thanks

Thanks to Matheus Marchini who wrote [this medium article](https://medium.com/sthima-insights/we-just-got-a-new-super-power-runtime-usdt-comes-to-linux-814dc47e909f)
showing the same capability on Node.js and Python. I would not even have
realized it was possible before that.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake test` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/rock-core/ruby-usdt. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Usdt project’s codebases, issue trackers, chat
rooms and mailing lists is expected to follow the [code of
conduct](https://github.com/[USERNAME]/usdt/blob/master/CODE_OF_CONDUCT.md).
