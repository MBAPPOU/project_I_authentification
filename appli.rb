class Appli < ActiveRecord::Base
   validates :name, :uniqueness => true
end
