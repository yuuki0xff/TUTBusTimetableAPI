Rails.application.routes.draw do
  # API
  namespace :api do
    namespace :v1 do
      resources :timetables, only: [:index]
      resources :places, only: [:index]

      get '/places/available', to: 'places#available'
      get '/timetables/internal', to: 'timetables#internal'

    end
  end

  root 'static_pages#index'
  get 'api/v1/document', to: 'static_pages#document'
  resources :register, only: [:index, :new, :create]
end
