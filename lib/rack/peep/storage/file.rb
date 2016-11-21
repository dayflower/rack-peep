require "json"
require "tmpdir"

module Rack
  class Peep
    module Storage; end
  end
end

class Rack::Peep::Storage::File
  def initialize(options = {})
    @page_size = options[:page_size] || 10
    @filename  = options[:filename] || File.join(Dir.tmpdir, 'rackpeep.dat')
  end

  def add(interaction)
    File.open(@filename, File::RDWR | File::CREAT) { |f|
      f.flock(File::LOCK_EX)
      interactions = f.readlines.map { |line| JSON.parse(line, symbolize_names: true) }

      keep = [@page_size - 1, interactions.length].min
      interactions = interactions[-keep, keep] + [ interaction ]

      f.rewind
      f.puts interactions.map { |act| JSON.generate(act) }.join("\n")
      f.flush
      f.truncate(f.pos)
    }
    nil
  end

  def fetch(start_id=nil)
    begin
      interactions = File.open(@filename, File::RDONLY) { |f|
        f.flock(File::LOCK_SH)
        f.readlines.map { |line| JSON.parse(line, symbolize_names: true) }
      }
    rescue Errno::ENOENT
      interactions = []
    end

    {
      entries: interactions.reverse,
      next_id: nil,
    }
  end
end
