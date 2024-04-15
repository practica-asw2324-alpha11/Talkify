Rails.application.routes.draw do
  devise_for :admins, controllers: {
    omniauth_callbacks: 'admins/omniauth_callbacks',
    sessions: 'admins/sessions'
  }


  resources :tweets do
    put 'like', on: :member
  end

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

  root 'posts#index'

  devise_scope :admin do
    get 'admins/sign_in', to: 'admins/sessions#new', as: :new_admin_session
    post 'admins/sign_in', to: 'admins/sessions#create', as: :admin_session
    get 'admins/sign_out', to: 'admins/sessions#destroy', as: :destroy_admin_session
    get 'admins/:id', to: 'admins/admins#show', as: :admin
  end

  # Añadir la ruta para el perfil del admin
  get 'profile', to: 'admins/admins#show', as: 'profile'
end
