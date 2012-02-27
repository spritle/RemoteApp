require 'rho/rhocontroller'
require 'helpers/application_helper'
require 'helpers/browser_helper'
require 'helpers/method_helper'
require 'helpers/tv_show_helper'
require 'helpers/error_helper'
require 'helpers/download_helper'

class TvshowController < Rho::RhoController
  include ApplicationHelper
  include BrowserHelper
  include MethodHelper
  include TvShowHelper
  include ErrorHelper
  include DownloadHelper

  @@conditions = {}
  @@order = {:title => :sorttitle, :year => :year, :rating => :rating}
  @@active_order = :sorttitle
  @@order_dir = 'ASC'
  @@watch_list = false 

  # GET /Tvshow
  def index
    render
  end

  # GET /Tvshow/{1}
  def show
    @tvshow = Tvshow.find(@params['id'])
    if @tvshow
      redirect :controller => :Tvseason, :query => {:tvshowid => @tvshow.xlib_id}
    else
      redirect :action => :index
    end
  end
  
  def info
    @tvshow = find_tvshow(@params['tvshowid'])
    render
  end
  
  def get_tv_shows
    WebView.execute_js("showLoading('Loading TV Shows');")
    @tvshows = filter_tvshows_xbmc(@@conditions, @@active_order, @@order_dir)
    unless @tvshows.blank?
      ensure_sorted(@tvshows)
      WebView.execute_js("updateTVList(#{JSON.generate(@tvshows)});")
    end
    send_command {load_tv_shows(url_for :action => :tv_shows_callback)}
  end
  
  def tv_shows_callback
    if @params['status'] == 'ok'
      if sync_tv_shows(@params['body'].with_indifferent_access[:result][:tvshows])
        @tvshows = filter_tvshows_xbmc(@@conditions, @@active_order, @@order_dir)
        unless @tvshows.blank?
          ensure_sorted(@tvshows)
          WebView.execute_js("updateTVList(#{JSON.generate(@tvshows)});")
        end
      end
    else
      error_handle(@params)
      WebView.execute_js("hideLoading();")
      WebView.execute_js("showToastError('#{XbmcConnect.error[:msg]}');")
    end
  end
  
  def get_tv_thumb
    found_tvshow = find_tvshow(@params['tvshowid'])
    unless found_tvshow.blank? 
      unless found_tvshow.l_thumb.blank?
        WebView.execute_js("addTVThumb(#{found_tvshow.xlib_id},\'#{found_tvshow.l_thumb}\');")
      else
        download_tvthumb(found_tvshow)
      end
    end
  end
  
  def thumb_callback
    if @params['status'] == 'ok'
      found_tvshow = find_tvshow(@params['tvshowid'])
      unless found_tvshow.blank?
        unless @params['file'].blank?
          found_tvshow.l_thumb = @params['file']
          found_tvshow.save      
          WebView.execute_js("addTVThumb(#{found_tvshow.xlib_id},\'#{found_tvshow.l_thumb}\');")
        end
      end
    else
      error_handle(@params)
      #WebView.execute_js("showToastError('#{XbmcConnect.error[:msg]}');")
    end
  end

  def get_watch_list_bool
    @@watch_list
  end
  
  def get_order_dir
    @@order_dir
  end

  def get_order
    @@order
  end

  def get_active_order
    @@active_order
  end
  
  def tvsort
    if !@params['watch_later'].blank?
      @@watch_list = @params['watch_later']
      if @@watch_list == "true"
        @@conditions = {:watch_later => @@watch_list}
      else 
        @@conditions = {}
      end
    elsif !@params['order_dir'].blank?
      @@order_dir = "#{@params['order_dir']}"
    elsif !@params['order'].blank?
      wanted = @params['order']
      @@order.each do | key, value |
        if wanted == key.to_s
          @@active_order = value 
        end
      end
    end
  end 

  # Ensure that the list has been sorted properly.
  # This is used because Rhom only seems to sort by the first 
  # number. Therefore, iterate over the list to make sure it has
  # been sorted. This works for both ASC and DESC lists.
  def ensure_sorted(tvshows)
    if @@active_order == @@order[:rating]
      tvshows.sort_by! {|tvshow| tvshow.rating.to_f}
      if @@order_dir == 'DESC'
        tvshows.reverse!
      end
    end
  end

end
