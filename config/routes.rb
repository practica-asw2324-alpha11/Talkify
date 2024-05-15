Rails.application.routes.draw do

  root 'posts#index'


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

    post 'new_thread', on: :collection

    post 'upvote', on: :member
    post 'downvote', on: :member
    put 'boost', on: :member
    delete 'unboost', on: :member


    member do
      get 'sort_comments', to: "comments#sort"
      get 'sort_posts', to: "posts#sort"

    end
    resources :comments do

      member do
        # put 'upvote', on: :member
        # put 'downvote', on: :member
        post 'upvote'
        delete 'upvote', action: :unvote
        post 'downvote'
        delete 'downvote', action: :unvote

        get 'edit'
      end

    end
    collection do
    get 'new_link'
    get 'new_thread'
    get 'sort'
    get 'search', to: 'posts#search'

    end
  end


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
  post 'posts', to: 'posts#create'
  delete 'posts/:id/', to: 'posts#destroy'
  put 'posts/:id', to: 'posts#update'
  get 'posts/:id', to: 'posts#show'
  post 'posts/:id/upvote', to: 'posts#upvote'
  delete 'posts/:id/upvote', to: 'posts#upvote'
  put 'posts/:id/boost', to:'posts#boost'
  delete 'posts/:id/boost', to:'posts#unboost'
  post 'posts/:id/downvote', to: 'posts#downvote'
  delete 'posts/:id/downvote', to: 'posts#downvote'
  get 'posts/search', to: 'posts#search'


end
