gem 'ruby-gpgme', '>= 1.0.3'
require 'gpgme'

require 'acts_as_encrypted_with_gpgme'

ActiveRecord::Base.class_eval do
  include ActsAsEncryptedWithGpgme
end
