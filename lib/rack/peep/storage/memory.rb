module Rack
  class Peep
    module Storage; end
  end
end

class Rack::Peep::Storage::Memory
  def initialize(options = {})
    @page_size = options[:page_size] || 10
    @interactions = []
  end

  def add(interaction)
    keep = [@page_size - 1, @interactions.length].min
    @interactions = @interactions[-keep, keep] + [ interaction ]
    nil
  end

  def fetch(start_id=nil)
    {
      entries: @interactions.reverse,
      next_id: nil,
    }
  end
end
