require 'pathname'
require 'fileutils'

@source_base = Pathname.new(__FILE__).dirname
@destination_base = @source_base + '../../..'

def install(path)
  relpath = path.relative_path_from(@source_base)
  destination = @destination_base + relpath
  if destination.exist?
    $stderr.puts("skipping #{relpath}")
  else
    $stderr.puts("installing #{relpath}")
    FileUtils.install(path.to_s, destination.to_s)
  end
end

install(@source_base + './config/initializers/gpgme.rb')

puts (Pathname.new(__FILE__).dirname + 'README').read
