require 'spec_helper'

describe "Activity" do

  let(:photo) { Photo.create(:file => "image.jpg") }
  let(:album) { Album.create(:title => "A test album") }
  let(:user) { User.create(:full_name => "Christos") }

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
      @activity.receivers.size.should == 2
    end


    context "when activity not cached" do
      
      it "pushes activity to receivers" do
        @activity = Activity.publish(:new_photo_without_cache, {:actor => user, :object => photo, :target_object => album, :receivers => @send_to})
        @activity.receivers.size.should == 2
      end
      
    end
    
    it "overrides the recievers if option passed" do
      @activity = Activity.publish(:new_photo, {:actor => user, :object => photo, :target_object => album, :receivers => @send_to})
      @activity.receivers.size.should == 2
    end
    

    
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
  
  describe ".publish" do
    it "creates a new activity" do
      activity = Activity.publish(:new_photo, {:actor => user, :object => photo, :target_object => album})
      activity.should be_an_instance_of Activity
    end
  end

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

  describe 'batch insertion test' do

    max_batch_size = 5
    num_followers = 10

    it "no batch insert" do

      (1..num_followers).each do |n|
        activity = Activity.new({:verb => :enquiry, :receiver => user, :actor => user, :object => enquiry, :target_object => listing})
      end
    end

    it "batch insert" do

      options = {:verb => :enquiry, :receiver => user, :actor => user, :object => enquiry, :target_object => listing}

      verb = options.delete(:verb)
      definition = Streama::Definition.find(verb)

      batch = []
      (1..num_followers).each do |n|
        activity = {}
        activity["verb"] = verb

        options.each_pair do |key,val|
          keyString = key.to_s
          activity[keyString] = {}
          activity[keyString]["type"] = val.class.to_s
          activity[keyString]["id"] = val._id

          definitionObj = definition.send key

          cacheFields = definitionObj[val.class.to_s.downcase.to_sym][:cache]
          cacheFields.each do |field|
            activity[keyString][field.to_s] = val.send field
          end
        end

        activity["created_at"] = Time.now
        activity["updated_at"] = activity["created_at"]
        batch << activity

        if batch.size % max_batch_size == 0
          Activity.collection.insert(batch)
          batch = []
        end
      end

      Activity.collection.insert(batch)

      Activity.count.should == num_followers
      Activity.all.each do |a|

        a.load_instance(:actor).should be_instance_of User
        a.load_instance(:object).should be_instance_of Enquiry
        a.load_instance(:target_object).should be_instance_of Listing
        a.load_instance(:receiver).should be_instance_of User

        a.verb.should == :enquiry
        a.created_at.should be_instance_of Time
        a.updated_at.should be_instance_of Time
      end
    end
  end

  describe 'batch insertion performance test' do

    max_batch_size = 500
    num_followers = 50000

    it "no batch insert" do

      (1..num_followers).each do |n|
        activity = Activity.new({:verb => :enquiry, :receiver => user, :actor => user, :object => enquiry, :target_object => listing})
      end
    end

    it "batch insert" do

      options = {:verb => :enquiry, :receiver => user, :actor => user, :object => enquiry, :target_object => listing}

      verb = options.delete(:verb)
      definition = Streama::Definition.find(verb)

      batch = []
      (1..num_followers).each do |n|
        activity = {}
        activity["verb"] = verb

        options.each_pair do |key,val|
          keyString = key.to_s
          activity[keyString] = {}
          activity[keyString]["type"] = val.class.to_s
          activity[keyString]["id"] = val._id

          definitionObj = definition.send key

          cacheFields = definitionObj[val.class.to_s.downcase.to_sym][:cache]
          cacheFields.each do |field|
            activity[keyString][field.to_s] = val.send field
          end
        end

        activity["created_at"] = Time.now
        activity["updated_at"] = activity["created_at"]
        batch << activity

        if batch.size % max_batch_size == 0
          Activity.collection.insert(batch)
          batch = []
        end
      end

      Activity.collection.insert(batch)
    end

  end
  
end
