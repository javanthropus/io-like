# IO::Like - in the Likeness of IO

A composable implementation of IO methods.

## LINKS

* Homepage :: http://github.com/javanthropus/io-like
* Documentation :: http://rdoc.info/gems/io-like/frames
* Source :: http://github.com/javanthropus/io-like

## DESCRIPTION

This gem makes it possible to build filters or pipelines for processing data
into or out of streams of bytes while maintaining compatibility with native Ruby
IO classes.  Ruby IO classes may function as both sources and sinks, or entirely
new IO implementations may be created.

## FEATURES

* All standard Ruby 2.7 to 3.4 IO methods.
* Buffered operations.
* Configurable buffer size.

## KNOWN BUGS/LIMITATIONS

* Ruby's finalization capabilities fall a bit short in a few respects, and as a
  result, it is impossible to cause the close, close_read, or close_write
  methods to be called automatically when a descendent class is garbage
  collected.  Use the class open method which guarantees that an appropriate
  close method will be called after executing a block.  Other than that, be
  diligent about calling the close methods.

## SYNOPSIS

More examples can be found in the `examples` directory of the source
distribution.

A simple ROT13 codec:

```ruby
require 'io/like'
require 'io/like_helpers/delegated_io'
require 'io/like_helpers/io_wrapper'

include IO::LikeHelpers

class ROT13Filter < DelegatedIO
  def self.io_like(delegate, **kwargs, &b)
    autoclose = kwargs.delete(:autoclose) { true }
    IO::Like.open(
      new(IOWrapper.new(delegate, autoclose: autoclose)),
      **kwargs,
      &b
    )
  end

  def read(length, buffer: nil, buffer_offset: 0)
    result = super
    if buffer.nil?
      encode_rot13(result)
    else
      encode_rot13(buffer, buffer_offset: buffer_offset)
    end
    result
  end

  def write(buffer, length: buffer.bytesize)
    super(encode_rot13(buffer[0, length]), length: length)
  end

  private

  def encode_rot13(buffer, buffer_offset: 0)
    buffer_offset.upto(buffer.length - 1) do |i|
      ord = buffer[i].ord
      case ord
      when 65..90
        buffer[i] = ((ord - 52) % 26 + 65).chr
      when 97..122
        buffer[i] = ((ord - 84) % 26 + 97).chr
      end
    end
    buffer
  end
end

if $0 == __FILE__
  IO.pipe do |r, w|
    w.puts('This is a test')
    w.close
    ROT13Filter.io_like(r) do |rot13|
      puts(rot13.read)                    # -> Guvf vf n grfg
    end
  end

  IO.pipe do |r, w|
    ROT13Filter.io_like(w) do |rot13|
      rot13.puts('This is a test')
    end
    puts(r.read)                          # -> Guvf vf n grfg
  end

  IO.pipe do |r, w|
    w.puts('Guvf vf n grfg')
    w.close
    ROT13Filter.io_like(r) do |rot13|
      puts(rot13.read)                    # -> This is a test
    end
  end

  IO.pipe do |r, w|
    w.puts('This is a test')
    w.close
    ROT13Filter.io_like(r) do |rot13|
      puts(rot13.each_line.to_a.inspect)  # -> ["Guvf vf n grfg\n"]
    end
  end

  IO.pipe do |r, w|
    w.puts('Guvf vf n grfg')
    w.close
    ROT13Filter.io_like(r) do |rot13|
      puts(rot13.each_line.to_a.inspect)  # -> ["This is a test\n"]
    end
  end

  IO.pipe do |r, w|
    w.puts('This is a test')
    w.close
    IO::Like.open(ROT13Filter.new(ROT13Filter.new(IOWrapper.new(r)))) do |rot26| # ;-)
      puts(rot26.read)                    # -> This is a test
    end
  end
end

# vim: ts=2 sw=2 et
```

## REQUIREMENTS

* None

## INSTALL

    $ gem install io-like

## DEVELOPERS

After checking out the source, run:

    $ bundle install
    $ bundle exec rake test yard

This will install all dependencies, run the tests/specs, and generate the
documentation.

## AUTHORS and CONTRIBUTORS

Thanks to all contributors.  Without your help this project would not exist.

* Jeremy Bopp :: jeremy@bopp.net
* Jarred Holman :: jarred.holman@gmail.com
* Grant Gardner :: grant@lastweekend.com.au
* Jordan Pickwell :: jpickwell@users.noreply.github.com

## CONTRIBUTING

Contributions for bug fixes, documentation, extensions, tests, etc. are
encouraged.

1. Clone the repository.
2. Fix a bug or add a feature.
3. Add tests for the fix or feature.
4. Make a pull request.

### CODING STYLE

The following points are not necessarily set in stone but should rather be used
as a good guideline.  Consistency is the goal of coding style, and changes will
be more easily accepted if they are consistent with the rest of the code.

* **File Encoding**
  * UTF-8
* **Indentation**
  * Two spaces; no tabs
* **Line length**
  * Limit lines to a maximum of 80 characters
* **Comments**
  * Document classes, attributes, methods, and code
* **Method Calls with Arguments**
  * Use `a_method(arg, arg, etc)`; **not** `a_method( arg, arg, etc )`,
    `a_method arg, arg, etc`, or any other variation
* **Method Calls without Arguments**
  * Use `a_method`; avoid parenthesis
* **String Literals**
  * Use single quotes by default
  * Use double quotes when interpolation is necessary
  * Use `%{...}` and similar when embedding the quoting character is cumbersome
* **Blocks**
  * `do ... end` for multi-line blocks and `{ ... }` for single-line blocks
* **Boolean Operators**
  * Use `&&` and `||` for boolean tests; avoid `and` and `or`
* **In General**
  * Try to follow the flow and style of the rest of the code

## LICENSE

```
(The MIT License)

Copyright (c) 2024 Jeremy Bopp

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

## RUBYSPEC LICENSE

Files under the `rubyspec` directory are copied in whole from the Rubyspec
project.

```
Copyright (c) 2008 Engine Yard, Inc. All rights reserved.

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
```
