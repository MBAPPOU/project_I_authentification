class User < ActiveRecord::Base
   validates :login, :uniqueness => true
end
