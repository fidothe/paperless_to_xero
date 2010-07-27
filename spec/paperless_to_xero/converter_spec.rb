require 'spec_helper'
require 'tempfile'

Spec::Matchers.define :have_detail_matching do |key, value|
  match do |object|
    object.send(key) == value
  end
  failure_message_for_should do |object|
    "Expected <#{object.class.name}>.#{key} to match '#{value}'. Instead, it was '#{object.send(key)}'"
  end
  failure_message_for_should_not do |object|
    "Expected <#{object.class.name}>.#{key} NOT to match '#{value}'"
  end
  description do
    "have detail #{key.inspect} matching '#{value}'"
  end
end

describe PaperlessToXero::Converter do
  before(:each) do
    @converter = PaperlessToXero::Converter.new('/input/path', '/output/path')
  end
  
  def fixture_path(name)
    File.expand_path(File.dirname(__FILE__) + "/../fixtures/#{name}.csv")
  end
  
  def verify_invoice_details(details)
    invoice = @converter.invoices.first
    invoice_details = details[:invoice]
    
    invoice_details.each do |key, value|
      invoice.should have_detail_matching(key, value)
    end
    
    invoice.should be_vat_inclusive     if details[:vat_inclusive]
    invoice.should_not be_vat_inclusive if details[:vat_exclusive]
    
    line_items_details = {:description => 'Phone case', :category => '429', :vat_inclusive_amount => '14.95', :vat_exclusive_amount => '13.00', :vat_amount => '1.95', :vat_type => '15% (VAT on expenses)'}
    line_items = invoice.items.dup
    if details[:line_items]
      details[:line_items].each do |line_item_details|
        line_item = line_items.shift
        line_item_details.each do |key, value|
          line_item.should have_detail_matching(key, value)
        end
      end
    end
  end
  
  describe "checking the header row" do
    it "should raise an UnknownHeaderRow error if it doesn't recognise the header..." do
      @converter.stubs(:input_path).returns(fixture_path('dodgy-header'))
      lambda { @converter.parse }.should raise_error(PaperlessToXero::UnknownHeaderRow)
    end
  end
  
  describe "single item inputs" do
    it "should able to create an invoice for a basic single-item invoice" do
      @converter.stubs(:input_path).returns(fixture_path('single-basic'))
      @converter.parse
      
      verify_invoice_details(
        :invoice => {:date => Date.parse('2009-05-18'), :merchant => 'Apple Store, Regent Street', 
                     :reference_id => '2009-05-18-05', :inc_vat_total => '14.95', :vat_total => '1.95', 
                     :ex_vat_total => '13.00', :currency => 'GBP'},
        :vat_inclusive => true,
        :line_items => [
          {:description => 'Phone case', :category => '429', :vat_type => '15% (VAT on expenses)',
           :vat_inclusive_amount => '14.95', :vat_exclusive_amount => '13.00', :vat_amount => '1.95'}
        ]
      )
    end
    
    it "should able to create an invoice for a single-item invoice with an amount over 1,000 (Paperless likes to add the commas)" do
      @converter.stubs(:input_path).returns(fixture_path('single-1000'))
      @converter.parse
      verify_invoice_details(
        :invoice => {:inc_vat_total => '2235.00'},
        :line_items => [
          {:vat_inclusive_amount => '2235.00'}
        ]
      )
    end
    
    it "should able to create an invoice for a zero-rated single-item invoice" do
      @converter.stubs(:input_path).returns(fixture_path('single-zero_rated'))
      @converter.parse
      
      verify_invoice_details(
        :invoice => {:merchant => 'Transport For London', :inc_vat_total => '20.00', :vat_total => '0.00', 
                     :ex_vat_total => '20.00'},
        :vat_inclusive => true,
        :line_items => [
          {:vat_type => 'Zero Rated Expenses', :vat_inclusive_amount => '20.00', :vat_exclusive_amount => '20.00', 
           :vat_amount => '0.00'}
        ]
      )
    end
    
    it "should able to create an invoice for a foreign currency single-item invoice" do
      @converter.stubs(:input_path).returns(fixture_path('single-foreign'))
      @converter.parse
      
      verify_invoice_details(
        :invoice => {:currency => 'EUR', :inc_vat_total => '250.00', :vat_total => '50.00', 
                     :ex_vat_total => '200.00'},
        :vat_inclusive => true,
        :line_items => [
          {:vat_type => '25% (Denmark, VAT on expenses)', :vat_inclusive_amount => '250.00', :vat_exclusive_amount => '200.00', 
           :vat_amount => '50.00'}
        ]
      )
    end
    
    it "should able to create an invoice for a foreign currency (not € or $) single-item invoice" do
      @converter.stubs(:input_path).returns(fixture_path('single-dkk'))
      @converter.parse
      
      verify_invoice_details(
        :invoice => {:merchant => 'Halvandet', :currency => 'DKK'},
        :vat_inclusive => true,
        :line_items => [
          {:vat_type => '25% (Denmark, VAT on expenses)', :vat_inclusive_amount => '73.00', :vat_exclusive_amount => '58.40', 
           :vat_amount => '14.60'}
        ]
      )
    end
    
    it "should cope with a single item invoice with no VAT" do
      @converter.stubs(:input_path).returns(fixture_path('single-no-vat'))
      @converter.parse
      
      verify_invoice_details(
        :invoice => {:inc_vat_total => '4.50', :vat_total => '0.00', :ex_vat_total => '4.50'},
        :vat_inclusive => true,
        :line_items => [
          {:vat_type => 'No VAT', :vat_inclusive_amount => '4.50', :vat_exclusive_amount => '4.50', 
           :vat_amount => nil}
        ]
      )
    end
    
    describe "UK VAT rate changes" do
      describe "pre 2008-12 17.5% VAT" do
        it "correctly handles days in that VAT rate" do
          @converter.stubs(:input_path).returns(fixture_path('single-vat-pre-2008-12'))
          @converter.parse
          
          verify_invoice_details(
            :invoice => {:date => Date.parse('2008-05-18'), :merchant => 'Apple Store, Regent Street', 
                         :reference_id => '2008-05-18-05', :inc_vat_total => '117.50', :vat_total => '17.50', 
                         :ex_vat_total => '100.00', :currency => 'GBP'},
            :vat_inclusive => true,
            :line_items => [
              {:description => 'Phone case', :category => '429', :vat_type => '17.5% (VAT on expenses)',
               :vat_inclusive_amount => '117.50', :vat_exclusive_amount => '100.00', :vat_amount => '17.50'}
            ]
          )
        end
        
        it "correctly handles the last day of that VAT rate" do
          @converter.stubs(:input_path).returns(fixture_path('single-vat-2008-11-30'))
          @converter.parse
          
          verify_invoice_details(
            :invoice => {:date => Date.parse('2008-11-30'), :merchant => 'Apple Store, Regent Street', 
                         :reference_id => '2008-11-30-05', :inc_vat_total => '117.50', :vat_total => '17.50', 
                         :ex_vat_total => '100.00', :currency => 'GBP'},
            :vat_inclusive => true,
            :line_items => [
              {:description => 'Phone case', :category => '429', :vat_type => '17.5% (VAT on expenses)',
               :vat_inclusive_amount => '117.50', :vat_exclusive_amount => '100.00', :vat_amount => '17.50'}
            ]
          )
        end
      end
      
      describe "2009's 15% VAT rate" do
        it "correctly handles the first day of that VAT rate" do
          @converter.stubs(:input_path).returns(fixture_path('single-vat-2008-12-01'))
          @converter.parse
          
          verify_invoice_details(
            :invoice => {:date => Date.parse('2008-12-01'), :merchant => 'Apple Store, Regent Street', 
                         :reference_id => '2008-12-01-05', :inc_vat_total => '115.00', :vat_total => '15.00', 
                         :ex_vat_total => '100.00', :currency => 'GBP'},
            :vat_inclusive => true,
            :line_items => [
              {:description => 'Phone case', :category => '429', :vat_type => '15% (VAT on expenses)',
               :vat_inclusive_amount => '115.00', :vat_exclusive_amount => '100.00', :vat_amount => '15.00'}
            ]
          )
        end
        
        it "correctly handles days in that VAT rate" do
          @converter.stubs(:input_path).returns(fixture_path('single-vat-2009'))
          @converter.parse
          
          verify_invoice_details(
            :invoice => {:date => Date.parse('2009-06-01'), :merchant => 'Apple Store, Regent Street', 
                         :reference_id => '2009-06-01-05', :inc_vat_total => '115.00', :vat_total => '15.00', 
                         :ex_vat_total => '100.00', :currency => 'GBP'},
            :vat_inclusive => true,
            :line_items => [
              {:description => 'Phone case', :category => '429', :vat_type => '15% (VAT on expenses)',
               :vat_inclusive_amount => '115.00', :vat_exclusive_amount => '100.00', :vat_amount => '15.00'}
            ]
          )
        end
        
        it "correctly handles the last day of that VAT rate" do
          @converter.stubs(:input_path).returns(fixture_path('single-vat-2009-12-31'))
          @converter.parse
          
          verify_invoice_details(
            :invoice => {:date => Date.parse('2009-12-31'), :merchant => 'Apple Store, Regent Street', 
                         :reference_id => '2009-12-31-05', :inc_vat_total => '115.00', :vat_total => '15.00', 
                         :ex_vat_total => '100.00', :currency => 'GBP'},
            :vat_inclusive => true,
            :line_items => [
              {:description => 'Phone case', :category => '429', :vat_type => '15% (VAT on expenses)',
               :vat_inclusive_amount => '115.00', :vat_exclusive_amount => '100.00', :vat_amount => '15.00'}
            ]
          )
        end
      end
      
      describe "2010-01-01's return to 17.5% VAT" do
        it "correctly handles the first day of that VAT rate" do
          @converter.stubs(:input_path).returns(fixture_path('single-vat-2010-01-01'))
          @converter.parse
          
          verify_invoice_details(
            :invoice => {:date => Date.parse('2010-01-01'), :merchant => 'Apple Store, Regent Street', 
                         :reference_id => '2010-01-01-05', :inc_vat_total => '117.50', :vat_total => '17.50', 
                         :ex_vat_total => '100.00', :currency => 'GBP'},
            :vat_inclusive => true,
            :line_items => [
              {:description => 'Phone case', :category => '429', :vat_type => '17.5% (VAT on expenses)',
               :vat_inclusive_amount => '117.50', :vat_exclusive_amount => '100.00', :vat_amount => '17.50'}
            ]
          )
        end
      end
    end
    
    describe "handling Pingdom's USD invoices with Swedish 25%" do
      it "correctly applies both currency and VAT" do
        @converter.stubs(:input_path).returns(fixture_path('dollars_with_swedish_vat'))
        @converter.parse
        
        verify_invoice_details(
          :invoice => {:date => Date.parse('2010-06-06'), :merchant => 'Pingdom', 
                       :reference_id => '2010-06-06-01', :inc_vat_total => '149.25', :vat_total => '29.95', 
                       :ex_vat_total => '119.30', :currency => 'USD'},
          :vat_inclusive => true,
          :line_items => [
            {:description => 'Pingdom site monitoring subscription', :category => '429', :vat_type => '25% (Sweden, VAT on expenses)',
             :vat_inclusive_amount => '149.25', :vat_exclusive_amount => '119.30', :vat_amount => '29.95'}
          ]
        )
      end
    end
  end
  
  describe "multi-item inputs" do
    it "should able to create an Invoice for a basic multi-item invoice" do
      @converter.stubs(:input_path).returns(fixture_path('multi-item'))
      @converter.parse
      
      verify_invoice_details(
        :invoice => {:date => Date.parse('2009-05-18'), :merchant => 'Apple Store, Regent Street', 
                     :reference_id => '2009-05-18-09', :inc_vat_total => '617.95', :vat_total => '80.60', 
                     :ex_vat_total => '537.35', :currency => 'GBP'},
        :vat_inclusive => true,
        :line_items => [
          {:description => 'Mac Mini', :category => '720', :vat_type => '15% (VAT on expenses)',
           :vat_inclusive_amount => '499.00', :vat_exclusive_amount => '433.91', :vat_amount => '65.09'},
          {:description => 'iWork 09', :category => '463', :vat_type => '15% (VAT on expenses)',
           :vat_inclusive_amount => '70.00', :vat_exclusive_amount => '60.87', :vat_amount => '9.13'},
          {:description => 'VMWare Fusion', :category => '463', :vat_type => '15% (VAT on expenses)',
           :vat_inclusive_amount => '48.95', :vat_exclusive_amount => '42.57', :vat_amount => '6.38'}
        ]
      )
    end
    
    it "should able to create an Invoice for a foreign currency multi-item invoice" do
      @converter.stubs(:input_path).returns(fixture_path('multi-foreign'))
      @converter.parse
      
      verify_invoice_details(
        :invoice => {:currency => 'EUR', :inc_vat_total => '2.80', :vat_total => '0.33', 
                     :ex_vat_total => '2.47'},
        :vat_inclusive => true,
        :line_items => [
          {:description => 'Coffee', :vat_type => '19% (Germany, VAT on expenses)', 
           :vat_inclusive_amount => '1.50', :vat_amount => '0.24'},
          {:description => 'Food', :vat_type => '7% (Germany, VAT on expenses)', 
           :vat_inclusive_amount => '1.30', :vat_amount => '0.09'}
        ]
      )
    end
    
    it "should cope with a VAT-exclusive invoice" do
      @converter.stubs(:input_path).returns(fixture_path('multi-ex-vat'))
      @converter.parse
      
      verify_invoice_details(
        :invoice => {:date => Date.parse('2009-05-18'), :merchant => 'Apple Store, Regent Street', 
                     :reference_id => '2009-05-18-09', :inc_vat_total => '617.95', :vat_total => '80.60', 
                     :ex_vat_total => '537.35', :currency => 'GBP'},
        :vat_inclusive => false,
        :line_items => [
          {:description => 'Mac Mini', :category => '720', :vat_type => '15% (VAT on expenses)',
           :vat_inclusive_amount => '499.00', :vat_exclusive_amount => '433.91', :vat_amount => '65.09'},
          {:description => 'iWork 09', :category => '463', :vat_type => '15% (VAT on expenses)',
           :vat_inclusive_amount => '70.00', :vat_exclusive_amount => '60.87', :vat_amount => '9.13'},
          {:description => 'VMWare Fusion', :category => '463', :vat_type => '15% (VAT on expenses)',
           :vat_inclusive_amount => '48.95', :vat_exclusive_amount => '42.57', :vat_amount => '6.38'}
        ]
      )
    end
    
    it "should be able to cope with an multi-line invoice with mixed VAT and VAT-exempt lines" do
      @converter.stubs(:input_path).returns(fixture_path('multi-item-mixed_vat_and_exempt'))
      @converter.parse
      
      verify_invoice_details(
        :invoice => {:date => Date.parse('2009-07-23'), :merchant => 'Post Office', 
                     :reference_id => '2009-07-23-03', :inc_vat_total => '3.55', :vat_total => '0.29', 
                     :ex_vat_total => '3.26', :currency => 'GBP'},
        :vat_inclusive => false,
        :line_items => [
          {:description => 'Envelopes', :category => '429', :vat_type => '15% (VAT on expenses)',
           :vat_inclusive_amount => '2.19', :vat_exclusive_amount => '1.90', :vat_amount => '0.29'},
          {:description => 'Postage', :category => '425', :vat_type => 'Zero Rated Expenses',
           :vat_inclusive_amount => '1.36', :vat_exclusive_amount => '1.36', :vat_amount => '0.00'}
        ]
      )
    end
  end
  
  describe "end-to-end" do
    before(:each) do
      @tempfile_path = Tempfile.new(['output', 'csv']).path
    end
    
    it "should produce exactly the output we expect" do
      converter = PaperlessToXero::Converter.new(fixture_path('end_to_end-input'), @tempfile_path)
      converter.convert!
      
      expected = File.readlines(fixture_path('end_to_end-output'))
      actual = File.readlines(@tempfile_path)
      
      (0..expected.size).each do |i|
        actual[i].should == expected[i]
      end
    end
    
    after(:each) do
      File.unlink(@tempfile_path)
    end
  end
end