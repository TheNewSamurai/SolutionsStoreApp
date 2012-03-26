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
end
