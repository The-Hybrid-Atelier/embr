Rails.application.routes.draw do
  namespace :ebroidery do 
    get "keys"
    get 'tool', :as => "tool"
    get "gallery", :as => "gallery"
  end

  root 'ebroidery#gallery'
end
