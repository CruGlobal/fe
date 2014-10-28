Rails.application.routes.draw do

  namespace "fe" do
    namespace :admin do
      resources :email_templates
      resources :question_sheets do
        member do
          post :archive
          post :unarchive
          post :duplicate
        end
        resources :pages,                               # pages/
                  :controller => :question_pages do         # question_sheet_pages_path(),
          collection do
            post :reorder
          end
          member do
            get :show_panel
          end
          resources :elements do
            collection do
              post :reorder
            end
            member do
              get :remove_from_grid
              post :use_existing
              post :drop
              post :duplicate
            end
          end
        end
      end
    end
  end

  match 'fe/references/done' => "fe/reference_sheets#done", via: [:get, :post]
  match 'fe/applications/show_default' => 'fe/applications#show_default', :as => 'show_default', via: [:get, :post]
  match 'fe/payment_pages/staff_search' => 'fe/payment_pages#staff_search', :as => :payment_page_staff_search, via: [:get, :post]

  # form capture and review
  namespace "fe" do
    resources :reference_sheets
    resources :answer_sheets do
      member do
        post :send_reference_invite
        post :submit
      end
      resources  :page, :controller => :answer_pages do
        member do
          post :save_file
        end
      end
    end
    resources :applications do
      member do
        get :no_ref
        get :no_conf
        get :collated_refs
        get :done
      end

      resources :references do
        member do
          get :print
          post :submit
          post :send_invite
        end
      end

      # custom pages (singular resources)
      resource :reference_page

      resources :payments do
        member do
          get :approve
        end
        collection do
          post :staff_search
        end
      end

      resource :submit_page do
        member do
          post :submit
        end
      end
    end
  end

  resources :elements, :namespace => "fe"
end
