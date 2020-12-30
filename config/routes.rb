Rails.application.routes.draw do
  resources :repositories do
    get "export", on: :collection
  end
  get "/", to: redirect("/repositories")
end
