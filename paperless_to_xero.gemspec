# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{paperless_to_xero}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Patterson"]
  s.date = %q{2009-07-21}
  s.default_executable = %q{paperless_to_xero}
  s.description = %q{}
  s.email = %q{matt@reprocessed.org}
  s.executables = ["paperless_to_xero"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["Rakefile", "README.rdoc", "bin/paperless_to_xero", "spec/fixtures", "spec/fixtures/multi-foreign.csv", "spec/fixtures/multi-item.csv", "spec/fixtures/single-basic.csv", "spec/fixtures/single-foreign.csv", "spec/paperless_to_xero", "spec/paperless_to_xero/converter_spec.rb", "spec/paperless_to_xero/invoice_item_spec.rb", "spec/paperless_to_xero/invoice_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "lib/paperless_to_xero", "lib/paperless_to_xero/converter.rb", "lib/paperless_to_xero/invoice.rb", "lib/paperless_to_xero/invoice_item.rb", "lib/paperless_to_xero/version.rb", "lib/paperless_to_xero.rb"]
  s.homepage = %q{http://reprocessed.org/}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{paperless_to_xero}
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{Convert Paperless CSV exports to Xero invoice import CSV}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
