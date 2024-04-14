Rails.application.routes.draw do
  resources :posts do
    member do
      get 'sort_comments', to: "comments#sort"
    end
    resources :comments do 
      post 'upvote', on: :member
      post 'downvote', on: :member
      get 'edit', on: :member
    end
  end

  resources :user

  root 'posts#index'

  get '/magazines', to: 'magazines#index'


end

