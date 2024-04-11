Rails.application.routes.draw do
  resources :posts do
    resources :comments do 
      post 'upvote', on: :member
      post 'downvote', on: :member
      get 'edit', on: :member
    end
  end

  resources :user

  root 'posts#index'


end

