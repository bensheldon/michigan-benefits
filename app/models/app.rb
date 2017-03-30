class App < ApplicationRecord
  belongs_to :user
  has_many :documents, inverse_of: :app
  has_many :household_members

  delegate :full_name, to: :user

  def form
    Form.new(self)
  end

  def mailing_address
    [mailing_street, mailing_city, mailing_zip].join(", ")
  end
end
