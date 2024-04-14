Rails.application.routes.draw do
  devise_for :admins, controllers: {
    omniauth_callbacks: 'admins/omniauth_callbacks',
    sessions: 'admins/sessions'
  }

  resources :posts
  resources :tweets do
    put 'like', on: :member
  end

  root 'posts#index'

  devise_scope :admin do
    get 'admins/sign_in', to: 'admins/sessions#new', as: :new_admin_session
    get 'admins/sign_out', to: 'admins/sessions#destroy', as: :destroy_admin_session
  end

  # Añadir la ruta para el perfil del admin
  get 'profile', to: 'admins/admins#show', as: 'profile'
end
