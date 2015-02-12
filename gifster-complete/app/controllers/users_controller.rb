class UsersController < ApplicationController

  def new
    @user = User.new
  end

  def create
    @user = User.new(params.require(:user).permit(:password, :password_confirmation, :username, :email, :name))

    if @user.save
      session[:user_id] = @user.id
      WelcomeEmailWorker.perform_async(@user.id) # queue a email worker to be done asap.
      redirect_to gifs_path
    else
      render :new
    end
  end

end