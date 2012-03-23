class Authentification < ActiveRecord::Base
   #validates :user, :presence => true
   #validates :application, :presence => true
   belongs_to :users
   belongs_to :applis
end
