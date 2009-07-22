require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'tempfile'

describe PaperlessToXero::Converter do
  before(:each) do
    @converter = PaperlessToXero::Converter.new('/input/path', '/output/path')
  end
  
  def fixture_path(name)
    File.expand_path(File.dirname(__FILE__) + "/../fixtures/#{name}.csv")
  end
  
  describe "single item inputs" do
    it "should able to create an invoice for a basic single-item invoice" do
      @converter.stubs(:input_path).returns(fixture_path('single-basic'))
      mock_invoice = mock()
      
      PaperlessToXero::Invoice.expects(:new).with(Date.parse('2009-05-18'), 'Apple Store, Regent Street', '2009-05-18-05', '14.95', '1.95', true, 'GBP').returns(mock_invoice)
      mock_invoice.expects(:add_item).with('Phone case', '14.95', '1.95', '429', 'VAT - 15%')
      
      @converter.parse
    end
    
    it "should able to create an invoice for a single-item invoice with an amount over 1,000 (Paperless likes to add the commas)" do
      @converter.stubs(:input_path).returns(fixture_path('single-1000'))
      mock_invoice = mock()
      
      PaperlessToXero::Invoice.expects(:new).with(Date.parse('2009-05-31'), 'Bertrams Hotel Guldsmeden', '2009-05-31-02', '2235.00', '447.00', true, 'GBP').returns(mock_invoice)
      mock_invoice.expects(:add_item).with('Reboot hotel booking', '2235.00', '447.00', '494', 'VAT - Denmark - 25%')
      
      @converter.parse
    end
    
    it "should able to create an invoice for a zero-rated single-item invoice" do
      @converter.stubs(:input_path).returns(fixture_path('single-zero_rated'))
      mock_invoice = mock()
      
      PaperlessToXero::Invoice.expects(:new).with(Date.parse('2009-03-10'), 'Transport For London', '2009-03-10-06', '20.00', '0.00', true, 'GBP').returns(mock_invoice)
      mock_invoice.expects(:add_item).with('Oyster card auto top-up', '20.00', '0.00', '493', 'VAT - 0%')
      
      @converter.parse
    end
    
    it "should able to create an invoice for a foreign currency single-item invoice" do
      @converter.stubs(:input_path).returns(fixture_path('single-foreign'))
      mock_invoice = mock()
      
      PaperlessToXero::Invoice.expects(:new).with(Date.parse('2009-05-29'), 'FDIH', '2009-05-29-02', '250.00', '50.00', true, 'EUR').returns(mock_invoice)
      mock_invoice.expects(:add_item).with('Reboot 11 ticket', '250.00', '50.00', '480', 'VAT - Denmark - 25%')
      
      @converter.parse
    end
    
    it "should able to create an invoice for a foreign currency (not € or $) single-item invoice" do
      @converter.stubs(:input_path).returns(fixture_path('single-dkk'))
      mock_invoice = mock()
      
      PaperlessToXero::Invoice.expects(:new).with(Date.parse('2009-06-24'), 'Halvandet', '2009-06-24-03', '73.00', '14.60', true, 'DKK').returns(mock_invoice)
      mock_invoice.expects(:add_item).with('Food & drink', '73.00', '14.60', '494', 'VAT - Denmark - 25%')
      
      @converter.parse
    end
    
    it "should cope with a VAT-exclusive invoice" do
      @converter.stubs(:input_path).returns(fixture_path('single-ex-vat'))
      mock_invoice = mock()
      
      PaperlessToXero::Invoice.expects(:new).with(Date.parse('2009-06-24'), 'Halvandet', '2009-06-24-03', '73.00', '14.60', false, 'DKK').returns(mock_invoice)
      mock_invoice.expects(:add_item).with('Food & drink', '73.00', '14.60', '494', 'VAT - Denmark - 25%')
      
      @converter.parse
    end
  end
  
  describe "multi-item inputs" do
    it "should able to create an Invoice for a basic multi-item invoice" do
      @converter.stubs(:input_path).returns(fixture_path('multi-item'))
      mock_invoice = mock()
      
      PaperlessToXero::Invoice.expects(:new).with(Date.parse('2009-05-18'), 'Apple Store, Regent Street', '2009-05-18-09', '617.95', '80.60', true, 'GBP').returns(mock_invoice)
      mock_invoice.expects(:add_item).with('iWork 09', '70.00', '9.13', '463', 'VAT - 15%')
      mock_invoice.expects(:add_item).with('VMWare Fusion', '48.95', '6.38', '463', 'VAT - 15%')
      mock_invoice.expects(:add_item).with('Mac Mini', '499.00', '65.09', '720', 'VAT - 15%')
      
      @converter.parse
    end
    
    it "should able to create an Invoice for a foreign currency multi-item invoice" do
      @converter.stubs(:input_path).returns(fixture_path('multi-foreign'))
      mock_invoice = mock()
      
      PaperlessToXero::Invoice.expects(:new).with(Date.parse('2009-06-22'), 'Geberer', '2009-06-22-02', '2.80', '0.33', true, 'EUR').returns(mock_invoice)
      mock_invoice.expects(:add_item).with('Coffee', '1.50', '0.24', '494', 'VAT - Germany - 19%')
      mock_invoice.expects(:add_item).with('Food', '1.30', '0.09','494', 'VAT - Germany - 7%')
      
      @converter.parse
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