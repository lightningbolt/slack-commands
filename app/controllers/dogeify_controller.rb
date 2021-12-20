require "doger"
require "fileutils"
require "google/cloud/storage"

class DogeifyController < ApplicationController
  BASE_IMAGE_DIR = File.join(Rails.root, "lib", "assets", "dogeify")
  GCS_BUCKET = Google::Cloud::Storage.new.bucket("dogeify")
  SECTIONS = [1, 2, 3, 4]
  SECTION_RANGES = {
    1 => (1..30),
    2 => (31..60),
    3 => (61..90),
    4 => (91..120)
  }
  TEMP_DIR = File.join(Rails.root, "tmp")
  VALID_DOGE_TYPES = %w(doge ponyboy shump)
  VALID_DOGE_TYPE_HASHTAGS = VALID_DOGE_TYPES.map { |t| "##{t}" }
  DOGES = Hash[
    VALID_DOGE_TYPES.map do |doge|
      [doge, Doger::Doge.new(File.join(BASE_IMAGE_DIR, "#{doge}.jpg"), auto_generate_zones: true)]
    end
  ]

  before_action :check_slack_token, only: [:slack]

  def index
    render :text => (params[:string] || params[:text]).to_s.dogeify, :status => :ok
  end

  def slack
    split_text = params[:text].split(" ")
    is_text = split_text.delete("#text")

    if is_text
      dogeified_text = split_text.join(" ").dogeify
      slack_text = formatted_dogeified_text(dogeified_text)
      response_payload = {
        response_type: "in_channel",
        text: slack_text
      }
    else # is image
      doge_type_hashtag = VALID_DOGE_TYPE_HASHTAGS.detect { |t| t == split_text.first }
      if doge_type_hashtag
        split_text.shift
        doge_type = doge_type_hashtag.sub("#", "")
      else
        doge_type = "doge"
      end
      dogeified_text = split_text.join(" ").dogeify
      doge_url = generate_doge_image_and_get_url(dogeified_text, doge_type: doge_type)
      response_payload = {
        response_type: "in_channel",
        blocks: [
          {
            type: "image",
            image_url: doge_url,
            alt_text: dogeified_text
          }
        ]
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

  def formatted_dogeified_text(dogeified_text)
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

  def generate_doge_image_and_get_url(dogeified_text, doge_type: "doge")
    local_dir = File.join(TEMP_DIR, date_path)
    FileUtils.mkdir_p(local_dir)
    file_name = "#{SecureRandom.uuid}.jpg"
    local_file_path = File.join(local_dir, file_name)
    remote_file_path = File.join(date_path, file_name)
    DOGES[doge_type].generate_image(local_file_path, dogeified_text.split("."))
    file = GCS_BUCKET.create_file(local_file_path, remote_file_path)
    FileUtils.rm(local_file_path)
    file.public_url
  end

end
