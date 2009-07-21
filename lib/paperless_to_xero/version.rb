module PaperlessToXero
  def self.Version
    PaperlessToXero::Version::FULL
  end
  
  module Version
    MAJOR = 1
    MINOR = 0
    POINT = 3
    FULL = [PaperlessToXero::Version::MAJOR, PaperlessToXero::Version::MINOR, PaperlessToXero::Version::POINT].join('.')
  end
end