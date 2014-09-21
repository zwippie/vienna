module Vienna
  module Persistence
    def save
      @new_record ? create : update
    end

    def create
      # self.class.adapter.create_record(self).then do
      # self.class.adapter.create_record(self) do
      #   did_create
      # end
      self.class.adapter.create_record(self)
    end

    def update(attributes = nil)
      self.attributes = attributes if attributes
      self.class.adapter.update_record self
    end

    def destroy
      self.class.adapter.delete_record self
    end

    def did_destroy
      @destroyed = true
      self.class.adapter.cache[id] = nil
      self.class.all.delete self

      trigger :destroy
    end

    def did_create
      self.new_record = false
      
      # add_model_for_id model.class, model, id
      # nilled = self.class.all.select {|t| t.id.nil? }
      # puts "did_create BEFORE delete, nilled: #{nilled.count}"
      # self.class.all.delete_if {|t| t.id.nil? }
      # puts "did_create AFTER delete, nilled: #{nilled.count}"
      
      self.class.all.push self

      trigger :create
    end

    def did_update
      trigger :update
    end
  end
end
