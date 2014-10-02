module Plaid
  class Call

    BASE_URL = 'https://tartan.plaid.com/'
    PRODUCTION_BASE_URL = 'https://api.plaid.com/'

    # This initializes our instance variables, and sets up a new Customer class.
    def initialize
      Plaid::Configure::KEYS.each do |key|
        instance_variable_set(:"@#{key}", Plaid.instance_variable_get(:"@#{key}"))
      end
    end

    def auth(type, username, password)
      post('/auth', type, username, password)
      parse_response(@response)
    end

    def add_account(type,username,password,email)
      post('/connect',type,username,password,email)
      return parse_response(@response)
    end

    def get_place(id)
      get('/entity',id)
      return parse_place(@response)
    end
    protected

    def parse_response(response)
      case response.code
      when 200
        @parsed_response = Hash.new
        @parsed_response[:code] = response.code
        response = JSON.parse(response)
        @parsed_response[:access_token] = response["access_token"]
        @parsed_response[:accounts] = response["accounts"]
        @parsed_response[:transactions] = response["transactions"]
        return @parsed_response
      when 201
        @parsed_response = Hash.new
        @parsed_response[:code] = response.code
        response = JSON.parse(response)
        @parsed_response = Hash.new
        @parsed_response[:type] = response["type"]
        @parsed_response[:access_token] = response["access_token"]
        @parsed_response[:mfa_info] = response["mfa"] || response["mfa_info"]
        return @parsed_response
      else
        @parsed_response = Hash.new
        @parsed_response[:code] = response.code
        @parsed_response[:message] = response
        return @parsed_response
      end
    end

    def parse_place(response)
      @parsed_response = Hash.new
      @parsed_response[:code] = response.code
      response = JSON.parse(response)["entity"]
      @parsed_response[:category] = response["category"]
      @parsed_response[:name] = response["name"]
      @parsed_response[:id] = response["_id"]
      @parsed_response[:phone] = response["meta"]["contact"]["telephone"]
      @parsed_response[:location] = response["meta"]["location"]
      return @parsed_response
    end

    private

    def post(path,type,username,password,email = nil)
      url = base_url + path
      payload = {
          :client_id => self.instance_variable_get(:'@customer_id'),
          :secret => self.instance_variable_get(:'@secret'),
          :type => type,
          :credentials => { :username => username, :password => password }
      }

      if email
        payload[:email] = email
      end

      @response = RestClient.post url, payload
      return @response
    end

    def get(path,id)
      url = base_url + path
      @response = RestClient.get(url,:params => {:entity_id => id})
      return @response
    end

    def base_url
      return @base_url if @base_url

      if self.instance_variable_get(:'@production')
        @base_url = PRODUCTION_BASE_URL
      else
        @base_url = BASE_URL
      end

      @base_url
    end

  end
end
