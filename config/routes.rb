Rails.application.routes.draw do
  resources :posts do
    member do
      get 'sort_comments', to: "comments#sort"
    end
    resources :comments do 
      member do
        post 'upvote'
        post 'downvote'
      end

      # post 'upvote', on: :member
      # post 'downvote', on: :member
      get 'edit', on: :member
      #post 'create_reply', on: :member
    end
  end

  resources :user

  root 'posts#index'


end

