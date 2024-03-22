Rails.application.routes.draw do
  resources :posts
  resources :tweets do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

    put 'like', on: :member
  end

  root 'posts#index'


end

