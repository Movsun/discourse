require_dependency 'jobs/regular/update_username'

class UsernameChanger

  def initialize(user, new_username, actor = nil)
    @user = user
    @old_username = user.username
    @new_username = new_username
    @actor = actor
  end

  def self.change(user, new_username, actor = nil)
    self.new(user, new_username, actor).change
  end

  def change(asynchronous: true)
    if @actor && @old_username != @new_username
      StaffActionLogger.new(@actor).log_username_change(@user, @old_username, @new_username)
    end

    @user.username = @new_username
    if @user.save

      args = {
        user_id: @user.id,
        old_username: @old_username,
        new_username: @new_username
      }

      if asynchronous
        Jobs.enqueue(:update_username, args)
      else
        Jobs::UpdateUsername.new.execute(args)
      end

      return true
    end

    false
  end

end
