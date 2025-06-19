# emanlib.gemspec
$LOAD_PATH.push File.expand_path("lib", __dir__)

Gem::Specification.new do |spec|
  spec.required_ruby_version = ">= 3.0.0"

  spec.name = "emanlib"
  spec.version = "1.0.0"
  spec.authors = ["emanrdesu"]
  spec.email = ["janitor@waifu.club"]

  spec.summary = %q{emanrdesu's personal library}
  spec.description = %q{Convenience methods and features, mostly done through monkey patching.}
  spec.homepage = "https://github.com/emanrdesu/lib"
  spec.license = "GPL-3.0-only"

  spec.files = Dir.glob("lib/**/*.rb")
  spec.require_paths = ["lib"]
end
