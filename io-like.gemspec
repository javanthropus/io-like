# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = 'io-like'
  s.version     = '0.3.1'
  s.licenses    = ['MIT']
  s.platform    = Gem::Platform::RUBY
  s.authors     = [
    'Jeremy Bopp',
    'Jarred Holman',
    'Grant Gardner',
    'Jordan Pickwell'
  ]
  s.email       = %w(
    jeremy@bopp.net
    jarred.holman@gmail.com
    grant@lastweekend.com.au
    jpickwell@users.noreply.github.com
  )
  s.homepage    = 'http://github.com/javanthropus/io-like'
  s.summary     = 'An abstract class which provides the functionality of an IO object to any descendent class which provides a couple of simple methods.'
  s.description = <<-EOD
The IO::Like class provides the methods of an IO object based upon on a few
simple methods provided by the descendent class: unbuffered_read,
unbuffered_write, and unbuffered_seek.  These methods provide the underlying
read, write, and seek support respectively, and only the method or methods
necessary to the correct operation of the IO aspects of the descendent class need
to be provided.  Missing functionality will cause the resulting object to appear
read-only, write-only, and/or unseekable depending on which underlying methods
are absent.
  EOD

  s.required_ruby_version = '>= 1.8.1'

  s.add_development_dependency('rake', '~> 10.3')
  s.add_development_dependency('mspec', '~> 1.5')
  s.add_development_dependency('yard', '~> 0.8')
  s.add_development_dependency('yard-redcarpet-ext', '~> 0.0')
  s.add_development_dependency('github-markup', '~> 1.2')
  if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('1.9.2')
    s.add_development_dependency('redcarpet', '~> 3.1')
  end


  s.has_rdoc    = true
  s.extra_rdoc_files = %w(
    LICENSE
    LICENSE-rubyspec
    NEWS.md
    README.md
  )
  s.rdoc_options  << '--title' << 'IO::Like Documentation' <<
                     '--charset' << 'utf-8' <<
                     '--line-numbers' << '--inline-source'

  s.files       = %w(
    .yardopts
    LICENSE
    LICENSE-rubyspec
    NEWS.md
    README.md
    Rakefile
    lib/io/like-1.8.6.rb
    lib/io/like-1.8.7.rb
    lib/io/like.rb
    lib/io/like/buffer.rb
    lib/io/like/version.rb
  )

  s.test_files = %w(
    ruby.1.8.mspec
    spec/binmode_spec.rb
    spec/close_read_spec.rb
    spec/close_spec.rb
    spec/close_write_spec.rb
    spec/closed_spec.rb
    spec/each_byte_spec.rb
    spec/each_line_spec.rb
    spec/each_spec.rb
    spec/eof_spec.rb
    spec/fixtures/classes.rb
    spec/fixtures/gets.txt
    spec/fixtures/numbered_lines.txt
    spec/fixtures/one_byte.txt
    spec/fixtures/paragraphs.txt
    spec/fixtures/readlines.txt
    spec/flush_spec.rb
    spec/getc_spec.rb
    spec/gets_spec.rb
    spec/isatty_spec.rb
    spec/lineno_spec.rb
    spec/output_spec.rb
    spec/pos_spec.rb
    spec/print_spec.rb
    spec/printf_spec.rb
    spec/putc_spec.rb
    spec/puts_spec.rb
    spec/read_spec.rb
    spec/readchar_spec.rb
    spec/readline_spec.rb
    spec/readlines_spec.rb
    spec/readpartial_spec.rb
    spec/rewind_spec.rb
    spec/seek_spec.rb
    spec/shared/each.rb
    spec/shared/eof.rb
    spec/shared/pos.rb
    spec/shared/tty.rb
    spec/shared/write.rb
    spec/sync_spec.rb
    spec/sysread_spec.rb
    spec/sysseek_spec.rb
    spec/syswrite_spec.rb
    spec/tell_spec.rb
    spec/to_io_spec.rb
    spec/tty_spec.rb
    spec/ungetc_spec.rb
    spec/write_spec.rb
    spec_helper.rb
  )
end
