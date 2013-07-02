class SearchController < ApplicationController
  def get
    query = params[:query]
    if query == nil
      @items = []
      return
    end
    page = make_page(params[:page])
    @items = []
    @items += get_tube8(query, page)
    @items += get_youtube(query, page)
    @items += get_xvideo(query, page)
    @items += get_xhamster(query, page)
    @query = query
    @page = page
    @prev_page = make_prev_page(page)
    @next_page = make_next_page(page)
  end

  def make_page(page)
    if page.to_i > 0
      page.to_i
    else
      1
    end
  end

  def make_prev_page(page)
    if page.to_i > 1
      page.to_i - 1
    else
      nil
    end
  end

  def make_next_page(page)
    if page.to_i > 1
      page.to_i + 1
    else
      2
    end
  end

  def get_xml(url)
    charset = nil
    html = open(url) do |f|
      charset = f.charset
      f.read
    end
    Nokogiri::HTML.parse(html, nil, charset)
  end

  def get_youtube(keyword, page)
    if page > 1
      page_param = '&page=' + page.to_s
    else
      page_param = ''
    end

    items = []
    url = 'http://www.youtube.com/results?search_query=' + keyword + page_param
    xml = get_xml(url)

    xml.xpath('//*[@id="search-results"]/li').each do |video|
      item = Item.new()
      item.link = 'http://www.youtube.com/watch?v=' + video.attribute('data-context-item-id').value
      item.title = video.attribute('data-context-item-title').value
      lazy_thumbnail = video.xpath('.//img').attribute('data-thumb')
      if lazy_thumbnail == nil
        item.thumbnail = video.xpath('.//img').attribute('src').value
      else
        item.thumbnail = lazy_thumbnail
      end
      item.length = video.xpath('.//*[@class="duration"]').text.gsub(/\(([0-9]+).+\)/,'\1').to_i * 60
      items.push(item)
    end
    items
  end

  def get_xvideo(keyword, page)
    if page > 1
      page_param = '&p=' + (page - 1).to_s
    else
      page_param = ''
    end

    items = []
    url = 'http://www.xvideos.com?k=' + keyword + page_param
    xml = get_xml(url)

    xml.xpath('//div[@class="thumbBlock"]').each do |video|
      item = Item.new()
#      item.link = 'http://www.xvideos.com/' + video.xpath('.//a').attribute('href').value
#      item.title = video.xpath('.//a').attribute('href').value.gsub(/\/.+\/(.+)/,'\1')
      item.thumbnail = video.xpath('.//img').attribute('src').value
#      item.length = video.xpath('.//*[@class="duration"]').text.gsub(/\(([0-9]+).+\)/,'\1').to_i * 60
      items.push(item)
    end
    items
  end

  def get_xhamster(keyword, page)
    if page > 1
      page_param = '&page=' + page.to_s
    else
      page_param = ''
    end

    items = []
    url = 'http://xhamster.com/search.php?qcat=video&q=' + keyword + page_param
    xml = get_xml(url)

    xml.xpath('//div[@class="video"]').each do |video|
      item = Item.new()
      item.link = video.xpath('.//a').attribute('href').value
      item.title = video.xpath('.//img').attribute('alt').value
      item.thumbnail = video.xpath('.//img').attribute('src').value
      item.length = video.xpath('.//b').text
      items.push(item)
    end
    items
  end

  def get_tube8(keyword, page)
    if page > 1
      page_param = '&page=' + page.to_s
    else
      page_param = ''
    end

    items = []
    url = 'http://www.tube8.com/searches.html?q=' + keyword + page_param
    xml = get_xml(url)

    xml.xpath('//div[@class="box-thumbnail"]').each do |video|
      item = Item.new()
      item.link = video.xpath('.//img[@class="videoThumbs"]/parent::a').attribute('href').value
#      item.title = video.xpath('.//img').attribute('alt').value
      item.thumbnail = video.xpath('.//img[@class="videoThumbs"]').attribute('src').value
#      item.length = video.xpath('.//b').text
      items.push(item)
    end
    items
  end
end

class Item
  attr_accessor :thumbnail, :title, :length, :link, :prev_page, :next_page, :query
end
