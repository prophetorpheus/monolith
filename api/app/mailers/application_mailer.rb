# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'Hack Club Team <team@mail.hackclub.com>',
          reply_to: 'Hack Club Team <team@hackclub.com>'
  layout 'mailer'
end
