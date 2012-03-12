require 'active_record'
require_relative 'user'
require_relative 'appli'

config_file = File.join(File.dirname(__FILE__),"Dbconf","database.yml")

#puts YAML.load(File.open(config_file)).inspect

base_directory = File.dirname(__FILE__)
configuration = YAML.load(File.open(config_file))["database"]
configuration["database"] = File.join(base_directory,configuration["database"])

ActiveRecord::Base.establish_connection(configuration)
