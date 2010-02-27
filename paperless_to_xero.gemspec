# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{paperless_to_xero}
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Patterson"]
  s.date = %q{2010-02-27}
  s.default_executable = %q{paperless_to_xero}
  s.description = %q{= Paperless-to-Xero

A simple translator which takes a CSV file from Mariner's Paperless receipt/document management software and makes a Xero accounts payable invoice CSV, for import into Xero.

Formatting in Paperless is very important, so you probably want to wait until I've written the docs}
  s.email = %q{matt@reprocessed.org}
  s.executables = ["paperless_to_xero"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "MIT-LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "bin/paperless_to_xero",
     "lib/paperless_to_xero.rb",
     "lib/paperless_to_xero/converter.rb",
     "lib/paperless_to_xero/decimal_helpers.rb",
     "lib/paperless_to_xero/errors.rb",
     "lib/paperless_to_xero/invoice.rb",
     "lib/paperless_to_xero/invoice_item.rb",
     "lib/paperless_to_xero/version.rb",
     "paperless_to_xero.gemspec",
     "spec/fixtures/dodgy-header.csv",
     "spec/fixtures/end_to_end-input.csv",
     "spec/fixtures/end_to_end-output.csv",
     "spec/fixtures/multi-ex-vat.csv",
     "spec/fixtures/multi-foreign.csv",
     "spec/fixtures/multi-item-mixed_vat_and_exempt.csv",
     "spec/fixtures/multi-item.csv",
     "spec/fixtures/single-1000.csv",
     "spec/fixtures/single-basic.csv",
     "spec/fixtures/single-dkk.csv",
     "spec/fixtures/single-foreign.csv",
     "spec/fixtures/single-no-vat.csv",
     "spec/fixtures/single-vat-2008-11-30.csv",
     "spec/fixtures/single-vat-2008-12-01.csv",
     "spec/fixtures/single-vat-2009-12-31.csv",
     "spec/fixtures/single-vat-2009.csv",
     "spec/fixtures/single-vat-2010-01-01.csv",
     "spec/fixtures/single-vat-pre-2008-12.csv",
     "spec/fixtures/single-zero_rated.csv",
     "spec/paperless_to_xero/converter_spec.rb",
     "spec/paperless_to_xero/errors_spec.rb",
     "spec/paperless_to_xero/invoice_item_spec.rb",
     "spec/paperless_to_xero/invoice_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/fidothe/paperless_to_xero/}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{paperless_to_xero}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Convert Paperless CSV exports to Xero invoice import CSV}
  s.test_files = [
    "spec/paperless_to_xero/converter_spec.rb",
     "spec/paperless_to_xero/errors_spec.rb",
     "spec/paperless_to_xero/invoice_item_spec.rb",
     "spec/paperless_to_xero/invoice_spec.rb",
     "spec/spec_helper.rb"
  ]

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

