Rails.application.routes.draw do
   # get 'metareviewgenerator/AutomatedMetareview'
  #match 'metareviewgenerator', to: 'metareviewgenerator#AutomatedMetareview', via: [:get]
  resource :metareviewgenerator do
    post 'create', to:'metareviewgenerator#create'
    post 'get_tone', to:'metareviewgenerator#get_tone'
    post 'get_quantity', to:'metareviewgenerator#get_quantity'
    post 'get_content', to:'metareviewgenerator#get_content'
    post 'get_plagiarism', to:'metareviewgenerator#get_plagiarism'
    post 'get_coverage', to:'metareviewgenerator#get_coverage'
    post 'get_relevance', to:'metareviewgenerator#get_relevance'
  end
=begin working sample
  resources :metareviewgenerator do
    collection do
      post :'/'
    end
  end
=end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
