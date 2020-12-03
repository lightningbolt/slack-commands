require 'core_ext/range/weighted_array'
require 'fileutils'

class DogeifyController < ApplicationController
  BASE_IMAGE_DIR = File.join(Rails.root, "lib", "assets", "dogeify")
  COLORS = [
    "rgb(221,0,204)",   # magenta
    "rgb(255,51,51)",   # red
    "rgb(255,136,0)",   # orange
    "rgb(225,225,0)",   # yellow
    "rgb(0,255,0)",     # green
    "rgb(0,255,255)",   # cyan
    "rgb(51,51,255)",   # blue
    "rgb(127,0,255)",   # purple
    "rgb(255,255,255)"  # white
  ] 
  GRAVITIES = [
#   [:Center,    { x: (-113 .. 113).to_weighted_array, y: (-113 .. 113).to_weighted_array }],
    [:East,      { x: (0    .. 200).to_weighted_array, y: (-113 .. 113).to_weighted_array }],
    [:North,     { x: (-113 .. 113).to_weighted_array, y: (0    .. 80 ).to_weighted_array }],
    [:NorthEast, { x: (0    .. 220).to_weighted_array, y: (0    .. 226).to_weighted_array }],
    [:NorthWest, { x: (0    .. 220).to_weighted_array, y: (0    .. 226).to_weighted_array }],
    [:South,     { x: (-113 .. 113).to_weighted_array, y: (0    .. 80 ).to_weighted_array }],
    [:SouthEast, { x: (0    .. 220).to_weighted_array, y: (0    .. 226).to_weighted_array }],
    [:SouthWest, { x: (0    .. 220).to_weighted_array, y: (0    .. 226).to_weighted_array }],
    [:West,      { x: (0    .. 200).to_weighted_array, y: (-113 .. 113).to_weighted_array }]
  ]
  PUBLIC_DIR = File.join(Rails.root, "public", "dogeify")
  SECTIONS = [1, 2, 3, 4]
  SECTION_RANGES = {
    1 => (1..30),
    2 => (31..60),
    3 => (61..90),
    4 => (91..120)
  }
  VALID_DOGE_TYPES = %w(ponyboy shump)
  VALID_DOGE_TYPE_HASHTAGS = VALID_DOGE_TYPES.map { |t| "##{t}" }

  before_action :check_slack_token, only: [:slack]

  def index
    render :text => (params[:string] || params[:text]).to_s.dogeify, :status => :ok
  end

  def slack
    split_text = params[:text].split(" ")
    image = split_text.delete("#image")
    doge_type_hashtag = VALID_DOGE_TYPE_HASHTAGS.detect { |t| t == split_text.first }
    if doge_type_hashtag
      split_text.shift
      doge_type = doge_type_hashtag.sub("#", "")
    else
      doge_type = 'doge'
    end
    text = split_text.join(" ")
    dogeified_text = text.to_s.dogeify

    if image
      doge_url = generate_doge_image_and_get_url(dogeified_text, doge_type: doge_type)
      response_payload = {
        response_type: "in_channel",
        blocks: [
          {
            type: "image",
            image_url: doge_url,
            alt_text: "doge meme"
          }
        ]
      }
    else
      slack_text = formatted_doge_text(dogeified_text)
      response_payload = {
        response_type: "in_channel",
        text: slack_text
      }
    end
    render json: response_payload, status: :ok
  end

  private

  def date_path
    @date_path ||= Date.today.strftime("%Y/%m/%d")
  end

  def doge_image_filename(id)
    @filename ||= "#{id}.jpg"
  end

  def formatted_doge_text(dogeified_text)
    last_two_sections = []
    dogeified_text.
      split(".").
      each_with_index.map do |sentence, i|
        section = (i == 0 ? 1 : (SECTIONS - last_two_sections).sample)
        range = SECTION_RANGES[section] #range = i.even? ? (1..25) : (25..75)
        last_two_sections.shift
        last_two_sections << section
        (" " * rand(range)) + "#{sentence}."
      end.join("\n")
  end

  def generate_doge_image(source_image_path, id, phrases)
    return if phrases.empty?
    phrase = phrases.shift
    gravity, shifts = get_gravity
    x_shift = sprintf("%+d", shifts[:x].sample)
    y_shift = sprintf("%+d", shifts[:y].sample)
    FileUtils.mkdir_p(File.join(PUBLIC_DIR, date_path))
    output_path = File.join(PUBLIC_DIR, date_path, doge_image_filename(id))
    command = %Q(
      convert #{source_image_path} \
      -fill "#{get_color}" \
      -font Comic-Sans-MS \
      -pointsize #{rand(18..24)} \
      -gravity #{gravity} \
      -annotate #{x_shift}#{y_shift} '#{phrase}' \
      #{output_path}
    )
    `#{command}`
    generate_doge_image(output_path, id, phrases)
  end

  def generate_doge_image_and_get_url(dogeified_text, doge_type: 'doge')
    phrases = dogeified_text.split(".")
    id = SecureRandom.uuid
    base_image_path = File.join(BASE_IMAGE_DIR, "#{doge_type}.jpg")
    generate_doge_image(base_image_path, id, phrases)
    date_path_and_filename = File.join(date_path,  doge_image_filename(id))
    url = URI.join(url_for(controller: "dogeify", action: "index", trailing_slash: true), date_path_and_filename).to_s
  end

  def get_color
    @colors ||= COLORS.dup
    @colors += COLORS if @colors.empty?
    @colors.delete_at(rand(@colors.length))
  end

  def get_gravity
    @gravities ||= GRAVITIES.dup
    @gravities += GRAVITIES if @gravities.empty?
    @gravities.delete_at(rand(@gravities.length))
  end

end
