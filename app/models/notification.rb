class Notification < ApplicationRecord
  mount_uploader :image, ImageUploader
end
