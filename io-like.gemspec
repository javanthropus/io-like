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
    LICENSE
    NEWS.md
    README.md
    lib/io/like-1.8.6.rb
    lib/io/like-1.8.7.rb
    lib/io/like.rb
  )
end
