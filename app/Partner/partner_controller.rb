require 'rho/rhocontroller'
require 'helpers/browser_helper'

class PartnerController < Rho::RhoController
  include BrowserHelper

  # GET /Partner
  def index
    @partners = Partner.find(:all)
    render :back => '/app'
  end

  # GET /Partner/{1}
  def show
    @partner = Partner.find(@params['id'])
    if @partner
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Partner/new
  def new
    @partner = Partner.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Partner/{1}/edit
  def edit
    @partner = Partner.find(@params['id'])
    if @partner
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Partner/create
  def create
    @partner = Partner.create(@params['partner'])
    get_geolocation(@partner)
    #redirect :action => :index
  end

  # POST /Partner/{1}/update
  def update
    @partner = Partner.find(@params['id'])
    @partner.update_attributes(@params['partner']) if @partner
    redirect :action => :index
  end

  # POST /Partner/{1}/delete
  def delete
    @partner = Partner.find(@params['id'])
    @partner.destroy if @partner
    redirect :action => :index  
  end
  
  def preload_callback
    puts '@@@@@@@@@      Preload Callback       STATUS['+@params['status']+']   PROGRESS['+@params['progress']+']'
  end
  
  #Setting up the map for GeoLocation
  def partner_location
    @partner = Partner.find(@params['id'])
      
    #Using Open Source Maps (This is used by MapQuest)
    map_params = {
      :provider => 'OSM', 
      :settings => {:map_type => "roadmap", :region => [@partner.lat,@partner.long, 0.2, 0.2],
                    :zoom_enabled => true, :scroll_enabled => true, :shows_user_location => false}, 
      :annotations => [{:latitude => @partner.lat, :longitude => @partner.long, :title => "PRELOAD MARKER"}]
    }
    
    #Using Google Static API maps
    #map_params = {
    #  :provider => 'RhoGoogle', 
    #  :settings => {:map_type => "roadmap", :region => [40.994705,-77.604546, 0.2, 0.2],
    #                :zoom_enabled => true, :scroll_enabled => true, :shows_user_location => true}, 
    #  :annotations => [{:latitude => 40.994705, :longitude => -77.604546, :title => "PRELOAD MARKER"}]
    #}
    MapView.create map_params
    
    render :back => url_for( :action => :index)
  end
  
  def show_location
    #if !GeoLocation.known_position?
    #  GeoLocation.set_notification( url_for(:action => :geo_callback), "")
    #  redirect url_for(:action => :wait)
    #else
    #  render
    #end
    
    puts "ENTER SHOW LOCATION!!!!!!!!!!!!"
    
    if GeoLocation.known_position?
      puts "@@@@@@@@@@@@@@@@@ GPS COORDS @@@@@@@@@@@@@@@@ " + GeoLocation.latitude.to_s + " " + GeoLocation.longitude.to_s
    else
      Alert.show_popup(
          :message => 'Awating GPS Coordinates please wait a minute.',
          :title => 'GPS Coordinates',
          :buttons => ['ok'],
          :callback => url_for(:action => :partner_callback)
      )
    end
    
    map_params = {
      :provider => 'OSM', 
      :settings => {:map_type => "roadmap", :region => [GeoLocation.latitude,GeoLocation.longitude, 0.2, 0.2],
                    :zoom_enabled => true, :scroll_enabled => true, :shows_user_location => true}, 
      :annotations => [{:latitude => GeoLocation.latitude, :longitude => GeoLocation.longitude, :title => "Your Location"}]
    }
    MapView.create map_params
    
    redirect :action => :index
  end
  
  def partner_callback
    WebView.navigate url_for(:action => :index)
  end
  
  def show_location_error
    puts "Can't get GPS Coordinates"
    redirect :action => :index
  end
  
  def geo_callback
    puts "GEO_CALLBACK :: #{@params}"
    if @params['known_position'].to_i != 0 && @params['status'] == 'ok'
      WebView.navigate url_for(:action => :show_location)
    end
    #if @params['available'].to_i == 0 || @params['status'] == 'ok'
    #  WebView.navigate url_for(:action => :show_location_error)
    #end
  end
  
  def get_geolocation(tmpPart)
    $tempGlob = tmpPart
    #Properly format the Address 
    while tmpPart.address.include? ' '
      tmpPart.address.sub!(' ','+')
    end
    
    Rho::AsyncHttp.get(
      :url => "http://where.yahooapis.com/geocode?q=#{tmpPart.address},+#{tmpPart.city},+#{tmpPart.state}",
      :callback => url_for(:action => :yahoo_callback)
    )
      
    puts "END"
    redirect :action => :index
  end
  
  # Need to pass partner params into here
  def yahoo_callback
    @partner = Partner.find($tempGlob.object)
    
    if @params['status'] != 'ok'
      puts @params
    else
      @@get_result = @params["body"]
      
        require 'rexml/document'

      doc = REXML::Document.new(@@get_result)
      @lat = ""
      @long = ""
      
      doc.elements.each('ResultSet/Error') do |ele|
        @temp = ele.text
        if @temp.to_i != 0
          Alert.show_popup(
              :message => 'Error with Address can not get GPS coordinates',
              :title => 'GeoLocation Error',
              :buttons => ['ok'],
              :callback => url_for(:action => :index)
          )
        end
      end
        
      doc.elements.each('ResultSet/Result/offsetlat') do |ele|  #Pass the macthing XML portion
        @lat = ele.text                    #Add the latitude XML element into Array
        puts @lat
      end
      
      doc.elements.each('ResultSet/Result/offsetlon') do |ele|  #Pass the macthing XML portion
        @long = ele.text                   #Add the longitude XML element into Array
        puts @long
      end
      @partner.update_attributes("lat" => @lat, "long" => @long)
    end
  end
  
end
