Rails.application.routes.draw do
  devise_for :admins, controllers: {
    omniauth_callbacks: 'admins/omniauth_callbacks',
    sessions: 'admins/sessions'
  }

  resources :posts do
    member do
      get 'sort_comments', to: "comments#sort"
    end
    resources :comments do
      member do
        post 'upvote'
        post 'downvote'
      end

      get 'edit', on: :member
      #post 'create_reply', on: :member
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
