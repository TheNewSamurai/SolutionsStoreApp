require 'rho/rhocontroller'
require 'helpers/browser_helper'

class ClientController < Rho::RhoController
  include BrowserHelper

  # GET /Client
  def index
    @clients = Client.find(:all)
    render :back => '/app'
  end

  # GET /Client/{1}
  def show
    @client = Client.find(@params['id'])
    if @client
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Client/new
  def new
    @client = Client.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Client/{1}/edit
  def edit
    @client = Client.find(@params['id'])
    if @client
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Client/create
  def create
    @client = Client.create(@params['client'])
    redirect :action => :index
  end

  # POST /Client/{1}/update
  def update
    @client = Client.find(@params['id'])
    @client.update_attributes(@params['client']) if @client
    redirect :action => :index
  end

  # POST /Client/{1}/delete
  def delete
    @client = Client.find(@params['id'])
    @client.destroy if @client
    redirect :action => :index  
  end
  
  #def preload_map
  #  options = { :engine => 'OSM',
  #           :map_type => 'roadmap',
  #           :top_latitude => 60.1,
  #           :left_longitude => 30.0,
  #           :bottom_latitude => 59.7,
  #           :right_longitude => 30.6,
  #           :min_zoom => 9,
  #           :max_zoom => 11
  #         }
  #  total_tiles_for_preload_count = MapView.preload_map_tiles(options, url_for(:action => :preload_callback))    
  #  redirect :action => :index
  #end
  
  def preload_callback
    puts '@@@@@@@@@      Preload Callback       STATUS['+@params['status']+']   PROGRESS['+@params['progress']+']'
  end
  
  #Setting up the map for GeoLocation
  def location
    map_params = {
      :provider => 'OSM', 
      :settings => {:map_type => "roadmap", :region => [39.956596,-75.160904, 0.2, 0.2],
                    :zoom_enabled => true, :scroll_enabled => true, :shows_user_location => false}, 
      :annotations => [{:latitude => '39.956596', :longitude => '-75.160904', :title => "PRELOAD MARKER"}]
    }
    MapView.create map_params
  end
  
  def show_location
    if !GeoLocation.known_position?
      GeoLocation.set_notification( url_for(:action => :geo_callback), "")
      redirect url_for(:action => :wait)
    else
      render
    end
  end
  
  def geo_callback
    if @params['known_postion'].to_i != 0 && @params['status'] == 'ok'
      WebView.navigate url_for(:action => :show_location)
    end
    if @params['available'].to_i == 0 || @params['status'] == 'ok'
      WebView.navigate url_for(:action => :show_location_error)
    end
  end
  
end
