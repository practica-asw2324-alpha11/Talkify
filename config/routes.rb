Rails.application.routes.draw do



  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    sessions: 'users/sessions'
  }

  resources :magazines do
    member do
      post 'subscribe'
      delete 'unsubscribe'
    end
  end

  resources :posts do


    put 'upvote', on: :member
    put 'downvote', on: :member
    post 'boost', on: :member

    member do
      get 'sort_comments', to: "comments#sort"
      get 'sort_posts', to: "posts#sort"

    end
    resources :comments do
      put 'upvote', on: :member
      put 'downvote', on: :member
      get 'edit', on: :member

    end
    collection do
    get 'new_link'
    get 'new_thread'
    get 'sort'
    get 'search', to: 'posts#search'

    end
  end

  root 'posts#index'

  devise_scope :user do
    get 'users/sign_in', to: 'users/sessions#new', as: :new_user_session
    post 'users/sign_in', to: 'users/sessions#create', as: :user_session
    get 'users/sign_out', to: 'users/sessions#destroy', as: :destroy_user_session
    get 'users/:id', to: 'users/users#show', as: :user
    get 'users/:id/edit', to: 'users/users#edit', as: :edit_user
    patch '/users/:id', to: 'users/users#update'

  end

  # Añadir la ruta para el perfil del user
  #get 'profile', to: 'users/users#show', as: 'profile'
  post 'posts/:id/', to: 'posts#destroy'
  post 'posts/:id/upvote', to: 'posts#upvote'

end
