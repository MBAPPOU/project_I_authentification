class Authentification < ActiveRecord::Base
   validates :user, :presence => true
   validates :application, :presence => true
   
   belongs_to :applis
   belongs_to :users
end
