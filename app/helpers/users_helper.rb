module UsersHelper
  def gravatar_for( user, options = { :size => 50 } )                         #:size - default size of avatar
      gravatar_image_tag( user.email.downcase, :alt => user.name,
                                               :class => 'gravatar',
                                               :gravatar => options )
  end
  
  def number_of_users
    User.all.count
  end
end
