class PostsController < ApplicationController  
  before_filter :get_image_uploads
  
  @@return_early = Proc.new do 
    render :json => {:status => 0, :message => "Error"}.to_json
    return false
  end
  
  def index
    @posts = Post.all
  end
  
  def show
    @post = Post.find(params[:id])
  end
  
  def ajax_photo_destroy
    @image_uploads.images.where(:slot => params[:slot]).all.each do |image| 
      @status = image.destroy
    end
    if @status.nil?
      render :json => {:status => 0, :message => "Could Not Destroy Image!"}.to_json
    else
      render :json => {:status => 1, :message => "Successfully Destroyed Image!"}.to_json
    end
  end
  
  def ajax_photo_upload
    # To make things easier in Uploadify, I hijacked the `folder` parameter
    slot = params[:folder].match(/pic(\d)/) unless params[:folder].nil?
    slot = slot[1] unless slot.nil?
    @@return_early.call if slot.nil?
    slot = "pic#{slot}"
    
    @current_images = @image_uploads.images.where(:slot => slot).all
    @upload = Image.new(:slot => slot, :data => params[:Filedata])
    if not @image_uploads.images << @upload
      render :json => {:status => 0, :message => "Error Uploading Image!"}.to_json
    else
      @current_images.each{|image| image.destroy}
      render :json => {:status => 1, :img => my_thumb(@upload, 118, 118).url }.to_json
    end
  end
  
  def new
    @post = Post.new
  end
  
  def create
    @post = Post.new(params[:post])
    @post.assetable = @image_uploads.assetable
    Post.transaction do
      if @post.save
        @image_uploads.assetable = nil
        @image_uploads.destroy
        session[:image_upload_id] = nil
        redirect_to(posts_path, :notice => 'Post was successfully created.')
      else
        render :new
      end
    end
  end
  
private

  def get_image_uploads
    if session[:image_upload_id].nil?
      @image_uploads = ImageUpload.create!
    else
      @image_uploads = ImageUpload.find_or_create_by_id(session[:image_upload_id])
    end
    session[:image_upload_id] = @image_uploads.id
  end
  
end
