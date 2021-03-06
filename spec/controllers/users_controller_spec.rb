require 'spec_helper'

describe UsersController do
  render_views

  describe "For users after signing-up" do
    before(:each) do
      @user_one = Factory( :user, :name  => "Tuomas",
                                  :email => "aim@tuomas.com")
      @user_two = Factory( :user, :name  => "Tarja",
                                  :email => "aim@tarja.com")
    end

    it "should send an e-mail about registration to correct person" do
      UserMailer.registration_confirmation(@user_one).deliver
      ActionMailer::Base.deliveries.last.to.should     == [@user_one.email]
      ActionMailer::Base.deliveries.last.to.should_not == [@user_two.email]
    end
  end


  describe "GET 'index'" do

      describe "for non-signed-in users" do
        it "should deny access" do
          get :index
          response.should redirect_to( signin_path )
          flash[:notice].should =~ /sign in/i
        end
      end

      describe "for signed-in users" do

        before(:each) do
          @user = test_sign_in( Factory(:user) )
          second = Factory( :user, :name => "Bob", 
                                   :email => "an@example.com" )
          third  = Factory( :user, :name => "Ben", 
                                   :email => "ano@example.net")

          @users = [@user, second, third]
          30.times do
            @users << Factory(:user, :email => Factory.next(:email))
          end
        end

        it "should be successful" do
          get :index
          response.should be_success
        end

        it "should have the right title" do
          get :index
          response.should have_selector("title", :content => "All users")
        end

        it "should have an element for each user" do
          get :index
          @users[0..2].each do |user|
            response.should have_selector("li", :content => user.name)
          end
        end
        
        it "should paginate users" do
          get :index
          response.should have_selector("div.pagination")
          response.should have_selector("span.disabled", :content => "Previous")
          response.should have_selector("a", :href => "/users?page=2",
                                             :content => "2")
          response.should have_selector("a", :href => "/users?page=2",
                                             :content => "Next")
        end
        
        it "should deny access to register new user" do
          get 'new'
          response.should redirect_to( users_path )
        end    
         
        it "should deny access to create new user" do
          get 'create'
          response.should redirect_to( users_path )
        end
   
      end
  end
  
  describe "GET 'show'" do
      before(:each) do
        @user  = Factory(:user)                                               # Create user by using factory from spec/factories.rb 
        50.times do
          @user.microposts << Factory(:micropost, 
                                      :user => @user, 
                                      :content => "Foo bar")         
        end
      end
      
      describe "for signed-in users" do
        before(:each) do
          other_user = Factory(:user, :email => Factory.next(:email))
          other_user.follow!(@user)
        end
        
        it "should have right number of microposts in sidebar on profile" do
          get :show, :id => @user
          num_of_user_posts = @user.microposts.count
          response.should have_selector("table.profile",                      
                                         :content => "Microposts " + num_of_user_posts.to_s)
        end
        
        it "should paginate microposts" do
          get :show, :id => @user
          response.should have_selector("div.pagination")
          response.should have_selector("span.disabled", :content => "Previous")
          response.should have_selector("a", :href => "/users/" + @user.id.to_s + "?page=2",
                                             :content => "2")
          response.should have_selector("a", :href => "/users/" + @user.id.to_s + "?page=2",
                                             :content => "Next")
