class AddImageTmpToGifs < ActiveRecord::Migration
  def change
    add_column :gifs, :image_tmp, :string
  end
end
