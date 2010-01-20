require 'test_helper'
require 'active_record'

require File.dirname(__FILE__) + '/../init'

$stdout = StringIO.new

ActiveRecord::Base.establish_connection(:adapter  => "sqlite3",
                                        :database => ":memory:")

def setup_db
  ActiveRecord::Base.logger
  ActiveRecord::Schema.define(:version => 1) do
    create_table :symkey_test_records do |t|
      t.column :id, :integer
      t.column :encrypted_field, :string
    end
    create_table :pubkey_test_records do |t|
      t.column :id, :integer
      t.column :encrypted_field, :string
    end
  end
end
 
def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

setup_db
class SymkeyTestRecord < ActiveRecord::Base
  acts_as_encrypted_with_gpgme :fields => {
    :encrypted_field => {}
  }
end

class PubkeyTestRecord < ActiveRecord::Base
  acts_as_encrypted_with_gpgme :fields => {
    :encrypted_field => {
      :recipients => ["AC5C76C1"], :key => "AC5C76C1"
    }
  }
end
teardown_db

class ActsAsEncryptedWithGpgmeTest < ActiveSupport::TestCase
  def setup
    setup_db
    ENV.delete('GPG_AGENT_INFO')
    homedir = File.dirname(__FILE__) + '/gpgme'
    GPGME::set_engine_info(GPGME::PROTOCOL_OpenPGP, nil, homedir)
    ActsAsEncryptedWithGpgme.set_passphrase('SymkeyTestRecord#encrypted_field',
                                            'test')
    ActsAsEncryptedWithGpgme.set_passphrase('AC5C76C1',
                                            'test')
  end

  def teardown
    teardown_db
  end

  test "symkey encryption" do
    r = SymkeyTestRecord.create(:encrypted_field => "aaa")
    r = SymkeyTestRecord.find(r.id)
    assert_equal(r.encrypted_field, "aaa")
  end

  test "pubkey encryption" do
    r = PubkeyTestRecord.create(:encrypted_field => "aaa")
    r = PubkeyTestRecord.find(r.id)
    assert_equal(r.encrypted_field, "aaa")
  end
end
