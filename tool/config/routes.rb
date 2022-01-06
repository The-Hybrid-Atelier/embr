Rails.application.routes.draw do
  get 'tool' =>"ebroidery#tool", :as => "tool"
  get "gallery" => "ebroidery#gallery", :as => "gallery"

  namespace :heater do
  	get "tool"
  	get "keys"
  end

  namespace :ebroidery do 
    get "keys"
    
  end
  get "motion", action: "motion", controller: "application"
  root 'ebroidery#gallery'
end
