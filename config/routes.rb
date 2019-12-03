Rails.application.routes.draw do
  get 'proxy/get_resource'
  get 'proxy/resend_params'
  #get 'proxy', to: 'proxy'
  resources :registers
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
