class PartyparrotController < ApplicationController
  MAX_BPM = 300
  MIN_BPM = 1

  before_action :check_slack_token, only: [:index]

  def index
    args = params[:text].downcase.split(" ")

    unless (bpm = get_and_validate_bpm(args))
      render_error("Please provide a numerical BPM between #{MIN_BPM} and #{MAX_BPM}.") and return
    end

    if args.include?("#mega") && args.include?("#sweatyguy")
      render_error("Please only provide one parrot type.") and return
    end

    parrot_type = if args.include?("#mega")
      "mega"
    elsif args.include?("#sweatyguy")
      "sweatyguy"
    else
      "regular"
    end
    
    parrot_url = generate_parrot_url(bpm: bpm, parrot_type: parrot_type)
    response_payload = {
      response_type: "in_channel",
      blocks: [
        {
          type: "image",
          image_url: parrot_url,
          alt_text: "#{bpm}bpm parrot"
        }
      ]
    } 
    render json: response_payload, status: :ok
  end

  private

  def generate_parrot_url(bpm: nil, parrot_type: "regular")
    source_files_directory = File.join(Rails.root, "lib", "assets", "partyparrot", parrot_type)
    public_directory = File.join(Rails.root, "public", "partyparrot")
    file_name = "#{parrot_type}_#{bpm.to_s.rjust(3, "0")}.gif"
    output_file_path = Pathname.new(File.join(public_directory, file_name))

    # generate partyparrot gif if it doesn't already exist
    if !output_file_path.exist?
      number_of_frames = 10
      framerate = (bpm.to_f / 60 * number_of_frames).round(2)
      command = %Q(
        ffmpeg \
        -framerate #{framerate} \
        -i "#{source_files_directory}/frame-%03d.png" \
        -i "#{source_files_directory}/palette.png" \
        -lavfi "paletteuse=alpha_threshold=255" \
        -gifflags -offsetting \
        -y #{output_file_path}
      )
      `#{command}`
    end
    url = URI.join(url_for(controller: "partyparrot", action: "index", trailing_slash: true), file_name).to_s
  end

  def get_and_validate_bpm(args)
    bpm_arg = args.find { |arg| arg.match(/\d+(bpm)?/i) } || ""
    bpm = bpm_arg.scan(/\d+/).first.to_i
    bpm = false unless (bpm >= MIN_BPM && bpm <= MAX_BPM)
    bpm
  end

  def render_error(message)
    response_payload = {
      response_type: "ephemeral",
      text: message
    }
    render(json: response_payload, status: :ok)
  end
end
