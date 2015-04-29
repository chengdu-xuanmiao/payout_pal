module PayoutPal
  module Stubs
    def load!
      @stubs ||= {}

      dir = File.join(File.dirname(File.expand_path(__FILE__)), "json")
      glob_path = File.join(dir, "/*.json")

      Dir.glob(glob_path) do |filename|
        stub_name = File.basename(filename, ".json")
        @stubs[stub_name] = IO.read(filename)
      end
    end

    def [](stub)
      @stubs[stub].dup
    end

    def inspect
      @stubs.inspect
    end

    extend self
  end
end
