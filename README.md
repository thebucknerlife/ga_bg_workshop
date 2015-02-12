#Rails Background Workers

Tonight we will discuss background workers. We'll cover:

* What a background worker is
* Why they're awesome
* When to use them
* Install Redis
* Add Sidekiq to Gifster for email
* Add Sidekiq to Gifster for image uploads

Then we will install Redis (for Sidekiq) and add Sidekiq to an existing app, Gifster.

##Background Workers
---

Background workers are separate processes that can run along side a Rails server.

##Getting Started with Sidekiq
---

1. First we need to install Redis. We can do that via homebrew: `$ brew install redis`. Paste the followup instruction to keep Redis running locally.

2. We check Redis is running by pinging it with `$ redis-cli ping`.

3. Let's add Sidekiq to our Gemfile: 

    ```
    # rest of Gemfile

    gem 'sidekiq'
    ```

    Then `bundle install`.

4. You can test Sidekiq is worker by starting it in a separate tab: `bundle exec sidekiq`. If it starts and then waits for jobs, we're good.

##Our First Worker

5. Now, we can write our first worker:

    ```rb
    class WelcomeEmailWorker
      include Sidekiq::Worker

      def perform(user_id)
        user = User.find(user_id)
        WelcomeMailer.welcome_email(user).deliver
      end
    end
    ```

6. How do we run a Sidekiq worker? Simple: `WelcomeEmailWorker.perform_async(1)`. But the task won't actually be done until we start the Sidekiq process.

7. Replace the mailer line in our UserController#create action with a call to spin up the worker:

    ```rb
    # app/controllers/users_controller.rb
    # top of file

    def create
      @user = User.new(params.require(:user).permit(:password, :password_confirmation, :username, :email, :name))

      if @user.save
        session[:user_id] = @user.id
        WelcomeEmailWorker.perform_async(@user.id)
        redirect_to gifs_path
      else
        render :new
      end
    end

    # rest of file
    ```

Now your email is moved into a BG worker.

8. To start Sidekiq, open a new tab and run: `bundle exec sidekiq`. Test the worker by restarting your Rails server, starting your Sidekiq process, then signup as a new user. You should see the jump `start` and `finish` in the sidekiq process after you signup.

##Moving Image Processing Into Sidekiq

9. For image process, we need an additional gem to help: [Carrierwave Backgrounder](https://github.com/lardawge/carrierwave_backgrounder). This gem ties into Carrierwave to handle the actual image files so we can move them to the background.  Add `gem 'carrierwave_backgrounder'` to your Gemfile and bundle!

10. After bundling, we run the installer script: `$ rails g carrierwave_backgrounder:install`. Then adjust the config file to use Sidekiq.

11. Now, we need to include this module in our Uploader: 

    ```rb
    class ImageUploader < CarrierWave::Uploader::Base
      include ::CarrierWave::Backgrounder::Delay

      # rest of the file
    ```

12. We need to tell the GIF model to use the backgrounder:

    ```rb
    class Gif < ActiveRecord::Base
      mount_uploader :image, ImageUploader
      store_in_background :image

    # rest of the file
    ```

    And we need to add a column called `image_tmp` to our Gif to handle the temporary image.

    ```
    $ rails g migration add_image_tmp_to_gifs image_tmp:string
    $ rake db:migrate
    ```

13. We also need to create a sidekiq.yml file to create a queue for carrierwave.

    ```
    # config/sidekiq.yml

    :queues:
      - [default, 5]
      - [carrierwave, 3]
    ```

14. If all of that worked, our form now remotes handles image uploads! Restart your server and start sidekiq to see!

Awesome. Now our app easily moves jobs to a Sidekiq worker!