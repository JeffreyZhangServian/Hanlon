# Root ProjectHanlon::Node namespace
class ProjectHanlon::Node < ProjectHanlon::Object
  attr_accessor :name
  attr_accessor :hw_id
  attr_accessor :attributes_hash
  attr_accessor :timestamp
  attr_accessor :last_state
  #attr_accessor :current_state
  #attr_accessor :next_state
  attr_accessor :dhcp_mac

  attr_accessor :tags
  attr_accessor :status

  # init
  # @param hash [Hash]
  def initialize(hash)
    super()
    @_namespace = :node
    @noun = "node"
    @dhcp_mac = nil
    @hw_id = []
    @attributes_hash = {}
    from_hash(hash)
  end

  def tags
    # Dynamically return tags for this node
    engine = ProjectHanlon::Engine.instance
    engine.node_tags(self)
  end

  # We override the to_hash to add the 'tags key/value for sharing node tags
  def to_hash
    hash = super
    hash['@tags'] = tags
    hash['@status'] = current_status
    hash
  end

  def uuid=(new_uuid)
    @uuid = new_uuid.upcase
  end

  def current_status
    # Dynamically return the current status for this node
    engine = ProjectHanlon::Engine.instance
    engine.node_status(self)
  end

  def print_header(additional_fields = nil)
    header_fields = ["UUID", "Last Checkin", "Status", "Tags"]
    additional_fields.each { |field|
      if field == 'hardware_id'
        header_fields << 'Hardware ID'
      else
        header_fields << field.split('_').map(&:capitalize).join(' ')
      end
    } if additional_fields
    header_fields
  end

  def print_items(additional_fields = nil)
    # filter out the hardware ID related tag (using the pattern for an SMBIOS UUID)
    # from the list of tags to display
    temp_tags = @tags.reject { |item| /[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}/.match(item) }
    temp_tags = ["n/a"] if temp_tags == [] || temp_tags == nil
    time_diff = Time.now.to_i - @timestamp.to_i
    status = "-"
    case @status
      when "rebind"
        status = "R"
      when "bound"
        status = "B"
      when "inactive"
        status = "I"
      when "active"
        status = "A"
      else
        status = "U"
    end
    return_vals = @uuid, pretty_time(time_diff), status, "[#{temp_tags.join(",")}]"
    additional_fields.each { |field|
      if field == 'hardware_id'
        val = "[#{@hw_id.join(",")}]"
      else
        val = @attributes_hash[field]
      end
      return_vals << (val ? val : 'N/A')
    } if additional_fields
    return_vals
  end

  def print_item_header
    return "UUID", "Last Checkin", "Status", "Tags", "Hardware ID"
  end

  def print_item
    # filter out the hardware ID related tag (using the pattern for an SMBIOS UUID)
    # from the list of tags to display
    temp_tags = @tags.reject { |item| /[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}/.match(item) }
    temp_tags = ["n/a"] if temp_tags == [] || temp_tags == nil
    return @uuid, Time.at(@timestamp.to_i).strftime("%m-%d-%y %H:%M:%S"), @status,
        "[#{temp_tags.join(",")}]", "[#{@hw_id.join(",")}]"
  end

  def line_color
    :white_on_black
  end

  def header_color
    :red_on_black
  end


  # Used to print our attributes_hash through slice printing
  # @return [Array]
  def print_attributes_hash
    # First see if we have the HashPrint class already defined
    begin
      self.class.const_get :HashPrint # This throws an error so we need to use begin/rescue to catch
    rescue
      # Define out HashPrint class for this object
      define_hash_print_class
    end
    # Create an array to store our HashPrint objects
    attr_array = []
    # Take each element in our attributes_hash and store as a HashPrint object in our array
    @attributes_hash.keys.sort.each do |k|
      v = @attributes_hash[k]
      # Skip any k/v where the v > 32 characters
      if v.to_s.length < 32
        # We use Name / Value as header and key/value as values for our object
        attr_array << self.class.const_get(:HashPrint).new(["\tName", "Value"], ["\t" + k.to_s, v.to_s], line_color, header_color)
      end
    end
    # Return our array of HashPrint
    attr_array
  end

  def print_hardware_ids
    # First see if we have the HashPrint class already defined
    begin
      self.class.const_get :HashPrint # This throws an error so we need to use begin/rescue to catch
    rescue
      # Define out HashPrint class for this object
      define_hash_print_class
    end
    # Create an array to store our HashPrint objects
    hw_id_array = []
    # Take each element in our attributes_hash and store as a HashPrint object in our array
    @hw_id.each do
    |id|
      hw_id_array << self.class.const_get(:HashPrint).new(["Hardware ID"], [id], line_color, header_color)
    end
    # Return our array of HashPrint
    hw_id_array
  end

  def pretty_time(in_time)
    float_time = in_time.to_f
    case
      when float_time < 60
        float_time.to_i.to_s + " sec"
      when float_time > 60
        ("%02.1f" % (float_time / 60)) + " min"
      else
        float_time.to_s + " sec"
    end
  end


end
