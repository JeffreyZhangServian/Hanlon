module ProjectHanlon
  module Persist
    # In-memory version of {ProjectHanlon::Persist::PluginInterface}
    # used by {ProjectHanlon::Persist::Controller} when ':memory' is the 'persist_mode'
    # in ProjectHanlon configuration
    class MemoryPlugin < PluginInterface
      # Closes connection if it is active
      #
      # @return [Boolean] Connection status
      #
      def teardown
        @collections = nil
      end

      # Establishes connection to the data store.
      #
      # @param options [Hash] "Connection" options (ignored for this plugin type)
      # @return [Boolean] Connection status
      #
      def connect(options = {})
        @collections = Hash.new do |hash, key| hash[key] = {} end
      end

      # Disconnects connection
      #
      # @return [Boolean] Connection status
      #
      def disconnect
        @collections = nil
      end

      # Checks whether the database is connected and active
      #
      # @return [Boolean] Connection status
      #
      def is_db_selected?
        !!@collections
      end

      # Returns all entries from the collection named 'collection_name'
      #
      # @param collection_name [Symbol]
      # @return [Array<Hash>]
      #
      def object_doc_get_all(collection_name)
        @collections[collection_name].values.map {|e| Utility.decode_symbols_in_hash(JSON.parse!(e[:json])) }
      end

      # Returns the entry keyed by the '@uuid' of the given 'object_doc' from the collection
      # named 'collection_name'
      #
      # @param object_doc [Hash]
      # @param collection_name [Symbol]
      # @return [Hash] or nil if the object cannot be found
      #
      def object_doc_get_by_uuid(object_doc, collection_name)
        entry = @collections[collection_name][object_doc['@uuid']]
        if entry
          Utility.decode_symbols_in_hash(JSON.parse!(entry[:json]))
        else
          nil
        end
      end

      # Adds or updates 'obj_document' in the collection named 'collection_name' with an incremented
      # '@version' value
      #
      # @param object_doc [Hash]
      # @param collection_name [Symbol]
      # @return [Hash] The updated doc
      #
      def object_doc_update(object_doc, collection_name)
        encoded_object_doc = Utility.encode_symbols_in_hash(object_doc)
        uuid = encoded_object_doc['@uuid']
        raise ArgumentError.new('Document has no uuid') if uuid === nil

        entries = @collections[collection_name]
        if entries === nil
          entries = Hash.new
          @collections[collection_name] = entries
        end

        entry = entries[uuid]
        old_version = encoded_object_doc['@version']
        if entry === nil
          version = 1
        else
          version = (old_version > 0 ? old_version : entry[:version]) + 1
        end
        encoded_object_doc['@version'] = version
        entries[uuid] = { :version => version, :json => JSON.generate(encoded_object_doc) }
        encoded_object_doc
      end

      # Adds or updates multiple object documents in the collection named 'collection_name'. This will
      # increase the '@version' value of all the documents
      #
      # @param object_docs [Array<Hash>]
      # @param collection_name [Symbol]
      # @return [Array<Hash>] The updated documents
      #
      def object_doc_update_multi(object_docs, collection_name)
        object_docs.collect {|object_doc|object_doc_update(object_doc,collection_name)}
      end

      # Removes a document identified by from the '@uuid' of the given 'object_doc' from the
      # collection named 'collection_name'
      #
      # @param object_doc [Hash]
      # @param collection_name [Symbol]
      # @return [Boolean] - returns 'true' if an object was removed
      #
      def object_doc_remove(object_doc, collection_name)
        uuid = object_doc['@uuid']
        raise ArgumentError.new('Document has no uuid') if uuid === nil
        entries = @collections[collection_name]
        entries.delete(uuid) unless entries === nil
        true
      end

      # Removes all documents from the collection named 'collection_name'
      #
      # @param collection_name [Symbol]
      # @return [Boolean] - returns 'true' if all entries were successfully removed
      #
      def object_doc_remove_all(collection_name)
        @collections.delete(collection_name)
        true
      end
    end
  end
end
