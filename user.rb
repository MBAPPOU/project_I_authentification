require 'active_record'
class User < ActiveRecord::Base
   validates :login, :uniqueness => true
end
