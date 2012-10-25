require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'base64.rb'

class ProductController < Rho::RhoController
  include BrowserHelper

  # GET /Product
  def index
    @products = Product.find(:all)
    render :back => '/app'
  end

  # GET /Product/{1}
  def show  
    @product = Product.find(@params['id'])
    flag = @params['flag']
      
    # Does a product exist?
    if @product
      # Is there an image for the product?
      if @product.image == ""
        # Have we prompted to take an image previously? If 'YES' (1) then just show page;
        # otherwise, Alert user if they would like to take a picture.
        if flag == '1'
          render :action => :show, :back => url_for(:action => :index)
        else
          Alert.show_popup( {
              :message => "Would you like to add a picture?",
              :title => "Add Picture?",
              :buttons => ["Yes", "No"],
              :callback => url_for(:action => :handle_picture, :id => @product.object)
          } )
        end
      else
        render :action => :show, :back => url_for(:action => :index)
      end
    else
      redirect :action => :index
    end
  end

  # GET /Product/new
  def new
    @product = Product.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Product/{1}/edit
  def edit
    @product = Product.find(@params['id'])
    if @product
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Product/create
  def create
    @product = Product.create(@params['product'])
    redirect :action => :index
  end

  # POST /Product/{1}/update
  def update
    @product = Product.find(@params['id'])
    @product.update_attributes(@params['product']) if @product
    redirect :action => :index
  end

  # POST /Product/{1}/delete
  def delete
    @product = Product.find(@params['id'])
    @product.destroy if @product
    redirect :action => :index  
  end
  
 ### SCANNING METHODS
  ## Working: MC75A, MC65, ET1 - Currently use trigger prefer auto start.
  ## Partial: 
  ## Failing: 
  
  # List the available scanners
  def enum_callback
    puts "enum_callback : #{@params}"
    $scanners = @params['scannerArray']
    puts "$scanners : #{$scanners}"
    WebView.navigate(url_for(:action => :scan))
  end
  
  def show_scanners
    render :back => '/app'
  end
  
  # Perform the scan
  def scan
    #scanner = @params['scanner']                      
    #puts "take - using scanner: #{scanner}"                                      #Prints string (can be read in debugger)
    #Barcode.take_barcode(url_for(:action => :scan_callback), {:deviceName => scanner})    #Sets the callback for when a barcode is decoded and scanner to use
    Scanner.enumerate
    puts Scanner.enumerate.to_s
    Scanner.enumerate(url_for(:action => :enum_callback))
    Scanner.enabled = 'SCN1'
    Scanner.decodeEvent = url_for(:action => :scan_callback)   #Sets the callback for when a barcode is decoded and scanner to use
    #redirect :action => :wait                                                    #Waiting while the camera is looking for a barcode
  end
  
  # Simple Scanner Enable for Decodes
  # Functionality will be expanded later especially for use cases
  def scanTake
    puts "DEVICE NAME !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  #{System.get_property('device_name')}"
    puts "DEVICE PLATFORM !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  #{System.get_property('platform')}"
    if System.get_property('device_name') == 'Motorola Solutions ET1N0' || System.get_property('platform') == 'WINDOWS'
      puts "MOT DEVICE"
      Scanner.enable
      Scanner.decodeEvent = url_for(:action => :scan_callback)
    elsif System.get_property('platform') == 'ANDROID' || System.get_property('platform') == 'APPLE'
      puts "CONSUMER DEVICE"
      Barcode.take_barcode((url_for :action => :scan_callback), {:camera => 'back'})
    end
    render :back => '/app'
  end
  
  def scan_callback
    status = @params['status']
    barcode = @params['barcode']

    if status == 'ok'
      @product = Product.find(:all, :conditions => { {:name => 'upc', :op => '='} => barcode}, :select => ['upc'])
      puts @product.to_s
      if @product == []
        #puts "Product ERROR"
        #WebView.navigate url_for(:action => :index)
        Alert.show_popup(
          :message => 'No Matching Barcode',
          :title => barcode,
          :buttons => ['ok'],
          :callback => url_for(:action => :index_callback)
          )
      else
        puts "Product Found"
        #puts @product[0].object
        #render :action => :show, :back => url_for(:action => :index)
        WebView.navigate url_for(:action => :show, :id => @product[0].object)
      end
    elsif status == 'cancel'
      Alert.show_popup(
        :message => 'Error during barcode scan',
        :title => 'ERROR',
        :buttons => ['ok'],
        :callback => url_for(:action => :index_callback)
        )
    end
  end
  
 ### CAMERA METHODS
  ## Working: ET1, MC75A
  ## Partial: MC55 - Camera starts but data is not passed.
  ## Failing: MC65 - Camera doesn't startup.
  
  def handle_picture
    button = @params['button_id']
    objectID = @params['id']
    # If the user selected 'Yes' we will take a picture
    if button=='Yes'
      WebView.navigate url_for(:action => :camera_picture, :id => objectID)
    end
  end
  
  # GET /Product/{1}/picture
  def picture
    @product = Product.find(@params['id'])
    if @product
      render :action => :picture, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end
  
  # Start the camera to take a picture of the item
  def camera_picture
      objectID = @params['id']
      puts "!!!!!!!!!!!!!!!!!PICTURE!!!!!!!!!!!!!!!!!!"
      puts Camera::get_camera_info('main')
      Camera::take_picture(url_for(:action => :camera_callback, :id => objectID))
  end
  
  # Save the Picture to display for the Product
  def camera_callback
    @product = Product.find(@params['id'])
    # When picture was taken successfully update the product w/ image
    if @params['status'] == 'ok'
      puts "ENTER CALLBACK WITH THIS PRODUCT ID!!!!!!!!!!!! #{@product}"
      
      #This is taking the picture and encoding it in base64 to display on device and upload if needed.
      #The io portion is taking the opened inmage and converting it to a String.
      #temp = Base64.encode64(open(@params['image_uri']) {|io| io.read})
      #puts "!~~~!~!~!~!~!~!~!~!~!~!~!~! #{temp}"
      #$placehold.update_attributes({"image" => "data:image/jpeg;base64," + temp.to_s })
      
      @product.update_attributes({"image" => @params['image_uri']})
    else
      Alert.show_popup(
        :message => @params['status'],
        :title => 'ERROR',
        :buttons => ['ok'],
        :callback => url_for(:action => :show_callback)
      )
    end
    #Return to the show page
    WebView.navigate(url_for :action => :show, :id => @product.object, :flag => '1')
  end
  
  def detect_camera
    if !System::get_property('has_camera')
      Alert.show_popup(
        :message => 'This Device does not have a Camera',
        :title => 'NO CAMERA',
        :buttons => ['ok'],
        :callback => url_for(:action => :index_callback)
      )
      render :back => '/app/product'
    else
      Alert.show_popup(
             :message => 'This Device HAS a Camera!!',
             :title => 'YES CAMERA',
             :buttons => ['ok'],
             :callback => url_for(:action => :index_callback)
      )
      render :action => :camera_default
      #Camera::take_picture(url_for(:action => :camera_callback))
    end
  end
  
  def index_callback
    #redirect :action => :index
    WebView.navigate url_for(:action => :index)
  end
  
  def show_callback
    redirect :action => :show
    #WebView.navigate url_for(:action => :show, :id => objectID)
  end
  
end
