require 'test/unit'
$:.unshift "#{File.dirname __FILE__}/../vendor/mocha-0.4.0/lib"
require 'mocha'
require "#{File.dirname __FILE__}/../lib/google/geo"

class Google::GeoTest < Test::Unit::TestCase  
  def setup    
    @geo = Google::Geo.new 'API_KEY'
  end

  def test_success
    @geo.expects(:open).
         # show that query is escaped
         with("http://maps.google.com/maps/geo?q=1600%20Amphitheatre%20Parkway,%20Mountain%20View,%20CA&key=API_KEY&output=xml").
         returns(response(:success))
    
    query = '1600 Amphitheatre Parkway, Mountain View, CA'
    
    address = @geo.locate(query).first
    
    assert_equal '1600 Amphitheatre Pkwy', address.street
    assert_equal address.street, address.thoroughfare
    
    assert_equal 'Mountain View', address.city
    assert_equal address.city, address.locality
    
    assert_equal '94043', address.zip
    assert_equal address.zip, address.postal_code
    
    assert_equal 'Santa Clara', address.county
    assert_equal address.county, address.subadministrative_area
    
    assert_equal 'CA', address.state
    assert_equal address.state, address.administrative_area
    
    assert_equal 'US', address.country
    assert_equal address.country, address.country_code
    
    assert_equal -122.083739, address.longitude
    assert_equal address.longitude, address.lng
    
    assert_equal 37.423021, address.latitude
    assert_equal address.latitude, address.lat
    
    assert_equal 0, address.elevation
    
    assert_equal [address.longitude, address.latitude, address.elevation], address.coordinates
    
    assert_equal 8, address.accuracy
    
    assert_equal '1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA', address.full_address
    assert_equal query, address.query
  end
  
  def test_success_with_multiple_addresses
    @geo.expects(:open).returns(response(:success_with_multiple_addresses))
    
    heavens = @geo.locate('heaven')
    
    assert_equal 2, heavens.size
    
    assert_equal 'Heaven, Pottsville, PA 17901, USA', heavens[0].full_address
    assert_equal 'Heaven, Oakboro, NC 28129, USA', heavens[1].full_address
    
    heavens.each { |h| assert_kind_of Google::Geo::Address, h }
  end

  def test_invalid_map_key
    @geo.expects(:open).returns(response(:invalid_map_key))
    assert_raises(Google::Geo::InvalidMapKeyError) { @geo.locate 'foo' }
  end

  def test_missing_address
    @geo.expects(:open).returns(response(:missing_address))
    assert_raises(Google::Geo::MissingAddressError) { @geo.locate 'foo' }
  end

  def test_server_error
    @geo.expects(:open).returns(response(:server_error))
    assert_raises(Google::Geo::ServerError) { @geo.locate 'foo' }
  end

  def test_too_many_queries
    @geo.expects(:open).returns(response(:too_many_queries))    
    assert_raises(Google::Geo::TooManyQueriesError) { @geo.locate 'foo' }
  end

  def test_unavailable_address
    @geo.expects(:open).returns(response(:unavailable_address))
    assert_raises(Google::Geo::UnavailableAddressError) { @geo.locate 'foo' }
  end

  def test_unknown_address
    @geo.expects(:open).returns(response(:unknown_address))
    assert_raises(Google::Geo::UnknownAddressError) { @geo.locate 'foo' }
  end
  
private
  def response(filename)
    File.new "#{File.dirname __FILE__}/fixtures/#{filename}.xml"
  end
end