require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PaperlessToXero::Invoice do
  describe "the creation basics" do
    it "should be able to be instantiated" do
      PaperlessToXero::Invoice.new(Date.parse("2009-07-20"), 'Merchant', 'reference UID', '23.00', '3.00', true, 'GBP').
        should be_instance_of(PaperlessToXero::Invoice)
    end
  end
  
  describe "instances" do
    describe "basics" do
      before(:each) do
        @invoice = PaperlessToXero::Invoice.new(Date.parse("2009-07-20"), 'Merchant', 'reference UID', '23.00', '3.00', true, 'GBP')
      end
      
      it "should be able to report their merchant" do
        @invoice.merchant.should == 'Merchant'
      end
      
      it "should be able to report their currency" do
        @invoice.currency.should == 'GBP'
      end
      
      it "should be able to report their reference UID" do
        @invoice.reference_id.should == 'reference UID'
      end
      
      it "should be able to report their date" do
        @invoice.date.should == Date.parse("2009-07-20")
      end
      
      it "should be able to report their total" do
        @invoice.total.should == '23.00'
      end
      
      it "should be able to report VAT" do
        @invoice.vat_total.should == '3.00'
      end
      
      it "should be able to report their ex-VAT total" do
        @invoice.ex_vat_total.should == '20.00'
      end
      
      it "should be able to report their inc-VAT total" do
        @invoice.inc_vat_total.should == '23.00'
      end
      
      it "should be able to report that it's VAT inclusive" do
        @invoice.vat_inclusive?.should be_true
      end
      
      describe "adding items to an invoice" do
        it "should be able to add an item" do
          PaperlessToXero::InvoiceItem.expects(:new).with('description', '30.00', nil, '123 - Some stuff', 'No VAT', true).returns(:item)
          @invoice.add_item('description', '30.00', nil, '123 - Some stuff', 'No VAT')
          
          @invoice.items.should == [:item]
        end
      end
      
      describe "ex-VAT invoices" do
        before(:each) do
          @invoice = PaperlessToXero::Invoice.new(Date.parse("2009-07-20"), 'Merchant', 'reference UID', '23.00', '3.00', false, 'GBP')
        end
        
        it "should be able to report VAT" do
          @invoice.vat_total.should == '3.00'
        end
        
        it "should be able to report their ex-VAT total" do
          @invoice.ex_vat_total.should == '20.00'
        end
        
        it "should be able to report their inc-VAT total" do
          @invoice.inc_vat_total.should == '23.00'
        end
        
        it "should be pass on its ex-vat-ness to invoice items" do
          PaperlessToXero::InvoiceItem.expects(:new).with('description', '30.00', nil, '123 - Some stuff', 'No VAT', false).returns(:item)
          @invoice.add_item('description', '30.00', nil, '123 - Some stuff', 'No VAT')
        end
      end
    end
    
    describe "serializing an invoice" do
      before(:each) do
        @fake_csv = mock()
      end
      
      def make_invoice(total, vat, currency = 'GBP')
        PaperlessToXero::Invoice.new(Date.parse("2009-07-20"), 'Merchant', 'reference UID', total, vat, true, currency)
      end
      
      describe "single-item invoices" do
        it "should produce sensible Xero-pleasing output" do
          invoice = make_invoice('45.00', '5.00')
          invoice.add_item('description', '30.00', nil, '123 - Some stuff', 'No VAT')
          
          @fake_csv.expects(:<<).with(['Merchant', 'reference UID', '20/07/2009', '20/07/2009', '40.00', '5.00', '45.00', 'description', '1', '30.00', '123 - Some stuff', 'No VAT', nil, nil, nil, nil, nil])
          
          invoice.serialise_to_csv(@fake_csv)
        end
      end
      
      describe "multi-item invoices" do
        it "should produce sensible Xero-pleasing output" do
          invoice = make_invoice('75.00', '5.00')
          invoice.add_item('thing', '30.00', nil, '123 - Some stuff', 'No VAT')
          invoice.add_item('other thing', '23.00', '3.00', '234 - Some other stuff', 'VAT - 15%')
          
          @fake_csv.expects(:<<).with(['Merchant', 'reference UID', '20/07/2009', '20/07/2009', '70.00', '5.00', '75.00', 'thing', '1', '30.00', '123 - Some stuff', 'No VAT', nil, nil, nil, nil, nil])
          @fake_csv.expects(:<<).with([nil, 'reference UID', nil, nil, nil, nil, nil, 'other thing', '1', '20.00', '234 - Some other stuff', '15% (VAT on expenses)', '3.00', nil, nil, nil, nil])
          
          invoice.serialise_to_csv(@fake_csv)
        end
      end
      
      describe "foreign-currency invoices" do
        it "should stick the currency after the merchant so they can be picked out after import" do
          invoice = make_invoice('45.00', '5.00', 'EUR')
          invoice.add_item('description', '30.00', nil, '123 - Some stuff', 'No VAT')
          
          @fake_csv.expects(:<<).with(['Merchant (EUR)', 'reference UID', '20/07/2009', '20/07/2009', '40.00', '5.00', '45.00', 'description', '1', '30.00', '123 - Some stuff', 'No VAT', nil, nil, nil, nil, nil])
          
          invoice.serialise_to_csv(@fake_csv)
        end
      end
    end
  end
end