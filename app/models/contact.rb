# frozen_string_literal: true

class Contact < ApplicationRecord
  belongs_to :user
  belongs_to :user_file

  validates :name, presence: true
  validates :name, format: { with: /\A[a-zA-Z0-9\-]+\z/, message: "must be alphanumeric or with '-'" }
  validates :date_of_birth, presence: true
  validates :phone, presence: true
  validates :phone, format: {
    with: /\A\(\+\d{2}\)\s\d{3}[\- ]\d{3}[\- ]\d{2}[\- ]\d{2}\z/,
    message: "format must be (+00) 000 000 00 00 or (+00) 000-000-00-00"
  }
  validates :address, presence: true
  validates :credit_card, presence: true
  validates :email, presence: true
  validates :email, uniqueness: { scope: :user_id }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :user_id, presence: true
  validates :user_file_id, presence: true

  validate :date_format
  validate :card_validation

  before_create :set_franchise
  before_create :encrypt_credit_card

  def card_numbers
    ("*" * 10) + Encryption::EncryptionService.decrypt(credit_card)[-4..]
  end

  private

  def date_format
    return true if ymd_format(date_of_birth.to_s)

    add_phone_error
  end

  def ymd_format(date)
    begin
      ymd_format = Date.strptime(date, "%Y-%m-%d").instance_of?(Date)
    rescue TypeError, ArgumentError, Error
      return false
    end

    ymd_format
  end

  def detector
    CreditCardValidations::Detector.new(credit_card)
  end

  def card_validation
    return add_card_error unless detector.valid_luhn?

    true
  end

  def add_phone_error
    errors.add(:date_of_birth, "format must be 'Y-M-D' or 'Y/M/D.")
  end

  def add_card_error
    errors.add(:credit_card, "please enter a valid card number.")
  end

  def set_franchise
    self.franchise = detector.brand.to_s
  end

  def encrypt_credit_card
    self.credit_card = Encryption::EncryptionService.encrypt(credit_card)
  end
end
