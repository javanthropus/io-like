Gem::Specification.new do |s|
  s.name        = 'io-like'
  s.version     = '0.4.0.pre1'
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
  s.summary     = 'A composable implementation of IO methods.'
  s.description = <<-EOD
This gem makes it possible to build filters or pipelines for processing data
into or out of streams of bytes while maintaining compatibility with native Ruby
IO classes.  Ruby IO classes may function as both sources and sinks, or entirely
new IO implementations may be created.
  EOD

  s.required_ruby_version = '>= 2.5.0'

  s.add_development_dependency('rake', '~> 13.0')
  s.add_development_dependency('yard', '~> 0.9')
  s.add_development_dependency('github-markup', '~> 3.0')
  s.add_development_dependency('redcarpet', '~> 3.1')
  s.add_development_dependency('simplecov', '~> 0.20.0')


  s.extra_rdoc_files = %w(
    LICENSE
    rubyspec/LICENSE
    NEWS.md
    README.md
  )
  s.rdoc_options  << '--title' << 'IO::Like Documentation' <<
                     '--charset' << 'utf-8' <<
                     '--line-numbers' << '--inline-source'

  s.files = %w(
    LICENSE
    NEWS.md
    README.md
    lib/io/like_helpers/abstract_io.rb
    lib/io/like_helpers/io_wrapper.rb
    lib/io/like_helpers/delegated_io.rb
    lib/io/like_helpers/duplexed_io.rb
    lib/io/like_helpers/buffered_io.rb
    lib/io/like.rb
  )
end
