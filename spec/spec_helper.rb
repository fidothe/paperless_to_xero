require 'rubygems'
require 'mocha'
$:.push(File.expand_path(File.dirname(__FILE__) + '/../lib'))
Spec::Runner.configure do |config|
  config.mock_with :mocha
end

require 'paperless_to_xero'

class Class
  def publicize_methods
    saved_private_instance_methods = self.private_instance_methods
    saved_protected_instance_methods = self.protected_instance_methods
    self.class_eval do
      public *saved_private_instance_methods
      public *saved_protected_instance_methods
    end
    
    yield
    
    self.class_eval do
      private *saved_private_instance_methods
      protected *saved_protected_instance_methods
    end
  end
end
