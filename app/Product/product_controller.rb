require 'rho/rhocontroller'
require 'helpers/browser_helper'

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
    if @product
      render :action => :show, :back => url_for(:action => :index)
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
  
  # This currently only works for android atm (Will update later)
  def define_scanner
    $scanners = []                                                              #Init the scanner array
    #if System.get_property('platform') == 'ANDROID'
    #  Barcode.enumerate()
    #  $scanners = [{'deviceName'=>'SCN1', 'friendlyName'=>'SCANNER_INTERNAL'}]    #Set the scanner on the ET1
    #else
      Barcode.enumerate()
      Barcode.enumerate(url_for(:action => :enum_callback))
    #end
    redirect url_for(:action => :scan)                                          #Calling the Scan function
    #puts Barcode.enumerate()
    #enum_callback
    #product_controller.enum_callback
    #render :action => :scan, :back =>  url_for(:action => :index)
    #redirect :action => :scan
    #Webview.navigate(url_for( :action => :scan))
  end
  
  def enum_callback
    puts "enum_callback : #{@params}"
    $scanners = @params['scannerArray']
    puts "$scanners : #{$scanners}"
    Webview.navigate url_for(:action => :scan)
  end
  
  def search
    # Barcode.enable(url_for(:action))
    #Barcode.start  This is handled by the take_barcode method
    Barcode.take_barcode(url_for(:action => :scan_barcode), {:name => $scanners})
    redirect :action => :wait
  end
  
  def scan
    scanner = @params['scanner']                      
    puts "take - using scanner: #(scanner)"                                      #Prints string (can be read in debugger)
    Barcode.take_barcode(url_for(:action => :scan_callback), {:deviceName => scanner})    #Sets the callback for when a barcode is decoded and scanner to use
    redirect :action => :wait                                                    #Waiting while the camera is looking for a barcode
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
  
  def index_callback
    WebView.navigate url_for(:action => :index)
  end
  
end
