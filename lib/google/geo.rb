require 'open-uri'

module Google

# = Google::Geo
# 
# A simple, elegant library for getting geocoding information from Google Maps. Very much inspired by the google-geocode gem, but completely dependency free!
# 
# == Examples
# 
#   geo = Google::Geo.new API_KEY
# 
#   addresses = geo.locate '1600 Amphitheatre Parkway, Mountain View, CA'
#   
#   addresses.size # 1, :locate always returns an Array
#   
#   address = addresses.first
# 
#   address.country      # 'US'
#   address.city         # 'Mountain View'
#   address.full_address # '1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA'
# 
#   address.query        # '1600 Amphitheatre Parkway, Mountain View, CA'
#   address.accuracy     # 8
# 
# In the case of sufficiently vague queries, Google will return more than one address:
# 
#   addresses = geo.locate 'heaven'
# 
#   addresses.size                  # 2
#   addresses.map { |a| a.state } # ['PA', 'NC']
# 
# == Contributors
# 
# Seth Thomas Rasmussen - http://greatseth.com - sethrasmussen@gmail.com
class  Geo    
  # API key provided by Google allowing access to the Geocode API
  attr_accessor :key
  
  def initialize(key)
    @key = key
  end
  
  # Returns an array of Address objects, each with accessors for all the components of a location. 
  # The query argument should be a string.
  def locate(query)
    xml = open(uri(query)).read
    res = Response.new(xml, key)
    
    res.placemarks.map { |place| Address.new place, res.query }
  end
  
  # Generate a request URI from a given search string.
  def uri(address) #:nodoc:
    "http://maps.google.com/maps/geo?q=#{URI.escape address}&key=#{key}&output=xml"
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