require 'mechanize'

class Shop
  def initialize(mech=Mechanize.new)
    @mech = mech
  end

  def search_first_text(page, selector, &blk)
    if els = page.search(selector).first
      normalize els.inner_text, &blk
    end
  end

  def search_all_text(page, selector, &blk)
    if els = page.search(selector)
      normalize els.inner_text, &blk
    end
  end

  def search_first_attr(page, selector, attr, &blk)
    if els = page.search(selector).first
      normalize els.attribute(attr).value, &blk
    end
  end


  private

  def normalize(s, &blk)
    if s
      s.strip!
      if s.blank?
        nil
      elsif blk
        blk.call(s)
      else
        s
      end
    end
  end
end

