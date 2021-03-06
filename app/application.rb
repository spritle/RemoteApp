require 'rho/rhoapplication'
require "validatable"   
require "json"

# Class that was created by Rhodes.
class AppApplication < Rho::RhoApplication
    
  # Method that sets up the application.
  def initialize
    # Tab items are loaded left->right, @tabs[0] is leftmost tab in the tab-bar
    # Super must be called *after* settings @tabs!
    @tabs = nil

    #To remove default toolbar uncomment next line:
    @@toolbar = nil
    super
    @default_menu = {
      "Controls" => "/app/Controls", 
      "Commands" => "/app/Commands",
      "Scan Barcode" => "app/BarcodeScan",
      :separator => nil,
      "Settings" => "app/XbmcConfig",
      "Close" => :close
    }

    # Uncomment to set sync notification callback to /app/Settings/sync_notify.
    # SyncEngine::set_objectnotify_url("/app/Settings/sync_notify")
    # SyncEngine.set_notification(-1, "/app/Settings/sync_notify", '')
     
  end

end
