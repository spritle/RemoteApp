require 'rho/rhocontroller'
require 'helpers/application_helper'
require 'helpers/browser_helper'
require 'helpers/controls_helper'
require 'helpers/xbmc_config_helper'
require 'helpers/xbmc/xbmc_connect'
require 'helpers/error_helper'
require 'helpers/telnet_test'

class ControlsController < Rho::RhoController
  include ApplicationHelper
  include BrowserHelper
  include Controls
  include XbmcConfigHelper
  include ErrorHelper
  include TelTest
  
  def index
    @@test = "First time"
    XbmcConfigHelper.current_config
    XbmcConnect.load_api
    render
  end
  
  def update_screen
    render :action => :index
  end
  
  def show_error
    render :action => :error
  end
  
  def get_text
    @@test
  end

  def cancel_control
    Rho::AsyncHttp.cancel
    @@test = 'Request was cancelled.'
    render :action => :index
  end
  
  # Handles the callback from sending a command. Will show error message if something
  # has gone wrong. Handles what to do with results depending on the Params of the
  # response. 
  def control_callback 
    if @params['status'] != 'ok'
      ErrorHelper.error_handle(@params)
    else
      puts "Body of message:\n#{@params['body']}"
      if @params['method'] == "load_api"
        XbmcConnect.load_version(@params)
      end  
      if @params['method'] == 'play_pause'
        res = @params['body'].with_indifferent_access[:result]
        paused = false
        if XbmcConnect.version == Api::V2::VERSION
          paused = true if res[:paused]
        elsif (XbmcConnect.version == Api::V4::VERSION) || XbmcConnect.version == 3
          paused = true if res[:speed] == 0
        end
        if paused
          @@test = "Paused"
        else
          @@test = 'Playing'
        end
      elsif @params['method'] == 'stop'
        if @params['body'].with_indifferent_access[:result] == "OK"
          @@test = "Stopped"
        else
          @@test = '???'
        end
      end
      render_transition :action => :index
    end
  end
    
  def pause_play
    control_player {play_pause_player}
  end
  
  def stop
    control_player {stop_player}
  end
  
  def rewind
    control_player {rewind_player}
  end
  
  def fast_forward
    control_player {fast_forward_player}
  end
  
  def big_skip_forward
    control_player {big_skip_forward_player}
  end
  
  def sm_skip_forward
    control_player {sm_skip_forward_player}
  end
  
  def big_skip_back
    control_player {big_skip_back_player}
  end
  
  def sm_skip_back
    control_player {sm_skip_back_player}
  end
  
  def skip_next
    control_player {skip_next_player}
  end
  
  def skip_prev
    control_player {skip_prev_player}
  end
  
  def telnet_test
    teltest
  end
  
end