require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

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
      
      PaperlessToXero::Invoice.expects(:new).with('18/05/2009', 'Apple Store, Regent Street', '2009-05-18-05', 'GBP').returns(mock_invoice)
      mock_invoice.expects(:add_item).with('Phone case', '14.95', '429', 'VAT - 15%', true)
      
      @converter.parse
    end
    
    it "should able to create an invoice for a foreign currency single-item invoice" do
      @converter.stubs(:input_path).returns(fixture_path('single-foreign'))
      mock_invoice = mock()
      
      PaperlessToXero::Invoice.expects(:new).with('29/05/2009', 'FDIH', '2009-05-29-02', 'EUR').returns(mock_invoice)
      mock_invoice.expects(:add_item).with('Reboot 11 ticket', '250.00', '480', 'VAT - Denmark - 25%', true)
      
      @converter.parse
    end
  end
  
  describe "multi-item inputs" do
    it "should able to create an Invoice for a basic multi-item invoice" do
      @converter.stubs(:input_path).returns(fixture_path('multi-item'))
      mock_invoice = mock()
      
      PaperlessToXero::Invoice.expects(:new).with('18/05/2009', 'Apple Store, Regent Street', '2009-05-18-09', 'GBP').returns(mock_invoice)
      mock_invoice.expects(:add_item).with('iWork 09', '70.00', '463', 'VAT - 15%', true)
      mock_invoice.expects(:add_item).with('VMWare Fusion', '48.95', '463', 'VAT - 15%', true)
      mock_invoice.expects(:add_item).with('Mac Mini', '499.00', '720', 'VAT - 15%', true)
      
      @converter.parse
    end
    
    it "should able to create an Invoice for a foreign currency multi-item invoice" do
      @converter.stubs(:input_path).returns(fixture_path('multi-foreign'))
      mock_invoice = mock()
      
      PaperlessToXero::Invoice.expects(:new).with('22/06/2009', 'Geberer', '2009-06-22-02', 'EUR').returns(mock_invoice)
      mock_invoice.expects(:add_item).with('Coffee', '1.50', '494', 'VAT - Germany - 19%', true)
      mock_invoice.expects(:add_item).with('Food', '1.30', '494', 'VAT - Germany - 7%', true)
      
      @converter.parse
    end
  end
end