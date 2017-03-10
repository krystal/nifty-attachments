# Nifty Attachments

Nifty attachments allow you to attach files/images/documents to Active Record models
with ease. Just define which attachments you wish to add and you can easily upload
them to your database.

* All attachment data is stored in your database
* Attachments are accessed at /attachment/{token}/{filename}. Middleware is provided to provide endpoint.

## Example Usage

In order to get started, add the gem to your Gemfile:

```ruby
gem 'nifty-attachments'
```

Once included, add the database table which will store your attachments.

```
$ rails generate nifty:attachments:migration
$ rake db:migrate
```

You can then define the attachments which you wish to use on any of your
models as such:

```ruby
class Person < ActiveRecord::Base
  attachment :cover_photo
  attachment :profile_picture
end
```

You can access any of your attachments easily through the methods as shown
below.

```ruby
# Accessing attachments
person = Person.find(person.id)
person.cover_photo            #=> Nifty::Attachments::Attachment
person.cover_photo.path       #=> "/attachment/145d17ed-d5e3-4b55-8c89-ecad9521ad73/snom-mm2.jpg"
person.cover_photo.file_name  #=> "snom-mm2.jpg"
person.cover_photo.digest     #=> "5d41402abc4b2a76b9719d911017c592"

# Pre-loading attachments will only load meta data, the actual content will
# not be loaded.
people = Person.includes(:profile_picture)
```

You can upload attachments straight from forms into your models by using the
`_file` accessor which is provided.

```erb
<% form_for @person, :html => {:multipart => true} do |f| %>
  <%= f.file_field :profile_picture_file %>
  <%= f.file_field :cover_photo_file %>
  <%= f.submit "Upload Attachments" %>
<% end %>
```

## Additional processing

If additional processing is required for an uploaded file, this can be acheived by passing a block to the `attachment` method.

```ruby
attachment :image do |attachment|
  # Do your additional processing on this attachment
  # This might include making thumbnails of an image etc...
end
```

By default, all processing will happen syncronously which may not be desirable if the processing will take time. To background the processing automatically, you can request the assistance of a worker. You need to use your own worker system to do this, an example is provided below.

```ruby
# Configure how jobs should be queued
Nifty::Attachments::Processor.background do |attachment|
  ProcessAttachmentJob.queue(:attachment_id => attachment.id)
end

# Define a job (if you don't preload your app, be sure to get the parent initialized before trying to run any processing
# otherwise the processors won't have registered),
class ProcessAttachmentJob < Jobster::Job
  def perform
    if attachment = Nifty::Attachments::Attachment.includes(:parent).find(params['attachment_id'])
      attachment.processor.process
    end
  end
end
```

Once you have registered a block for queueing (using `background`), all attachments for the application will be processed in the background.

## Coming Soon

There are a few extra things which need adding to this library:

* A test suite
* Validations
