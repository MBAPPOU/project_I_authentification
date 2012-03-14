class Appli < ActiveRecord::Base
   validates :name, :uniqueness => true
   validates :name, :presence => true
   validates :secret, :presence => true
   
   has_many :authentifications
   has_many :users, :through => :authentifications
end
