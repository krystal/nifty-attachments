require 'nifty/attachments/processor'

module Nifty
  module Attachments
    module ModelExtension

      def self.included(base)
        base.extend ClassMethods
        base.after_save do
          if @pending_attachment_deletions
            self.nifty_attachments.where(:role => @pending_attachment_deletions).destroy_all
          end

          if @pending_attachments
            @pending_attachments.each do |pa|
              old_attachments = self.nifty_attachments.where(:role => pa[:role]).pluck(:id)
              attachment = self.nifty_attachments.create(:uploaded_file => pa[:file], :role => pa[:role])
              self.nifty_attachments.where(:id => old_attachments).destroy_all

              processor = Processor.new(attachment)
              processor.queue_or_process
            end
            @pending_attachments = nil
          end
        end
      end

      module ClassMethods

        def attachment(name, options = {}, &block)
          unless self.reflect_on_all_associations(:has_many).map(&:name).include?(:nifty_attachments)
            has_many :nifty_attachments, :as => :parent, :dependent => :destroy, :class_name => 'Nifty::Attachments::Attachment'
          end

          has_one name, -> { select(:id, :token, :digest, :parent_id, :parent_type, :file_name, :file_type).where(:role => name) }, :class_name => 'Nifty::Attachments::Attachment', :as => :parent

          if block_given?
            Processor.register(self, name, &block)
          end

          define_method "#{name}_file" do
            instance_variable_get("@#{name}_file")
          end

          define_method "#{name}_file=" do |file|
            instance_variable_set("@#{name}_file", file)
            if file.is_a?(ActionDispatch::Http::UploadedFile)
              @pending_attachments ||= []
              @pending_attachments << {:role => name, :file => file}
            else
              nil
            end
          end

          define_method "#{name}_delete" do
            instance_variable_get("@#{name}_delete")
          end

          define_method "#{name}_delete=" do |delete|
            instance_variable_set("@#{name}_delete", delete)
            unless delete.blank?
              @pending_attachment_deletions ||= []
              @pending_attachment_deletions << name
            end
          end
        end

      end

    end
  end
end
