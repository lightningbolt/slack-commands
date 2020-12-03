CmSlackCommands::Application.routes.draw do
  match 'dogeify', to: 'dogeify#index', via: [:get, :post]
  match 'dogeify_slack', to: 'dogeify#slack', via: [:get, :post]
  match 'partyparrot', to: 'partyparrot#index', via: [:get, :post]
  match 'trash_talk', to: 'trash_talk#index', via: [:get, :post]
end
