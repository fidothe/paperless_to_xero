require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PaperlessToXero::InvoiceItem do
  describe "the creation basics" do
    it "should be able to be instantiated" do
      # amount, vat, category, payment_method, notes, description, reference, status
      PaperlessToXero::InvoiceItem.new('description', '34.50', '4.50', '123 - Some stuff', 'VAT - 15%', true).
        should be_instance_of(PaperlessToXero::InvoiceItem)
    end
  end
  
  describe "instances" do
    before(:each) do
      @item = PaperlessToXero::InvoiceItem.new('description', '34.50', '4.50', '123 - Some stuff', 'VAT - 15%', true)
    end
    
    it "should be able to report their description" do
      @item.description.should == 'description'
    end
    
    it "should be able to report their amount" do
      @item.amount.should == "34.50"
    end
    
    it "should be able to report their VAT amount" do
      @item.vat_amount.should == "4.50"
    end
    
    it "should be able to report their VAT rate" do
      @item.vat_type.should == '15% (VAT on expenses)'
    end
    
    it "should be able to report whether the amount is VAT inclusive" do
      @item.vat_inclusive.should be_true
    end
    
    it "should be able to report whether their category" do
      @item.category.should == "123 - Some stuff"
    end
    
    describe "where items are VAT inclusive" do
      it "should be able to report the amount of VAT" do
        @item.vat_amount.should == "4.50"
      end
      
      it "should be able to report the VAT inclusive amount" do
        @item.vat_inclusive_amount.should == "34.50"
      end
      
      it "should be able to report the VAT exclusive amount" do
        @item.vat_exclusive_amount.should == "30.00"
      end
    end
    
    describe "where items are VAT exclusive" do
      before(:each) do
        @item = PaperlessToXero::InvoiceItem.new('description', '30.00', '4.50', '123 - Some stuff', 'VAT - 15%', false)
      end
      
      it "should be able to report the amount of VAT" do
        @item.vat_amount.should == "4.50"
      end
      
      it "should be able to report the VAT inclusive amount" do
        @item.vat_inclusive_amount.should == "34.50"
      end
      
      it "should be able to report the VAT exclusive amount" do
        @item.vat_exclusive_amount.should == "30.00"
      end
    end
    
    describe "where items are zero-rated for VAT" do
      describe "and £0.00 VAT is reported for them" do
        before(:each) do
          @item = PaperlessToXero::InvoiceItem.new('description', '30.00', '0.00', '123 - Some stuff', 'VAT - 0%', false)
        end
        
        it "should be able to report the amount of VAT" do
          @item.vat_amount.should == "0.00"
        end
        
        it "should be able to report the VAT inclusive amount" do
          @item.vat_inclusive_amount.should == "30.00"
        end
        
        it "should be able to report the VAT exclusive amount" do
          @item.vat_exclusive_amount.should == "30.00"
        end
      end
      
      describe "and no VAT is reported for them" do
        before(:each) do
          @item = PaperlessToXero::InvoiceItem.new('description', '30.00', nil, '123 - Some stuff', 'VAT - 0%', false)
        end
        
        it "should be able to report the amount of VAT" do
          @item.vat_amount.should == "0.00"
        end
        
        it "should be able to report the VAT inclusive amount" do
          @item.vat_inclusive_amount.should == "30.00"
        end
        
        it "should be able to report the VAT exclusive amount" do
          @item.vat_exclusive_amount.should == "30.00"
        end
      end
    end
    
    describe "where items do not have a VAT receipt" do
      before(:each) do
        @item = PaperlessToXero::InvoiceItem.new('description', '30.00', nil, '123 - Some stuff', 'No VAT', false)
      end
      
      it "should be able to report the amount of VAT" do
        @item.vat_amount.should == nil
      end
      
      it "should be able to report the VAT inclusive amount" do
        @item.vat_inclusive_amount.should == "30.00"
      end
      
      it "should be able to report the VAT exclusive amount" do
        @item.vat_exclusive_amount.should == "30.00"
      end
    end
    
    describe "VAT extraction" do
      def self.vat_pairs
        {'VAT - Germany - 7%'     => '7% (Germany, VAT on expenses)',
         'VAT - Germany - 19%'    => '19% (Germany, VAT on expenses)',
         'VAT - Germany'          => '19% (Germany, VAT on expenses)',
         'VAT - France - 5.5%'    => '5.5% (France, VAT on expenses)',
         'VAT - France - 19.6%'   => '19.6% (France, VAT on expenses)',
         'VAT - France'           => '19.6% (France, VAT on expenses)',
         'VAT - Denmark - 25%'    => '25% (Denmark, VAT on expenses)',
         'VAT - Denmark'          => '25% (Denmark, VAT on expenses)',
         'VAT - Sweden - 25%'     => '25% (Sweden, VAT on expenses)',
         'VAT - Sweden'           => '25% (Sweden, VAT on expenses)',
         'VAT - Ireland - 21.5%'  => '21.5% (Ireland, VAT on expenses)',
         'VAT - Ireland'          => '21.5% (Ireland, VAT on expenses)',
         'VAT - Luxembourg - 15%' => '15% (Luxembourg, VAT on expenses)',
         'VAT - Luxembourg'       => '15% (Luxembourg, VAT on expenses)',
         'VAT - EU'               => '15% (EU VAT ID)',
         'VAT - EU - EU372000063' => '15% (EU VAT ID)',
         'VAT - 15%'              => '15% (VAT on expenses)',
         'VAT - 0%'               => 'Zero Rated Expenses',
         'VAT'                    => '15% (VAT on expenses)',
         'No VAT'                 => 'No VAT'}
      end
      
      vat_pairs.each do |input, expected|
        it "should convert '#{input}' to '#{expected}'" do
          PaperlessToXero::InvoiceItem.publicize_methods do
            @item.extract_vat_type(input).should == expected
          end
        end
      end
    end
  end
end