#          response.should have_selector("a", :href => "/users/1?page=2",
#                                             :content => "2")
#          response.should have_selector("a", :href => "/users/1?page=2",
#                                             :content => "Next")
        end
        
        it "should have right follower/following counts" do
          get :show, :id => @user
          response.should have_selector("a", :href => following_user_path(@user),
                                                     :content => "0 following")
          response.should have_selector("a", :href => followers_user_path(@user),
                                                     :content => "1 follower")
        end
      end


      it "should be successful" do
        get :show, :id => @user                                               # :show and 'show' are equal. :id => @use equal :id => @user.id
        response.should be_success
      end

      it "should find the right user" do
        get :show, :id => @user
        assigns(:user).should == @user
      end
      
      it "should have the right title" do
        get :show, :id => @user
        response.should have_selector("title", :content => @user.name)
      end

      it "should include the user's name" do
        get :show, :id => @user
        response.should have_selector("h1", :content => @user.name)
      end

      it "should have a profile image" do
        get :show, :id => @user
        response.should have_selector("h1>img", :class => "gravatar")         #"h1>img" makes sure that the img tag is inside the h1 tag.                                                                             #:class is option for testing CSS class of the element
      end
      
      it "should show the user's microposts" do
          mp1 = Factory(:micropost, :user => @user, :content => "Foo bar")
          mp2 = Factory(:micropost, :user => @user, :content => "Baz quux")
          get :show, :id => @user
          response.should have_selector("span.content", :content => mp1.content)
          response.should have_selector("span.content", :content => mp2.content)
      end
  end
  
  describe "POST 'create'" do

      describe "failure" do
        before(:each) do
          @attr = { :name => "", :email => "", :password => "",
                    :password_confirmation => "" }
        end

        it "should not create a user" do
          lambda do
            post :create, :user => @attr
          end.should_not change(User, :count)
        end

        it "should have the right title" do
          post :create, :user => @attr
          response.should have_selector("title", :content => "Sign up")
        end

        it "should render the 'new' page" do
          post :create, :user => @attr
          response.should render_template('new')
        end
      end
      
      describe "success" do
        before(:each) do
              @attr = { :name => "New User", :email => "user@example.com",
                        :password => "foobar", :password_confirmation => "foobar" }
        end

        it "should create a user" do
              lambda do
                post :create, :user => @attr
              end.should change(User, :count).by(1)
        end

        it "should redirect to the user show page" do
              post :create, :user => @attr
              response.should redirect_to(user_path(assigns(:user)))
        end
        
        it "should have a welcome message" do
              post :create, :user => @attr
              flash[:success].should =~ /welcome to the sample app/i
        end
        
        it "should sign the user in" do
              post :create, :user => @attr
              controller.should be_signed_in
        end
      end      
  end  
    
  describe "GET 'new'" do
    it "should be successful" do
      get 'new'
      response.should be_success
    end

    it "should have the right title" do
      get 'new'
      response.should have_selector("title", :content => "Sign up")
    end
    
    it "should have a name field" do
      get :new
      response.should have_selector("input[name='user[name]'][type='text']")  #check that inside <input/> name='user[name]' and type='text'
    end
    
    it "should have an email field" do
      get :new
      response.should have_selector("input[name='user[email]'][type='text']")
    end
    
    it "should have a password field" do
      get :new
      response.should have_selector("input[name='user[password]'][type='password']")
    end
    
    it "should have a password confirmation field" do
      get :new
      response.should have_selector("input[name='user[password_confirmation]'][type='password']")
    end
  end
  
  describe "GET 'edit'" do
      before(:each) do
        @user = Factory(:user)
        test_sign_in(@user)                                                   #We use that to sign in as a user.
      end

      it "should be successful" do
        get :edit, :id => @user
        response.should be_success
      end

      it "should have the right title" do
        get :edit, :id => @user
        response.should have_selector("title", :content => "Edit user")
      end

      it "should have a link to change the Gravatar" do
        get :edit, :id => @user
        gravatar_url = "http://gravatar.com/emails"
        response.should have_selector("a", :href => gravatar_url,
                                           :content => "Change your avatar")
      end
  end
  
  describe "PUT 'update'" do
      before(:each) do
        @user = Factory(:user)
        test_sign_in(@user)
      end

      describe "failure" do
        before(:each) do
          @attr = { :email => "", :name => "", :password => "",
                    :password_confirmation => "" }
        end

        it "should render the 'edit' page" do
          put :update, :id => @user, :user => @attr
          response.should render_template('edit')
        end

        it "should have the right title" do
          put :update, :id => @user, :user => @attr
          response.should have_selector("title", :content => "Edit user")
        end
      end

      describe "success" do
        before(:each) do
          @attr = { :name => "New Name", :email => "user@example.org",
                    :password => "barbaz", :password_confirmation => "barbaz" }
        end

        it "should change the user's attributes" do
          put :update, :id => @user, :user => @attr
          @user.reload
          @user.name.should  == @attr[:name]
          @user.email.should == @attr[:email]
        end

        it "should redirect to the user show page" do
          put :update, :id => @user, :user => @attr
          response.should redirect_to( user_path(@user) )
        end

        it "should have a flash message" do
          put :update, :id => @user, :user => @attr
          flash[:success].should =~ /updated/
        end
      end
  end
  
  describe "authentication of edit/update pages" do
      before(:each) do
        @user = Factory(:user)
      end

      describe "for non-signed-in users" do
        it "should deny access to 'edit'" do
          get :edit, :id => @user
          response.should redirect_to( signin_path )
        end

        it "should deny access to 'update'" do
          put :update, :id => @user, :user => {}
          response.should redirect_to( signin_path )
        end
      end
      
      describe "for signed-in users" do
          before(:each) do
            wrong_user = Factory( :user, :email => "user@example.net" )
            test_sign_in( wrong_user )
          end

          it "should require matching users for 'edit'" do
            get :edit, :id => @user
            response.should redirect_to( root_path )
          end

          it "should require matching users for 'update'" do
            put :update, :id => @user, :user => {}
            response.should redirect_to( root_path )
          end
      end
  end
  
  describe "DELETE 'destroy'" do

      before(:each) do
        @user = Factory(:user)
      end

      describe "as a non-signed-in user" do
        it "should deny access" do
          delete :destroy, :id => @user
          response.should redirect_to(signin_path)
        end
      end

      describe "as a non-admin user" do
        it "should protect the page" do
          test_sign_in(@user)
          delete :destroy, :id => @user
          response.should redirect_to(root_path)
        end
      end

      describe "as an admin user" do
        before(:each) do
          @admin = Factory(:user, :email => "admin@example.com", :admin => true)
          test_sign_in(@admin)
        end

        it "should destroy the user" do
          lambda do
            delete :destroy, :id => @user
          end.should change(User, :count).by(-1)
        end

        it "should redirect to the users page" do
          delete :destroy, :id => @user
          response.should redirect_to( users_path )
        end
        
        it "should allow to delete users" do
          get :index
          response.should have_selector( "a", :content =>"delete" )
        end
        
        it "should deny to delete themselves" do
          lambda do
            delete :destroy, :id => @admin                                    #Used @admin instead of admin. It should be local variable.
          end.should change( User, :count ).by( 0 )
        end
      end
  end
  
  describe "follow pages" do

      describe "when not signed in" do

        it "should protect 'following'" do
          get :following, :id => 1
          response.should redirect_to(signin_path)
        end

        it "should protect 'followers'" do
          get :followers, :id => 1
          response.should redirect_to(signin_path)
        end
      end

      describe "when signed in" do

        before(:each) do
          @user = test_sign_in(Factory(:user))
          @other_user = Factory(:user, :email => Factory.next(:email))
          @user.follow!(@other_user)
        end

        it "should show user following" do
          get :following, :id => @user
          response.should have_selector("a", :href => user_path(@other_user),
                                             :content => @other_user.name)
        end

        it "should show user followers" do
          get :followers, :id => @other_user
          response.should have_selector("a", :href => user_path(@user),
                                             :content => @user.name)
        end
      end
    end
end