module Plaid
  module Configure
    attr_writer :customer_id, :secret, :production

    KEYS = [:customer_id, :secret, :production]

    def config
      yield self
      self
    end

  end
end
