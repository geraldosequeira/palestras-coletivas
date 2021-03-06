#:nodoc:
class Event
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  include Geocoder::Model::Mongoid
  include Mongoid::Attributes::Dynamic
  include UpdateCounter
  include Commentable
  include Rateable

  field :name, type: String
  field :edition, type: String
  field :description, type: String
  field :stocking, type: Integer, default: 0
  field :tags, type: String
  field :start_date, type: Date
  field :end_date, type: Date
  field :deadline_date_enrollment, type: Date
  field :to_public, type: Boolean, default: false
  field :rating, type: Integer, default: 0
  field :place, type: String
  field :street, type: String
  field :district, type: String
  field :city, type: String
  field :state, type: String
  field :country, type: String
  field :coordinates, type: Array
  field :counter_registered_users, type: Integer, default: 0
  field :counter_present_users, type: Integer, default: 0
  field :accepts_submissions, type: Boolean, default: false
  field :block_presence, type: Boolean, default: false
  field :workload, type: Integer, default: 0

  mount_uploader :image, ImageUploader

  embeds_many :comments, as: :commentable
  embeds_many :ratings, as: :rateable
  has_and_belongs_to_many :users, inverse_of: :events
  has_many :schedules, dependent: :restrict_with_error
  has_many :enrollments, dependent: :restrict_with_error
  belongs_to :owner, class_name: 'User', inverse_of: :owner_events

  validates_presence_of :name, :edition, :tags, :start_date, :end_date,
                        :deadline_date_enrollment, :place, :street, :district,
                        :city, :state, :country, :workload
  validates_length_of :name, maximum: 50
  validates_length_of :edition, maximum: 10
  validates_length_of :description, maximum: 2000
  validates_numericality_of :stocking, greater_than_or_equal_to: 0
  validates_numericality_of :workload, greater_than_or_equal_to: 0

  slug :name, :edition

  scope :publics, -> { where(to_public: true) }
  scope :upcoming, -> { publics.desc(:start_date).limit(3) }
  scope :with_relations, -> do
    includes(:users, :schedules, :enrollments)
  end

  geocoded_by :address
  after_validation :geocode

  def name_edition
    "#{self.name} - #{self.edition}"
  end

  def address
    EventPolicy.new(self).address
  end

  def long_date
    date1 = start_date
    date2 = end_date

    date_between = I18n.t('titles.events.date.between')
    date_of = I18n.t('titles.events.date.of')
    date_to = I18n.t('titles.events.date.to')
    date_format = "%B #{date_of} %Y"
    day_one = zero_fill(date1.day)
    day_two = zero_fill(date2.day)

    if date1 == date2
      "#{I18n.t('titles.events.date.on')} #{locale(date1, :long)}"
    elsif date1.year != date2.year
      "#{date_of} #{locale(date1, :long)} #{date_to} #{locale(date2, :long)}"
    elsif date1.month == date2.month
      "#{date_of} #{day_one} #{date_to} #{day_two} #{date_of} #{locale(date1, date_format)}"
    else
      "#{date_of} #{day_one} #{date_of} #{locale(date1, '%B')} #{date_to} #{day_two} #{date_of} #{locale(date2, date_format)}"
    end
  end

  private

  def locale(date, format)
    I18n.l(date, format: format)
  end

  def zero_fill(field, size = 2)
    field.to_s.rjust(size, '0')
  end
end
