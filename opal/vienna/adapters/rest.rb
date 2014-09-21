module Vienna
  class Model
    def self.url(url = nil)
      url ? @url = url : @url
    end
  end
end

module Vienna
  # Adapter for a REST backend
  class RESTAdapter < Adapter
    def find(record, id)
      url = record_url record.class, id

      http_request(url).then do |response|
        did_find record, id, response.json
        record
      end
    end

    def did_find(record, id, json)
      record.load extract_record_data(record, json)
    end

    def extract_record_data(record, data)
      if root = record.class.root_key
        data[root]
      else
        data
      end
    end

    def create_record(record, &block)
      url = record_url record

      options = { 
        dataType: "json", 
        payload: record.as_json, 
        headers: { 
          :'X-Requested-With' => 'XMLHTTPRequest' 
        }
      }

      HTTP.post(url, options) do |response|
        if response.ok?
          new_record = record.class.load_json response.body
          record.class.trigger :ajax_success, response
          # record.did_create
          record.class.trigger :create, new_record
        else
          record.trigger :ajax_error, response
        end
      end

      block.call(record) if block
    end

    def update_record(record, &block)
      url = record_url(record)
      options = {
        dataType: "json",
        payload: record.as_json, 
        headers: { 
          :'X-Requested-With' => 'XMLHTTPRequest' 
        }
      }
      HTTP.put(url, options) do |response|
        if response.ok?
          record.class.load_json response.body
          record.class.trigger :ajax_success, response
          record.did_update
          record.class.trigger :update, record
        else
          record.trigger :ajax_error, response
        end
      end

      block.call(record) if block
    end

    def delete_record(record, &block)
      options = {
        dataType: "json", 
        headers: { 
          :'X-Requested-With' => 'XMLHTTPRequest' 
        }
      }
      url = record_url(record)

      HTTP.delete(url, options) do |response|
        if response.ok?
          record.did_destroy
          record.class.trigger :ajax_success, response
          record.class.trigger :destroy, record
        else
          record.class.trigger :ajax_error, response
        end
      end

      block.call(record) if block
    end

    def fetch(model, options = {}, &block)
      id = options.fetch(:id, nil)
      params = options.fetch(:params, nil)
      url = id ? "#{record_url(model)}/#{id}" : record_url(model)
      options = {
        dataType: "json", 
        data: params, 
        headers: { 
          :'X-Requested-With' => 'XMLHTTPRequest' 
        }
      }.merge(options)

      HTTP.get(url, options) do |response|
        if response.ok?
          response.body.map { |json| model.load_json json }
          model.trigger :ajax_success, response
          model.trigger :refresh, model.all
        else
          model.trigger :ajax_error, response
        end
      end

      block.call(model.all) if block
    end

    def record_url(record)
      return record.to_url if record.respond_to? :to_url
      return record.url if record.respond_to? :url

      if klass_url = record.class.url
        return "#{klass_url}/#{record.id}"
      end

      raise "Model does not define REST url: #{record}"
    end
  end
end
