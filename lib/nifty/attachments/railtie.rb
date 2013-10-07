module Nifty
  module Attachments
    class Railtie < Rails::Railtie #:nodoc:
      
      initializer 'nifty.attachments.initialize' do |app|
        
        require 'nifty/attachments/middleware'
        app.config.middleware.use Nifty::Attachments::Middleware
        
        ActiveSupport.on_load(:active_record) do
          require 'nifty/attachments/attachment'
          require 'nifty/attachments/model_extension'
          ::ActiveRecord::Base.send :include, Nifty::Attachments::ModelExtension
        end
        
      end
      
      generators do
        require 'nifty/attachments/migration_generator'
      end
      
    end
  end
end
