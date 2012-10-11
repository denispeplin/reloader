require 'reloader/sse'

class BrowserController < ApplicationController
  include ActionController::Live

  def index
    # SSE expects the `text/event-stream` content type
    response.headers['Content-Type'] = 'text/event-stream'

    sse = Reloader::SSE.new(response.stream)

    begin
      directory = File.join(Rails.root, 'app')

      notifier = INotify::Notifier.new

      notifier.watch(directory, :modify, :recursive) do |event|
        sse.write({ :dirs => directory, eventname: event.name }, :event => 'refresh')
      end

      notifier.run
    rescue IOError
      # When the client disconnects, we'll get an IOError on write
    ensure
      sse.close
    end
  end
end
