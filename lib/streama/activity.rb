require 'mongoid/compatibility'

module Streama
  module Activity
    extend ActiveSupport::Concern
    
    included do
      
      include Mongoid::Document
      include Mongoid::Timestamps
    
      field :verb,        :type => Symbol
      field :actor
      field :object
      field :target_object
      field :receiver

      if Mongoid::Compatibility::Version.mongoid2?
        index [['actor.id',         Mongo::ASCENDING], ['actor.type',         Mongo::ASCENDING]]
        index [['object.id',        Mongo::ASCENDING], ['object.type',        Mongo::ASCENDING]]
        index [['target_object.id', Mongo::ASCENDING], ['target_object.type', Mongo::ASCENDING]]
        index [['receiver.id',      Mongo::ASCENDING], ['receiver.type',      Mongo::ASCENDING], ['created_at', Mongo::DESCENDING]]
      else
        index({ :"actor.id"         => 1, :"actor.type"         => 1 })
        index({ :"object.id"        => 1, :"object.type"        => 1 })
        index({ :"target_object.id" => 1, :"target_object.type" => 1 })
        index({ :"receiver.id"      => 1, :"receiver.type"      => 1, :created_at => -1 })
      end
          
      validates_presence_of :actor, :verb
      before_save :assign_data
      
    end
    
    module ClassMethods

      # Defines a new activity type and registers a definition
      #
      # @param [ String ] name The name of the activity
      #
      # @example Define a new activity
      #   activity(:enquiry) do
      #     actor :user, :cache => [:full_name]
      #     object :enquiry, :cache => [:subject]
      #     target_object :listing, :cache => [:title]
      #   end
      #
      # @return [Definition] Returns the registered definition
      def activity(name, &block)
        definition = Streama::DefinitionDSL.new(name)
        definition.instance_eval(&block)
        Streama::Definition.register(definition)
      end

      # Publishes an activity using an activity name and data
      #
      # @param [ String ] verb The verb of the activity
      # @param [ Hash ] data The data to initialize the activity with.
      def publish(verb, data, options = nil)
        default_options = { use_batch_insert: true, batch_size: 500 }
        if options
          options = default_options.merge(options)
        else
          options = default_options
        end

        if data[:receiver]
          receiver = data.delete(:receiver)
          receivers = [ receiver ]
        else
          if data[:receivers]
            receivers = data.delete(:receivers)
          else
            receivers = data[:actor].followers
          end
        end

        if options && options[:use_batch_insert]
          # Use the Mongo Ruby driver and use the batch insert for performance.
          batch_insert(verb, data, receivers, options)
        else
          receivers.each do |receiver|
            activity = new({:verb => verb, :receiver => receiver}.merge(data))
            if activity.save
            end
          end
        end

        nil
      end
      
      def stream_for(actor, options={})
        query = { "receiver.id" => actor.id, "receiver.type" => actor.class.to_s }
        query.merge!({:verb => options[:type]}) if options[:type]
        self.where(query).desc(:created_at)
      end
      
      def actor_stream_for(actor, options={})
        query = { "receiver.id" => actor.id, "receiver.type" => actor.class.to_s, "actor.id" => actor.id }
        query.merge!({:verb => options[:type]}) if options[:type]
        self.where(query).desc(:created_at)
      end

      # Helper function called by publish to do batch insertions
      def batch_insert(verb, data, receivers, options = nil)
        default_options = { batch_size: 500 }
        if options
          options = default_options.merge(options)
        else
          options = default_options
        end

        definition = Streama::Definition.find(verb)

        # We're going to use the same activity timestamp for all our activities.
        activity_timestamp = Time.now

        # Need to construct the hash to pass into Mongo Ruby driver's batch insert
        batch = []
        receivers.each do |receiver|
          data[:receiver] = receiver

          activity = {}
          activity["verb"] = verb

          data.each_pair do |key,val|
            keyString = key.to_s
            activity[keyString] = {}
            activity[keyString]["type"] = val.class.to_s
            activity[keyString]["id"] = val._id

            definitionObj = definition.send key

            # Convert definitionObj to an array and access the second element which contains cache fields.
            definitionObjArray = definitionObj.to_a.first
            if definitionObjArray
              definitionObjArrayHash = definitionObjArray.last
              if definitionObjArrayHash
                cacheFields = definitionObjArrayHash[:cache]
                if cacheFields
                  cacheFields.each do |field|
                    activity[keyString][field.to_s] = val.send field
                  end
                end
              end
            end
          end

          activity["created_at"] = activity_timestamp
          activity["updated_at"] = activity_timestamp

          batch << activity

          # Perform the batch insert
          if 0 < batch.size && (batch.size % options[:batch_size] == 0)
            if Mongoid::Compatibility::Version.mongoid5_or_newer?
              self.collection.insert_many(batch)
            else
              self.collection.insert(batch)
            end

            batch = []
          end
        end

        # Perform the batch insert
        if 0 < batch.size
          if Mongoid::Compatibility::Version.mongoid5_or_newer?
            self.collection.insert_many(batch)
          else
            self.collection.insert(batch)
          end
        end
      end

    end

=begin
    # Publishes the activity to the receivers
    #
    # @param [ Hash ] options The options to publish with.
    #
    def publish(options = {})
      actor = load_instance(:actor)        
      self.receivers = (options[:receivers] || actor.followers).map { |r| { :id => r.id, :type => r.class.to_s } }
      self.save
      self
    end
=end
    
    # Returns an instance of an actor, object or target
    #
    # @param [ Symbol ] type The data type (actor, object, target) to return an instance for.
    #
    # @return [Mongoid::Document] document A mongoid document instance
    def load_instance(type)
      (data = self.read_attribute(type)).is_a?(Hash) ? data['type'].to_s.camelcase.constantize.find(data['id']) : data
    end
  
    def refresh_data
      assign_data
      save(:validates_presence_of => false)
    end
  
    protected


    def assign_data

      [:actor, :object, :target_object, :receiver].each do |type|
        next unless object = load_instance(type)

        class_sym = object.class.name.underscore.to_sym

        #raise Streama::InvalidData.new(class_sym) unless definition.send(type).has_key?(class_sym)

        hash = {'id' => object.id, 'type' => object.class.name}

        definitionForClass = definition.send(type)[class_sym]

        if definitionForClass
          if fields = definitionForClass.try(:[],:cache)
            if fields
              fields.each do |field|
                raise Streama::InvalidField.new(field) unless object.respond_to?(field)
                hash[field.to_s] = object.send(field)
              end
            end
          end
        end
        write_attribute(type, hash)
      end
    end
  
    def definition
      @definition ||= Streama::Definition.find(verb)
    end
    
  end
end
