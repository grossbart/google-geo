require 'test/unit'
$:.unshift "#{File.dirname __FILE__}/../vendor/mocha-0.4.0/lib"
require 'mocha'
require "#{File.dirname __FILE__}/../lib/google/geo"

class Google::GeoTest < Test::Unit::TestCase  
  def setup    
   @geo = Google::Geo.new 'API_KEY'
  end
    
  def test_streetview_should_not_be_nil
     @geo.expects(:open).
       with("http://maps.google.com/cbk?output=xml&oe=utf-8&cb_client=api&ll=34.154961,-118.25514&callback=_xdc_._0fqdyf9p2").
       returns(response(:streetview_success))
    
    street = @geo.street_view_locate({:lat => 34.154961, :lon => -118.25514})
    assert_not_nil street
  end
  
  def test_should_have_html_embed_tag
    @geo.expects(:open).
     with("http://maps.google.com/cbk?output=xml&oe=utf-8&cb_client=api&ll=34.154961,-118.25514&callback=_xdc_._0fqdyf9p2").
     returns(response(:streetview_success))
    
    street = @geo.street_view_locate({:lat => 34.154961, :lon => -118.25514})
    assert_not_nil street.scan(/\<embed.*\>.*\<\/embed\>/)
    assert_not_nil street.scan(/panoId=([a-zA-Z0-9\-_]+)/)
  end
  
  def test_reverse_location_should_have_streetview
    @geo.expects(:open).
     with("http://maps.google.com/maps/geo?ll=34.154961,-118.25514&key=API_KEY&output=xml&hl=en&oe=utf-8").
     returns(response(:reverse_locate_success))
    
    location = @geo.reverse_locate(:lat => 34.154961, :lon => -118.25514).first
  
    Google::Geo.any_instance.expects(:open).
     with("http://maps.google.com/cbk?output=xml&oe=utf-8&cb_client=api&ll=33.9986972,-118.0760384&callback=_xdc_._0fqdyf9p2").
     returns(response(:streetview_success)).at_most(3)
     
    assert_not_nil location.street_view
    assert_not_nil location.street_view.scan(/\<embed.*\>.*\<\/embed\>/)
    assert_not_nil location.street_view.scan(/panoId=([a-zA-Z0-9\-_]+)/)
  end
  
  def test_locate_should_have_streetview
    @geo.expects(:open).
      with("http://maps.google.com/maps/geo?q=1600%20Amphitheatre%20Parkway,%20Mountain%20View,%20CA&key=API_KEY&output=xml&hl=en&oe=utf-8").
      returns(response(:success))
  
    query = '1600 Amphitheatre Parkway, Mountain View, CA'
    address = @geo.locate(query).first
    
    Google::Geo.any_instance.expects(:open).
     with("http://maps.google.com/cbk?output=xml&oe=utf-8&cb_client=api&ll=37.423021,-122.083739&callback=_xdc_._0fqdyf9p2").
     returns(response(:streetview_success)).at_most(3)
         
    assert_not_nil address.street_view
    assert_not_nil address.street_view.scan(/\<embed.*\>.*\<\/embed\>/)
    assert_not_nil address.street_view.scan(/panoId=([a-zA-Z0-9\-_]+)/)
  end
  
private
  def response(filename)
    File.new "#{File.dirname __FILE__}/fixtures/#{filename}.xml"
  end
end