require 'active_support'
require 'dotenv'

module Gris
  class << self
    def load_environment
      env_file = Gris.env.test? ? '.env.test' : '.env'
      Dotenv.overload env_file
    end

    def env
      @_env ||= ActiveSupport::StringInquirer.new(ENV['RACK_ENV'] || 'development')
    end

    def env=(environment)
      @_env = ActiveSupport::StringInquirer.new(environment)
    end

    def db_connection_details
      YAML.load(ERB.new(File.read('./config/database.yml')).result)[Gris.env]
    end
  end
end
