GPGME::check_version("1.1.5")
GPGME::engine_check_version(GPGME::PROTOCOL_OpenPGP)

homedir = File.dirname(__FILE__) + '/../gpgme'
config.mkdir unless File.exist? homedir
GPGME::set_engine_info(GPGME::PROTOCOL_OpenPGP, nil, homedir)

# ENV.delete('GPG_AGENT_INFO')    # disable gpg-agent
# $stderr.write("Passphrase for \"Post#body\": ")
# $stderr.flush
# begin
#   system('stty -echo')
#   ActsAsEncryptedWithGpgme.set_passphrase('Post#body', gets)
# ensure
#   system('stty echo')
# end
# $stderr.puts
