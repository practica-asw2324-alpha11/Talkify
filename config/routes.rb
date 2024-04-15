Rails.application.routes.draw do
  resources :posts do

      post 'upvote', on: :member
      post 'downvote', on: :member

    member do
      get 'sort_comments', to: "comments#sort"
      get 'sort_posts', to: "posts#sort"

    end
    resources :comments do
      post 'upvote', on: :member
      post 'downvote', on: :member
      get 'edit', on: :member
    end
    collection do
    get 'new_link'
    get 'new_thread'
    get 'sort'
    get 'search', to: 'posts#search'

    end
  end

  resources :user

  root 'posts#index'


end

