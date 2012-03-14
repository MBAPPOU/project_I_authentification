class User < ActiveRecord::Base
   validates :login, :uniqueness => true
   validates :login, :presence => true
   validates :password, :presence => true
   
   has_many :authentifications
   has_many :applis, :through => :authentifications
end
