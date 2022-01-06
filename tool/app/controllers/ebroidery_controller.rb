class EbroideryController < ApplicationController
  
  def tool
    @files = get_primitives()
    render :layout => "full_screen"
  end
  def gallery
    @files = get_files("stitches")
    render :layout => "full_screen"
  end
  def keys
    legend = YAML.load_file(Rails.root.join('app', 'models', 'tool_keys.yaml'))
    render :json => legend
  end
  # HELPER METHODS
  def get_primitives
    files = {path: "/primitives/", filenames: Dir.glob("public/primitives/*").collect!{|c| c.split('/')[2..-1].join('/')}}
    files[:filenames].collect!{|f| {:collection => f.split('.')[0].split('-')[0].split('_')[0].titlecase, :filename => f, :title => f.split(".")[0].titlecase}}
    files
  end
  def get_files(path)
    files = {path: path, filenames: Dir.glob("public/#{path}/*").collect!{|c| c.split('/')[2..-1].join('/')}}
    collection = files[:filenames].collect!{|f| {:collection => f.split('.')[0].split('-')[0].split('_')[0].titlecase, :filename => "/"+path+"/"+f, :sketch => f.split(".")[0].titlecase.gsub(/\s/, "")+"Sketch", :title => f.split(".")[0].titlecase}}
    collection.group_by{ |i| i[:collection] }
  end
  
end
