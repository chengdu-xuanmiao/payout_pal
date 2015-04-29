module PayoutPal
  Error = Class.new(StandardError)
  BadRequest = Class.new(Error)
  NotFound = Class.new(Error)
end