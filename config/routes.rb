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
    collection do
    get 'new_link'
    get 'new_thread'
    end
  end

  resources :user

  root 'posts#index'


end

