class DriverError < ApplicationRecord
  belongs_to :driver_application

  validates :driver_application, presence: true
  validates :error_class, presence: true
  validates :error_message, presence: true
  validates :page_class, presence: true
  validates :page_html, presence: true
end
