
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ruby_101/version"

Gem::Specification.new do |spec|
  spec.name          = "ruby_101"
  spec.version       = Ruby101::VERSION
  spec.authors       = ["Paul Sonkoly"]
  spec.email         = ["sonkoly.pal@gmail.com"]

  spec.summary       = %q{A book about random stuff that might bite you in Ruby}
  spec.description   = %q{Random stuff I found on the internet, all vvery surprising in ruby. So much for the concept of least sursprise.}
  spec.homepage      = "http://github.com/phaul/ruby_101"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'coderay'
  spec.add_development_dependency 'redcarpet'
end
