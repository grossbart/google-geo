require 'open-uri'

module Google
# Please see README for usage examples.
class  Geo    
  # API key provided by Google allowing access to the Geocode API
  attr_accessor :key, :language

  # Google's XML files state that they are utf-8 encoded which is not true.
  # Because they state this explicitly, I see no need to let users set
  # another charset.
  attr_reader :charset
  
  def initialize(key)
    @key = key
    @language = 'en'
    @charset = 'utf-8'
  end
  
  # Returns an array of Address objects, each with accessors for all the components of a location. 
  # The query argument should be a string.
  def locate(query)
    xml = open(uri(query)).read
    res = Response.new(xml, key)
    
    res.placemarks.map { |place| Address.new place, res.query }
  end
  
  # Returns an array of Address objects, each with accessors for all components of a location.
  def reverse_locate(ll={})
    if ll.has_key?(:lat) && ll.has_key?(:lon)
      latlon = "#{ll[:lat]},#{ll[:lon]}"
    else
      raise ArgumentError, "Missing keys for latitude, longitude"
    end  
    xml = open(uri(:ll => latlon)).read
    res = Response.new(xml, key)
    res.placemarks.map{|place| Address.new(place, res.query) }
  end
  
  def street_view_locate(ll={})
    if ll.has_key?(:lat) && ll.has_key?(:lon)
     locurl = "http://maps.google.com/cbk?output=xml&oe=utf-8&cb_client=api"
     locurl += "&ll=#{ll[:lat]},#{ll[:lon]}&callback=_xdc_._0fqdyf9p2"
    else
     raise ArgumentError, "Missing Keys for latitude, longitude"
    end
    xml_response = open(locurl).read
    pano_id = xml_response.scan(/pano_id="([a-zA-Z0-9\-_]+)"/).flatten.first
    html_street_view(pano_id)
  end
  
  def html_street_view(pano_id, width=500, height=300)
    html_embed = %Q{<embed src="http://maps.google.com/mapfiles/cb/googlepano.066.swf"} 
    html_embed += %Q{quality="high" bgcolor="#000000" style="width: #{width}px; height: #{height}px;}
    html_embed += %Q{ position: relative;" wmode="opaque" swliveconnect="false" id="panoflash1"}
    html_embed += %Q{ allowscriptaccess="always" type="application/x-shockwave-flash" }
    html_embed += %Q{pluginspage="http://www.macromedia.com/go/getflashplayer" scale="noscale" salign="lt" }
    html_embed += %Q{flashvars="panoId=#{pano_id}}
    html_embed += %Q{&amp;directionMap=N:N,W:W,S:S,E:E,NW:NW,NE:NE,SW:SW,SE:SE&amp;yaw=0}
    html_embed += %Q{&amp;zoom=0&amp;browser=3&amp;pitch=5&amp;viewerId=1&amp;context=api&amp;}
    html_embed += %Q{animateOnLoad=false&amp;useSsl=false" align="middle"></embed>}
    html_embed
  end
  
  # Generate a request URI from a given search string.
  def uri(address) #:nodoc:
    if address.kind_of?(String)
      qstr = "q=#{URI.escape(address)}"
    elsif address.kind_of?(Hash)
      qstr = address.map{|k,v| "#{k.to_s}=#{URI.escape(v)}" }.flatten.join("&")
    end
    "http://maps.google.com/maps/geo?#{qstr}&key=#{key}&output=xml&hl=#{language}&oe=#{charset}"
  end
  private :uri
  
  ###
  
  module Parser #:nodoc:
    # Fetch contents of an XML element of the response.
    def fetch(element) #:nodoc:
      @xml.slice %r{<#{element}>(.+?)</#{element}>}, 1
    end
    
    # Like fetch, but for the only piece of data locked away in an attribute.
    def fetch_accuracy #:nodoc:
      @xml.slice(%r{Accuracy="([^"]+)">}, 1).to_i
    end
  end
  
  ###
  
  # Represents locations returned in response to geocoding queries.
  class Address
    include Parser
    
    attr_reader :street
    alias :thoroughfare :street
    
    attr_reader :city
    alias :locality :city
    
    attr_reader :zip
    alias :postal_code :zip
    
    attr_reader :county
    alias :subadministrative_area :county
    
    attr_reader :state
    alias :administrative_area :state
    
    attr_reader :country
    alias :country_code :country
    
    # An array containing the standard three elements of a coordinate triple: latitude, longitude, elevation.
    attr_reader :coordinates
    
    # A float, the standard first element of a coordinate triple.
    attr_reader :longitude
    alias :lng :longitude
    
    # A float, the standard second element of a coordinate triple.
    attr_reader :latitude
    alias :lat :latitude
    
    # A float, the standard third element of a coordinate triple.
    attr_reader :elevation
    
    # An integer, Google's rating of the accuracy of the supplied address.
    attr_reader :accuracy
    
    # All address attributes as one string, formatted by the service.
    attr_reader :full_address
    alias :to_s :full_address
    
    # The address query sent to the service. i.e. The user input.
    attr_reader :query
    
    def initialize(placemark, query) #:nodoc
      @xml   = placemark
      @query = query

      {
        :@street       => :ThoroughfareName,
        :@city         => :LocalityName,
        :@zip          => :PostalCodeNumber,
        :@county       => :SubAdministrativeAreaName,
        :@state        => :AdministrativeAreaName,
        :@country      => :CountryNameCode,
        
        :@full_address => :address
      }.each do |attribute, element|
        instance_variable_set(attribute, (fetch(element) rescue nil))
      end
      
      @longitude, @latitude, @elevation = @coordinates = fetch(:coordinates).split(',').map { |x| x.to_f }
      
      @accuracy = fetch_accuracy
    end
    
    def street_view
      geo = Google::Geo.new('key')
      geo.street_view_locate(:lat => @latitude, :lon => @longitude)
    end
  end
  
  ###
  
  class Response #:nodoc:
    include Parser
    
    attr_reader :query, :status, :placemarks
    
    def initialize(xml, geo_key) #:nodoc
      @xml, @geo_key = xml, geo_key
      
      @query  = fetch(:name)
      @status = fetch(:code).to_i
      
      check_for_errors
      
      @placemarks = @xml.scan %r{<Placemark(?: id="p\d+")?>.+?</Placemark>}m
    end
    
    def check_for_errors #:nodoc:
      case status
        when 200 then # Success
        when 500 then raise ServerError, "Unknown error from Google's server"
        when 601 then raise MissingAddressError, "Missing address"
        when 602 then raise UnknownAddressError, "Unknown address: #{@query}"
        when 603 then raise UnavailableAddressError, "Unavailable address: #{@query}"
        when 610 then raise InvalidMapKeyError, "Invalid map key: #{@geo_key}"
        when 620 then raise TooManyQueriesError, "Too many queries for map key: #{@geo_key}"
        else          raise UnknownError, "Unknown error: #{@status}"
      end
    end
  end
  
  ###    
  
  class Error < Exception; end
    
  class ServerError  < Error; end
    
  class AddressError < Error; end
  class MissingAddressError     < AddressError; end
  class UnknownAddressError     < AddressError; end
  class UnavailableAddressError < AddressError; end
    
  class MapKeyError < Error; end
  class InvalidMapKeyError  < MapKeyError; end
  class TooManyQueriesError < MapKeyError; end
  
  class UnknownError < Error; end
end

end