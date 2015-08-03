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
      payload = auth_payload(type, username, password)
      post('/auth', payload)
      parse_response(@response)
    end

    def auth_step(type, access_token, mfa)
      payload = mfa_payload(type, access_token, mfa)
      post('/auth/step', payload)
      parse_response(@response)
    end

    def get_request(resource, access_token)
      raise ArgumentError, 'resource must be passed as string' unless resource.is_a?(String)

      payload = get_request_payload(access_token)
      post('/' + resource + '/get', payload)
      parse_response(@response)
    end
    
    def upgrade_to(resource, access_token, options = nil)
      raise ArgumentError, 'resource must be passed as string' unless resource.is_a?(String)
      payload = upgrade_to_payload(resource, access_token, options)
      post('/upgrade', payload)
      parse_response(@response)
    end

    def add_account(type,username,password,email)
      payload = auth_payload(type, username, password, email)
      post('/connect', payload)
      return parse_response(@response)
    end

    def get_place(id)
      get('/entity',id)
      return parse_place(@response)
    end

    def get_institutions
      get('/institutions', {})
      return parse_institutions(@response)
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
        @parsed_response[:info] = response["info"]
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
        @parsed_response[:message] = response["message"]
        @parsed_response[:error_code] = response["code"]
        @parsed_response[:resolve] = response["resolve"]
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

    def parse_institutions(response)
      return JSON.parse(response)
    end

    private

    def common_payload(type)
      {
        :client_id => self.instance_variable_get(:'@customer_id'),
        :secret => self.instance_variable_get(:'@secret'),
        :type => type,
      }
    end

    def get_request_payload(access_token)
      {
        :client_id => self.instance_variable_get(:'@customer_id'),
        :secret => self.instance_variable_get(:'@secret'),
        :access_token => access_token,
      }
    end

    def auth_payload(type, username, password, email = nil)
      payload = common_payload(type)
      payload[:credentials] = { :username => username, :password => password }

      if email
        payload[:email] = email
      end

      payload
    end
    
    def upgrade_to_payload(resource, access_token, options = nil)
      payload = {
        :client_id => self.instance_variable_get(:'@customer_id'),
        :secret => self.instance_variable_get(:'@secret'),
        :access_token => access_token,
        :upgrade_to => resource,
      }
      payload.merge!(:options => options) if options
      payload
    end

    def mfa_payload(type, access_token, mfa)
      payload = common_payload(type)
      payload[:access_token] = access_token
      payload[:mfa] = mfa

      payload
    end

    def post(path, payload)
      url = base_url + path
      @response = RestClient.post(url, payload)
      return @response
    end

    def get(path, params_hash)
      url = base_url + path
      @response = RestClient.get(url, :params => params_hash)
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

    def exchange(public_token)
      payload = exchange_payload(public_token)
      post('/exchange_token', payload)
      parse_response(@response)
    end

    def exchange_payload(token)
      {
          :client_id => self.instance_variable_get(:'@customer_id'),
          :secret => self.instance_variable_get(:'@secret'),
          :public_token => token
      }
    end

  end
end
