# Copyright (c) 2009 Daiki Ueno, released under the MIT license

module ActsAsEncryptedWithGpgme
  def self.included(base)       # :nodoc:
    base.extend(ClassMethods)
  end

  @@passphrase_callbacks = Hash.new

  # Associate <i>key</i> and <i>passphrase</i>.
  # The passphrase set by this function will be passed to gpg when needed.
  def self.set_passphrase(key, passphrase)
    @@passphrase_callbacks[key] = PassphraseCallback.new(passphrase)
  end

  def self.get_passphrase_callback(key) # :nodoc:
    @@passphrase_callbacks[key].method(:call)
  end

  class PassphraseCallback      # :nodoc:
    def initialize(passphrase)
      @passphrase = passphrase
    end

    def call(*args)
      fd = args.last
      io = IO.for_fd(fd, 'w')
      io.puts(@passphrase)
      io.flush
    end
  end

  module ClassMethods
    DefaultOptions = {
      :armor => true,
      :always_trust => true
    }

    # Declare a class to have encrypted fields.
    #
    # <i>options</i> is a hash whose keys are:
    #
    # - <tt>:fields</tt> Fields to be encrypted.  The value of this
    #   option will be an array or a hash.  With the latter form, you
    #   can specify options for encryption (and decryption) for each
    #   field.
    # - <tt>:default_options</tt> Default options for encryption (and
    #   decryption).
    def acts_as_encrypted_with_gpgme(options = Hash.new)
      encrypted_fields = Hash.new
      write_inheritable_attribute :encrypted_fields, encrypted_fields
      class_inheritable_hash :encrypted_fields
      include ActsAsEncryptedWithGpgme::InstanceMethods

      fields = options[:fields]
      case fields
      when Array
        fields.each do |field|
          encrypted_fields[field] = Hash.new
        end
      when Hash
        encrypted_fields.update(fields)
      else
        raise ArgumentError, "fields must be an array or a hash"
      end

      default_options = options[:default_options] || Hash.new
      encrypted_fields.each do |field, field_options|
        DefaultOptions.merge(default_options).each do |key, val|
          field_options[key] = val unless field_options.has_key? key
        end
        recipients = field_options[:recipients]
        unless recipients
          unless field_options.has_key? :key
            field_options[:key] = "#{self}##{field.to_s}"
          end
        end
        encrypted_fields[field] = field_options
      end

      before_save :encrypt
      after_find :decrypt
    end
  end

  module InstanceMethods
    def encrypt                 # :nodoc:
      encrypted_fields.each do |field, field_options|
        next unless self[field] && changed.include?(field.to_s)
        self[field] = GPGME::encrypt(field_options[:recipients],
                                     self[field],
                                     encrypt_options_for_field(field))
      end
    end

    def decrypt                 # :nodoc:
      encrypted_fields.each do |field, field_options|
        next unless self[field]
        next if field_options[:recipients] && !field_options[:key]
        self[field] = GPGME::decrypt(self[field],
                                     decrypt_options_for_field(field))
      end
    end

    def after_find              # :nodoc:
    end

    private
    def encrypt_options_for_field(field)
      options = Hash.new
      field_options = encrypted_fields[field]
      if field_options[:recipients]
        if field_options.has_key? :always_trust
          options[:always_trust] = field_options[:always_trust]
        end
      else
        passphrase_callback =
          ActsAsEncryptedWithGpgme.get_passphrase_callback(field_options[:key])
        if passphrase_callback
          options[:passphrase_callback] = passphrase_callback
        end
      end
      if field_options.has_key? :armor
        options[:armor] = field_options[:armor]
      end
      options
    end

    def decrypt_options_for_field(field)
      options = Hash.new
      field_options = encrypted_fields[field]
      passphrase_callback =
        ActsAsEncryptedWithGpgme.get_passphrase_callback(field_options[:key])
      if passphrase_callback
        options[:passphrase_callback] = passphrase_callback
      end
      options
    end
  end
end
