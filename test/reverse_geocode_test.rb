require 'test/unit'
$:.unshift "#{File.dirname __FILE__}/../vendor/mocha-0.4.0/lib"
require 'mocha'
require "#{File.dirname __FILE__}/../lib/google/geo"

class Google::GeoTest < Test::Unit::TestCase  
  def setup    
   @geo = Google::Geo.new 'API_KEY'
  end
    
  def test_should_reverse_geocode_with_latlon
     @geo.expects(:open).
       with("http://maps.google.com/maps/geo?ll=33.998671,-118.075926&key=API_KEY&output=xml").
       returns(response(:reverse_geocode_success))
    
    location = @geo.reverse_geocode({:lat => 33.998671, :lon => -118.075926})
    address = location.first
    
    assert_equal 33.9986972, address.latitude
    assert_equal -118.0760384, address.longitude
    
    assert_equal address.longitude, address.lng
    assert_equal address.latitude, address.lat
  end
  
  def test_should_have_city
    @geo.expects(:open).returns(response(:reverse_geocode_success))
    location = @geo.reverse_geocode(:lat => 33.998671, :lon => -118.075926)
    address = location.first
    assert_equal "Pico Rivera", address.city
  end  
  
  def test_should_have_two_letter_state
    @geo.expects(:open).returns(response(:reverse_geocode_success))
    location = @geo.reverse_geocode(:lat => 33.998671, :lon => -118.075926)
    address = location.first
    assert_equal "CA", address.state
  end
  
  def test_should_have_zipcode
    @geo.expects(:open).returns(response(:reverse_geocode_success))
    location = @geo.reverse_geocode(:lat => 33.998671, :lon => -118.075926)
    address = location.first
    assert_equal "90660", address.zip
  end
  
  def test_should_have_country
    @geo.expects(:open).returns(response(:reverse_geocode_success))
    location = @geo.reverse_geocode(:lat => 33.998671, :lon => -118.075926)
    address = location.first
    assert_equal "US", address.country    
  end
  
  def test_should_have_full_address
    @geo.expects(:open).returns(response(:reverse_geocode_success))
    location = @geo.reverse_geocode(:lat => 33.998671, :lon => -118.075926)
    address = location.first
    assert_equal "4952-4958 Tobias Ave, Pico Rivera, CA 90660, USA", address.full_address
  end
  
  def test_should_handle_missing_keys
    @geo.expects(:open).returns(response(:reverse_geocode_success)).at_least(0)
    assert_raise ArgumentError do
      @geo.reverse_geocode(:la => 33.998671, :lo => -118.075926)
    end
  end
  
  def test_should_raise_error_when_unknown_address
    @geo.expects(:open).returns(response(:reverse_geocode_602))
    assert_raise Google::Geo::UnknownAddressError do
      @geo.reverse_geocode(:lat => 0, :lon => 0)
    end
  end
  
private
  def response(filename)
    File.new "#{File.dirname __FILE__}/fixtures/#{filename}.xml"
  end
end