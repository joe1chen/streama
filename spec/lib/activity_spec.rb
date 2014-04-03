require 'spec_helper'
require 'benchmark'

describe "Activity" do

  let(:photo) { Photo.create(:file => "image.jpg") }
  let(:album) { Album.create(:title => "A test album") }
  let(:user) { User.create(:full_name => "Christos") }
  let(:mars_user) { Mars::User.create(:full_name => "Mars User") }

  describe ".activity" do
    it "registers and return a valid definition" do
      @definition = Activity.activity(:test_activity) do
        actor :user, :cache => [:full_name]
        object :photo, :cache => [:file]
        target_object :album, :cache => [:title]
      end
      
      @definition.is_a?(Streama::Definition).should be true
    end
    
  end
  
  describe "#publish" do

    before :each do
      @send_to = []
      2.times { |n| @send_to << User.create(:full_name => "Custom Receiver #{n}") }
      5.times { |n| User.create(:full_name => "Receiver #{n}") }
    end
    
    it "pushes activity to receivers" do
      @activity = Activity.publish(:new_photo, {:actor => user, :object => photo, :target_object => album, :receivers => @send_to})
      #@activity.receivers.size.should == 2
      Activity.count.should == 2
    end


    context "when activity not cached" do
      
      it "pushes activity to receivers" do
        @activity = Activity.publish(:new_photo_without_cache, {:actor => user, :object => photo, :target_object => album, :receivers => @send_to})
        #@activity.receivers.size.should == 2
        Activity.count.should == 2
      end
      
    end
    
    it "overrides the recievers if option passed" do
      @activity = Activity.publish(:new_photo, {:actor => user, :object => photo, :target_object => album, :receivers => @send_to})
      #@activity.receivers.size.should == 2
      Activity.count.should == 2
    end

=begin
    context "when republishing"
      before :each do
        @actor = user
        @activity = Activity.publish(:new_photo, {:actor => @actor, :object => photo, :target_object => album})
        @activity.publish
      end
      
      it "updates metadata" do
        @actor.full_name = "testing"
        @actor.save
        @activity.publish
        @activity.actor['full_name'].should eq "testing"
      end
    end
=end
  end
  
  describe ".publish" do
    it "creates a new activity" do
      activity = Activity.publish(:new_photo, {:actor => user, :object => photo, :target_object => album})
      #activity.should be_an_instance_of Activity
      activity.should be_nil
    end

    it " creates a new activity when actor has namespace" do
      activity = Activity.publish(:new_mars_photo, {:actor => mars_user, :object => photo, :target_object => album})
      activity.should be_nil
    end
  end

=begin
  describe "#refresh" do
    
    before :each do
      @user = user
      @activity = Activity.publish(:new_photo, {:actor => @user, :object => photo, :target_object => album})
    end
    
    it "reloads instances and updates activities stored data" do
      @activity.save
      @activity = Activity.last    
      
      expect do
        @user.update_attribute(:full_name, "Test")
        @activity.refresh_data
      end.to change{ @activity.load_instance(:actor).full_name}.from("Christos").to("Test")
    end
    
  end
=end

  describe "#load_instance" do
    
    before :each do
      @activity = Activity.publish(:new_photo, {:actor => user, :object => photo, :target_object => album})
      @activity = Activity.last
    end
    
    it "loads an actor instance" do
      @activity.load_instance(:actor).should be_instance_of User
    end
    
    it "loads an object instance" do
      @activity.load_instance(:object).should be_instance_of Photo
    end
    
    it "loads a target instance" do
      @activity.load_instance(:target_object).should be_instance_of Album
    end
    
  end

  describe 'batch insertion performance test' do

    num_followers = 5000

    before :each do
      @send_to = []
      num_followers.times { |n| @send_to << User.create(:full_name => "Custom Receiver #{n}") }
    end

    it "should do performance test" do
      Benchmark.bm do |x|
        x.report("no batch insert:") do
          Activity.publish(:new_photo, {:actor => user, :object => photo, :target_object => album, :receivers => @send_to}, { use_batch_insert: false })
        end
        x.report("batch insert (batch size 500):") do
          Activity.publish(:new_photo, {:actor => user, :object => photo, :target_object => album, :receivers => @send_to})
        end
        x.report("batch insert (batch size 1000):") do
          Activity.publish(:new_photo, {:actor => user, :object => photo, :target_object => album, :receivers => @send_to}, { batch_size: 1000 })
        end
      end
    end
  end

end
