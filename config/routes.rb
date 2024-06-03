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
              post :copy_existing
              post :drop
              post :duplicate
            end
          end
        end
      end
    end
  end

  match 'fe/references/done' => "fe/reference_sheets#done", via: [:get, :post]

  # form capture and review
  namespace "fe" do
    resources :reference_sheets
    resources :answer_sheets, except: :new do
      member do
        post :send_reference_invite
        post :submit
      end
      resources  :page, :controller => :answer_pages do
        member do
          post :save_file
          delete :delete_file
        end
      end
    end
  end

  resources :elements, :namespace => "fe"
end
